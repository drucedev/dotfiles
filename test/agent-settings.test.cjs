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
            fs.writeFileSync(target, JSON.stringify(value));
            return target;
        },
    };
}

const read = file => JSON.parse(fs.readFileSync(file, 'utf8'));
const template = name => read(path.join(TEMPLATES, name));
const succeeded = result => assert.equal(result.status, 0, result.stderr || String(result.error));
const mode = file => fs.statSync(file).mode & 0o777;

function files(directory) {
    return fs.readdirSync(directory, { withFileTypes: true }).flatMap(entry => {
        const file = path.join(directory, entry.name);
        return entry.isDirectory() ? files(file) : [file];
    });
}

const mtimes = home => Object.fromEntries(files(home).filter(file => file.endsWith('.json'))
    .map(file => [file, fs.statSync(file, { bigint: true }).mtimeNs]));

test('fresh home and idempotence', t => {
    const s = sandbox(t);
    succeeded(s.apply('all'));
    for (const [name, target] of Object.entries(TARGETS)) {
        const file = path.join(s.home, target);
        assert.deepEqual(read(file), template(name));
        assert.equal(fs.lstatSync(file).isSymbolicLink(), false);
        assert.equal(mode(file), 0o600);
    }
    const before = mtimes(s.home);
    succeeded(s.apply('all'));
    assert.deepEqual(mtimes(s.home), before);
    assert.deepEqual(files(s.home).filter(file => file.endsWith('.bak')), []);
});

test('local provider/model configuration, credentials, and integrations survive', t => {
    const s = sandbox(t);
    const local = {
        defaultProvider: 'local-provider', defaultModel: 'local-model',
        modelSettings: { 'local-model': { effort: 'low' } },
        providerInstances: { local: { config: { apiKey: 'sandbox-secret' } } },
        hooks: { SessionStart: [{ command: 'local-hook' }] },
        env: { LOCAL_TOKEN: 'sandbox-secret' }, unknownPreference: { keep: true },
    };
    for (const name of Object.keys(TARGETS)) s.write(name, local);
    const result = s.apply('all');
    succeeded(result);
    for (const name of Object.keys(TARGETS)) {
        const actual = read(s.target(name));
        for (const [key, value] of Object.entries(local)) assert.deepEqual(actual[key], value);
    }
    assert.doesNotMatch(result.stdout + result.stderr, /sandbox-secret|local-model/);
});

test('nested preferences merge and local permission denials are retained', t => {
    const s = sandbox(t);
    s.write('claude.json', {
        permissions: { defaultMode: 'default', allow: ['Read'], deny: ['Bash(rm:*)'] },
        skillOverrides: { 'local-skill': 'off', init: 'on' },
    });
    succeeded(s.apply('claude'));
    const actual = read(s.target('claude.json'));
    assert.equal(actual.permissions.defaultMode, 'auto');
    assert.deepEqual(actual.permissions.allow, ['Read']);
    assert.ok(actual.permissions.deny.includes('Bash(rm:*)'));
    for (const denial of template('claude.json').permissions.deny) {
        assert.ok(actual.permissions.deny.includes(denial));
    }
    assert.equal(actual.skillOverrides['local-skill'], 'off');
    assert.equal(actual.skillOverrides.init, 'off');
});

test('Pi preserves local packages and updates shared package filters', t => {
    const s = sandbox(t);
    const shared = template('pi.json').packages;
    s.write('pi.json', {
        packages: ['npm:local-provider-package', {
            source: shared[1].source, extensions: ['old-filter'], skills: [],
        }], localProviderOptions: { temperature: 0.5 },
    });
    succeeded(s.apply('pi'));
    const actual = read(s.target('pi.json'));
    assert.ok(actual.packages.includes('npm:local-provider-package'));
    const package = actual.packages.find(entry => typeof entry === 'object');
    assert.deepEqual(package.extensions, shared[1].extensions);
    assert.deepEqual(package.skills, []);
    assert.ok(actual.packages.includes(shared[0]));
    assert.deepEqual(actual.localProviderOptions, { temperature: 0.5 });
});

