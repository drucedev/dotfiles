const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { spawnSync } = require('node:child_process');
const { test } = require('node:test');

// All configuration reads and writes use temporary homes, never the caller's.
const ROOT = path.resolve(__dirname, '..');
const COMMAND = path.join(ROOT, 'common/.local/bin/apply-agent-settings');
const TEMPLATES = path.join(ROOT, 'common/.local/share/agent-settings');
const TARGETS = {
    'claude.json': '.claude/settings.json',
    'pi.json': '.pi/agent/settings.json',
    't3-server.json': '.t3/userdata/settings.json',
    't3-client.json': '.t3/userdata/client-settings.json',
};

function sandbox(t) {
    const directory = fs.mkdtempSync(path.join(os.tmpdir(), 'agent-settings-test-'));
    t.after(() => fs.rmSync(directory, { recursive: true, force: true }));
    const home = path.join(directory, 'home');
    fs.mkdirSync(home);
    const env = { ...process.env, HOME: home };
    return {
        directory, home, env,
        target: name => path.join(home, TARGETS[name]),
        apply: (...args) => spawnSync(process.execPath, [COMMAND, ...args], { env, encoding: 'utf8' }),
        write(name, value) {
            const target = path.join(home, TARGETS[name]);
            fs.mkdirSync(path.dirname(target), { recursive: true });
            fs.writeFileSync(target, typeof value === 'string' ? value : JSON.stringify(value));
            return target;
        },
    };
}

const read = file => JSON.parse(fs.readFileSync(file, 'utf8'));
const template = name => read(path.join(TEMPLATES, name));
const succeeded = result => assert.equal(result.status, 0, result.stderr || String(result.error));

// Every file and directory below a directory, so stray empty directories count as writes.
function entries(directory) {
    return fs.readdirSync(directory, { withFileTypes: true }).flatMap(entry => {
        const file = path.join(directory, entry.name);
        return entry.isDirectory() ? [file, ...entries(file)] : [file];
    });
}

const mtimes = home => Object.fromEntries(entries(home)
    .map(file => [file, fs.statSync(file, { bigint: true }).mtimeNs]));

test('a fresh home gets private copies of every template', t => {
    const s = sandbox(t);
    succeeded(s.apply('all'));
    for (const name of Object.keys(TARGETS)) {
        const file = s.target(name);
        assert.deepEqual(read(file), template(name));
        assert.equal(fs.lstatSync(file).isSymbolicLink(), false);
        assert.equal(fs.statSync(file).mode & 0o777, 0o600);
    }
});

test('applying twice changes nothing', t => {
    const s = sandbox(t);
    succeeded(s.apply('all'));
    const before = mtimes(s.home);
    succeeded(s.apply('all'));
    assert.deepEqual(mtimes(s.home), before);
});

test('templates merge into local settings, which survive and are never echoed', t => {
    const s = sandbox(t);
    const local = {
        defaultModel: 'local-model',
        env: { LOCAL_TOKEN: 'sandbox-secret' },
        unknownPreference: { keep: true },
    };
    for (const name of Object.keys(TARGETS)) s.write(name, local);
    const result = s.apply('all');
    succeeded(result);
    for (const name of Object.keys(TARGETS)) {
        assert.deepEqual(read(s.target(name)), { ...template(name), ...local });
    }
    assert.doesNotMatch(result.stdout + result.stderr, /sandbox-secret|local-model/);
});

test('invalid JSON aborts before any write', t => {
    const s = sandbox(t);
    const file = s.write('t3-client.json', '{sandbox-secret');
    const before = entries(s.home);
    const result = s.apply('all');
    assert.notEqual(result.status, 0);
    assert.ok(result.stderr.includes(file));
    assert.doesNotMatch(result.stderr, /sandbox-secret/);
    assert.equal(fs.readFileSync(file, 'utf8'), '{sandbox-secret');
    assert.deepEqual(entries(s.home), before);
});

test('dry run writes nothing', t => {
    const s = sandbox(t);
    const file = s.write('claude.json', { theme: 'light' });
    const before = entries(s.home);
    succeeded(s.apply('all', '--dry-run'));
    assert.deepEqual(entries(s.home), before);
    assert.equal(fs.readFileSync(file, 'utf8'), '{"theme":"light"}');
});

test('symlinked settings are rejected', t => {
    const s = sandbox(t);
    const outside = path.join(s.directory, 'outside.json');
    fs.writeFileSync(outside, '{"theme":"light"}');
    const target = s.target('claude.json');
    fs.mkdirSync(path.dirname(target), { recursive: true });
    fs.symlinkSync(outside, target);
    assert.notEqual(s.apply('claude').status, 0);
    assert.equal(fs.readlinkSync(target), outside);
    assert.equal(fs.readFileSync(outside, 'utf8'), '{"theme":"light"}');
});

test('a Stow install links templates and applies real settings files', t => {
    const s = sandbox(t);
    succeeded(spawnSync('stow', ['--no-folding', '-d', ROOT, '-t', s.home, 'common'], { encoding: 'utf8' }));
    const installed = path.join(s.home, '.local/bin/apply-agent-settings');
    for (const name of Object.keys(TARGETS)) {
        assert.equal(fs.lstatSync(path.join(s.home, '.local/share/agent-settings', name)).isSymbolicLink(), true);
    }
    succeeded(spawnSync(installed, ['all'], { env: s.env, encoding: 'utf8' }));
    for (const name of Object.keys(TARGETS)) {
        assert.equal(fs.lstatSync(s.target(name)).isFile(), true);
        assert.deepEqual(read(s.target(name)), template(name));
    }
});