test('Pi resource overrides preserve unrelated local choices', t => {
    const s = sandbox(t);
    s.write('pi.json', {
        defaultTools: ['read', 'bash', '-codemode'],
        extensions: ['local-extension.ts', '+builtin:llama.cpp', '-builtin:mcp'],
        skills: ['+skills/code-review/SKILL.md', 'local-skill.md'],
    });
    succeeded(s.apply('pi'));
    const actual = read(s.target('pi.json'));
    assert.deepEqual(actual.defaultTools, ['read', 'bash', '+codemode']);
    assert.ok(actual.extensions.includes('local-extension.ts'));
    assert.ok(actual.extensions.includes('+builtin:llama.cpp'));
    assert.ok(!actual.extensions.includes('-builtin:llama.cpp'));
    assert.ok(actual.extensions.includes('+builtin:mcp'));
    assert.ok(!actual.extensions.includes('-builtin:mcp'));
    assert.ok(actual.skills.includes('local-skill.md'));
    assert.ok(!actual.skills.includes('+skills/code-review/SKILL.md'));
    const before = mtimes(s.home);
    succeeded(s.apply('pi'));
    assert.deepEqual(mtimes(s.home), before);
});

test('backups keep original bytes privately and file modes are preserved', t => {
    const s = sandbox(t);
    const file = s.write('claude.json', { theme: 'light' });
    fs.chmodSync(file, 0o640);
    const original = fs.readFileSync(file);
    succeeded(s.apply('claude'));
    const backups = files(s.home).filter(file => file.endsWith('.bak'));
    assert.equal(backups.length, 1);
    assert.deepEqual(fs.readFileSync(backups[0]), original);
    assert.equal(mode(backups[0]), 0o600);
    assert.equal(mode(file), 0o640);
});

test('dry run does not write', t => {
    const s = sandbox(t);
    const file = s.write('claude.json', { theme: 'light' });
    const original = fs.readFileSync(file);
    succeeded(s.apply('all', '--dry-run'));
    assert.deepEqual(fs.readFileSync(file), original);
    assert.equal(fs.existsSync(path.join(s.home, '.pi')), false);
    assert.equal(fs.existsSync(path.join(s.home, '.t3')), false);
    assert.deepEqual(files(s.home).filter(file => file.endsWith('.bak')), []);
});

test('app selection and unrelated state are untouched', t => {
    const s = sandbox(t);
    const state = path.join(s.home, '.claude.json');
    fs.writeFileSync(state, 'leave this alone');
    succeeded(s.apply('t3'));
    assert.equal(fs.existsSync(path.join(s.home, '.claude')), false);
    assert.equal(fs.existsSync(path.join(s.home, '.pi')), false);
    assert.equal(fs.readFileSync(state, 'utf8'), 'leave this alone');
    for (const name of ['desktop-settings.json', 'keybindings.json']) {
        assert.equal(fs.existsSync(path.join(s.home, '.t3/userdata', name)), false);
    }
});

test('invalid settings abort before any writes without echoing contents', t => {
    const s = sandbox(t);
    const file = s.target('t3-client.json');
    fs.mkdirSync(path.dirname(file), { recursive: true });
    fs.writeFileSync(file, '{sandbox-secret');
    const result = s.apply('all');
    assert.notEqual(result.status, 0);
    assert.ok(result.stderr.includes(file));
    assert.doesNotMatch(result.stderr, /sandbox-secret/);
    assert.equal(fs.existsSync(path.join(s.home, '.claude')), false);
    assert.equal(fs.existsSync(path.join(s.home, '.pi')), false);
    assert.equal(fs.readFileSync(file, 'utf8'), '{sandbox-secret');
});

test('non-object settings and invalid UTF-8 are rejected', t => {
    const s = sandbox(t);
    const file = s.write('pi.json', []);
    assert.notEqual(s.apply('pi').status, 0);
    assert.equal(fs.readFileSync(file, 'utf8'), '[]');
    const invalid = Buffer.from([0x7b, 0x22, 0xff, 0x22, 0x3a, 0x31, 0x7d]);
    fs.writeFileSync(file, invalid);
    assert.notEqual(s.apply('pi').status, 0);
    assert.deepEqual(fs.readFileSync(file), invalid);
});

test('symlinked settings or directories are rejected', t => {
    const s = sandbox(t);
    const external = path.join(s.directory, 'external');
    fs.mkdirSync(external);
    const source = path.join(external, 'settings.json');
    fs.writeFileSync(source, '{"theme":"light"}');
    const directory = path.join(s.home, '.claude');
    fs.mkdirSync(directory);
    const target = path.join(directory, 'settings.json');
    fs.symlinkSync(source, target);
    assert.notEqual(s.apply('claude').status, 0);
    assert.equal(fs.lstatSync(target).isSymbolicLink(), true);
    assert.equal(fs.readFileSync(source, 'utf8'), '{"theme":"light"}');
    fs.unlinkSync(target);
    fs.rmdirSync(directory);
    fs.symlinkSync(external, directory);
    assert.notEqual(s.apply('claude').status, 0);
    assert.equal(fs.readFileSync(source, 'utf8'), '{"theme":"light"}');
});

test('command works through a Stow-style symlink', t => {
    const s = sandbox(t);
    const installed = path.join(s.home, '.local/bin/apply-agent-settings');
    fs.mkdirSync(path.dirname(installed), { recursive: true });
    fs.symlinkSync(COMMAND, installed);
    succeeded(spawnSync(process.execPath, [installed, 'claude'], { env: s.env, encoding: 'utf8' }));
    assert.equal(fs.existsSync(s.target('claude.json')), true);
});

test('Stow links templates and theme, not live settings', t => {
    const s = sandbox(t);
    const sources = Object.fromEntries(Object.keys(TARGETS).map(name =>
        [name, fs.readFileSync(path.join(TEMPLATES, name))]));
    succeeded(spawnSync('stow', ['--no-folding', '-d', ROOT, '-t', s.home, 'common'], { encoding: 'utf8' }));
    const installed = path.join(s.home, '.local/bin/apply-agent-settings');
    for (const file of [installed, path.join(s.home, '.local/share/agent-settings/pi.json'),
        path.join(s.home, '.pi/agent/themes/catppuccin-mocha.json')]) {
        assert.equal(fs.lstatSync(file).isSymbolicLink(), true);
    }
    succeeded(spawnSync(installed, ['all'], { env: s.env, encoding: 'utf8' }));
    for (const [name, original] of Object.entries(sources)) {
        assert.equal(fs.lstatSync(s.target(name)).isSymbolicLink(), false);
        assert.deepEqual(fs.readFileSync(path.join(TEMPLATES, name)), original);
    }
});

test('accidental Pi state is ignored but theme is trackable', () => {
    const ignored = [
        'common/.pi/agent/settings.json', 'common/.pi/agent/auth.json',
        'common/.pi/agent/models-store.json', 'common/.pi/agent/sessions/session.jsonl',
        'common/.pi/agent/themes/catppuccin-mocha.json.local.bak',
    ];
    const result = spawnSync('git', ['check-ignore', '--no-index', '--stdin'], {
        cwd: ROOT, input: [...ignored, 'common/.pi/agent/themes/catppuccin-mocha.json'].join('\n') + '\n',
        encoding: 'utf8',
    });
    assert.deepEqual(new Set(result.stdout.trim().split('\n')), new Set(ignored));
});

test('templates are provider-neutral', () => {
    const forbidden = /provider|model|token|secret|credential|password|api.?key/i;
    function check(value) {
        if (Array.isArray(value)) value.forEach(check);
        else if (value && typeof value === 'object') {
            for (const [key, item] of Object.entries(value)) {
                assert.doesNotMatch(key, forbidden);
                check(item);
            }
        } else if (typeof value === 'string') assert.doesNotMatch(value, /\/Users\//);
    }
    for (const name of Object.keys(TARGETS)) check(template(name));
    const pi = template('pi.json');
    assert.ok(!pi.extensions.some(entry => entry.includes('builtin:llama.cpp')));
    const packages = pi.packages;
    assert.equal(packages.length, 2);
    assert.equal(packages[0], 'npm:@upstash/context7-pi');
    assert.equal(packages[1].source, 'ssh://git@github.com/drucedev/pid-mono');
});

test('executable requires only Node.js on PATH', t => {
    const s = sandbox(t);
    const bin = path.join(s.directory, 'bin');
    fs.mkdirSync(bin);
    fs.symlinkSync(process.execPath, path.join(bin, 'node'));
    succeeded(spawnSync(COMMAND, ['all'], { env: { ...s.env, PATH: bin }, encoding: 'utf8' }));
    assert.equal(fs.existsSync(s.target('pi.json')), true);
});
