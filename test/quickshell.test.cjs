const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const os = require('node:os');
const net = require('node:net');
const { spawn, spawnSync } = require('node:child_process');
const { test } = require('node:test');

// Execute the same plain JavaScript that QML imports, without a second implementation.
const logic = vm.createContext({ Date, Math, JSON });
vm.runInContext(fs.readFileSync(path.join(__dirname,
    '../linux/.config/quickshell/bar/BarLogic.js'), 'utf8'), logic);

// Convert values from the QML script's VM realm for strict comparisons.
const plain = value => JSON.parse(JSON.stringify(value));

async function componentTest(fixture, extraEnv = {}) {
    const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'quickshell-bar-test-'));
    try {
        fs.cpSync(path.join(__dirname, '../linux/.config/quickshell/bar'), dir, { recursive: true });
        fs.copyFileSync(path.join(__dirname, 'quickshell', fixture), path.join(dir, 'test.qml'));
        const env = { ...process.env, QT_QPA_PLATFORM: 'offscreen', NO_COLOR: '1', ...extraEnv };
        delete env.WAYLAND_DISPLAY;
        const { code, output } = await new Promise((resolve, reject) => {
            const child = spawn('qs', ['-p', path.join(dir, 'test.qml')], { env });
            let output = '';
            child.stdout.on('data', data => { output += data; });
            child.stderr.on('data', data => { output += data; });
            const timer = setTimeout(() => child.kill('SIGKILL'), 8000);
            child.on('error', reject);
            child.on('close', code => {
                clearTimeout(timer);
                resolve({ code, output });
            });
        });
        assert.equal(code, 0, output);
        assert.match(output, /PASS:/);
        assert.doesNotMatch(output, /ERROR|ReferenceError|TypeError|Binding loop|Unable to assign/);
    } finally {
        fs.rmSync(dir, { recursive: true, force: true });
    }
}

test('QML component interactions and English clock under a German session locale', () => componentTest('components.qml', {
    LC_ALL: 'de_DE.UTF-8', LANG: 'de_DE.UTF-8', LANGUAGE: 'de_DE'
}));
test('QML tooltips render in a separate window outside the thin panel', () => componentTest('tooltips.qml'));

test('QML services update network state, reject stale IP reads, sample CPU, and dispatch launcher commands', async () => {
    const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'quickshell-command-test-'));
    try {
        const output = path.join(dir, 'commands');
        fs.writeFileSync(path.join(dir, 'nmcli'), `#!/bin/sh
printf '%s\\n' "$*" >> "$BAR_TEST_COMMANDS"
sleep 0.05
case "$*" in
    *wifi-test) printf '192.0.2.1/24\\n' ;;
    *wired-test) printf '192.0.2.2/24\\n' ;;
    *) exit 1 ;;
esac
`, { mode: 0o700 });
        for (const command of ['ghostty', 'power-menu']) {
            fs.writeFileSync(path.join(dir, command), `#!/bin/sh\nprintf '%s %s\\n' '${command}' "$*" >> "$BAR_TEST_COMMANDS"\n`, { mode: 0o700 });
        }
        await componentTest('services.qml', {
            PATH: dir + path.delimiter + process.env.PATH,
            XDG_BIN_HOME: dir, BAR_TEST_COMMANDS: output
        });
        const commands = fs.readFileSync(output, 'utf8');
        assert.match(commands, /ghostty -e btop/);
        assert.match(commands, /power-menu /);
        assert.match(commands, /--escape no --get-values IP4.ADDRESS,IP6.ADDRESS device show wifi-test/);
        assert.match(commands, /--escape no --get-values IP4.ADDRESS,IP6.ADDRESS device show wired-test/);
    } finally {
        fs.rmSync(dir, { recursive: true, force: true });
    }
});

const workspace = (id, output, idx, extra = {}) => ({
    id, output, idx, name: null, is_active: false, is_focused: false,
    is_urgent: false, active_window_id: null, ...extra
});

test('workspace snapshots replace state and sort all outputs without losing duplicate indices', () => {
    const workspaces = [workspace(7, 'HDMI-A-5', 1), workspace(2, 'DP-5', 2), workspace(1, 'DP-5', 1)];
    const state = logic.workspaceEvent([], { WorkspacesChanged: { workspaces } });
    assert.deepEqual(plain(state).map(ws => ws.id), [1, 2, 7]);
    assert.deepEqual(plain(logic.workspaceEvent(state, {
        WorkspacesChanged: { workspaces: [workspace(7, 'HDMI-A-5', 1)] }
    })).map(ws => ws.id), [7]);
    assert.equal(logic.workspaceIcon(workspace(11, 'DP-5', 11)), '');
    assert.equal(logic.workspaceIcon(workspace(11, 'DP-5', 11, { name: '3' })), '3');
});

test('workspace events distinguish active per output from globally focused and do not mutate state', () => {
    const state = [workspace(1, 'DP-5', 1, { is_active: true, is_focused: true }),
        workspace(2, 'DP-5', 2), workspace(7, 'HDMI-A-5', 1, { is_active: true })];
    const next = logic.workspaceEvent(state, { WorkspaceActivated: { id: 2, focused: true } });
    assert.equal(next[0].is_active, false);
    assert.equal(next[1].is_focused, true);
    assert.equal(next[2].is_active, true);
    assert.equal(state[0].is_focused, true);
    const background = logic.workspaceEvent(next, { WorkspaceActivated: { id: 7, focused: false } });
    assert.equal(background[1].is_focused, true);
    const urgent = logic.workspaceEvent(background, { WorkspaceUrgencyChanged: { id: 7, urgent: true } });
    assert.equal(urgent[2].is_urgent, true);
    const occupied = logic.workspaceEvent(urgent, {
        WorkspaceActiveWindowChanged: { workspace_id: 7, active_window_id: 42 }
    });
    assert.equal(occupied[2].active_window_id, 42);
    assert.equal(logic.workspaceEvent(occupied, { WorkspaceActivated: { id: 999, focused: true } }), occupied);
    assert.equal(logic.workspaceEvent(occupied, { WindowsChanged: { windows: [] } }), occupied);
});

test('Niri adapter subscribes, handles split frames, focuses by ID on another socket, and reconnects', async () => {
    const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'quickshell-niri-test-'));
    const socketPath = path.join(dir, 'niri.sock');
    const connections = new Set();
    let subscriptions = 0;
    const actions = [];
    const protocolErrors = [];
    const server = net.createServer(socket => {
        connections.add(socket);
        socket.on('close', () => connections.delete(socket));
        let buffer = '';
        let subscribed = false;
        socket.on('data', data => {
            buffer += data;
            while (buffer.includes('\n')) {
                const end = buffer.indexOf('\n');
                const request = JSON.parse(buffer.slice(0, end));
                buffer = buffer.slice(end + 1);
                if (subscribed) {
                    protocolErrors.push('request written after EventStream');
                    socket.destroy();
                    continue;
                }
                if (request === 'EventStream') {
                    subscribed = true;
                    subscriptions++;
                    socket.write('{"Ok":"Handled"}\n');
                    const snapshot = JSON.stringify({ WorkspacesChanged: { workspaces: subscriptions === 1
                        ? [workspace(1, 'DP-5', 1), workspace(7, 'HDMI-A-5', 1)]
                        : [workspace(9, 'DP-5', 1)] } }) + '\n';
                    socket.write(snapshot.slice(0, 19));
                    setTimeout(() => {
                        if (!socket.destroyed) socket.write(snapshot.slice(19));
                    }, 10);
                } else {
                    actions.push(request);
                    socket.write('{"Ok":"Handled"}\n');
                    // A lost event stream must clear stale state and resubscribe.
                    for (const client of connections) client.end();
                }
            }
        });
    });
    try {
        await new Promise(resolve => server.listen(socketPath, resolve));
        await componentTest('niri.qml', { NIRI_SOCKET: socketPath });
        assert.deepEqual(protocolErrors, []);
        assert.equal(subscriptions, 2);
        assert.deepEqual(actions, [{ Action: { FocusWorkspace: { reference: { Id: 7 } } } }]);
    } finally {
        for (const socket of connections) socket.destroy();
        await new Promise(resolve => server.close(resolve));
        fs.rmSync(dir, { recursive: true, force: true });
    }
});

test('status icons preserve volume/headphone/mute and Wi-Fi signal levels', () => {
    assert.equal(logic.audioIcon(0.1, false, false), '');
    assert.equal(logic.audioIcon(0.5, false, false), '');
    assert.equal(logic.audioIcon(0.9, false, false), '');
    assert.equal(logic.audioIcon(0.5, false, true), '');
    assert.equal(logic.audioIcon(0.5, true, true), '');
    assert.equal(logic.networkIcon('wired', 0), '󰈀');
    assert.equal(logic.networkIcon('disconnected', 0), '󰤮');
    assert.deepEqual([0, 25, 50, 75, 100].map(signal => logic.networkIcon('wifi', signal)),
        ['󰤯', '󰤟', '󰤢', '󰤥', '󰤨']);
});

test('network tooltips prefer IPv4, handle IPv6-only, and never show a prefix as an address', () => {
    assert.equal(logic.networkAddress('192.168.1.2/24\nfe80::123/64\n'), '192.168.1.2');
    assert.equal(logic.networkAddress('fe80::123/64\n'), 'fe80::123');
    assert.equal(logic.networkAddress(''), 'No IP address');
});

test('CPU samples exclude guest time, include iowait as idle, and handle resets', () => {
    const before = logic.cpuSample('cpu 100 0 50 800 50 0 0 0 20 0\ncpu0 50 0 25 400 25 0 0 0 10 0\nintr 1');
    const after = logic.cpuSample('cpu 120 0 60 850 70 0 0 0 25 0\ncpu0 60 0 30 425 35 0 0 0 12 0');
    assert.equal(before.cpu.total, 1000);
    assert.equal(logic.cpuUsage(before, after), 'Total: 30%\ncpu0: 30%');
    assert.equal(logic.cpuUsage(null, after), 'CPU: collecting usage…');
    assert.equal(logic.cpuUsage(after, before), 'CPU: collecting usage…');
    assert.equal(logic.cpuUsage(after, after), 'CPU: collecting usage…');
});

test('clock preserves weekday/time and alternate date with a padded ISO week', () => {
    assert.equal(logic.clockFormat(new Date(2026, 0, 5, 12), false), 'dddd HH:mm');
    assert.equal(logic.clockFormat(new Date(2026, 0, 5, 12), true), "dd MMMM 'W02' yyyy");
});

test('ISO week handles year boundaries', () => {
    for (const [year, month, day, week] of [
        [2021, 0, 1, 53], [2021, 0, 4, 1], [2024, 11, 30, 1]
    ]) {
        assert.equal(logic.isoWeek(new Date(year, month, day, 12)), week);
    }
});

test('ISO week is independent of DST on both sides of southern-hemisphere transitions', () => {
    // An isolated timezone also catches local subtraction across a DST change
    // from January (summer) to April (winter), even when the host runs in UTC.
    const result = spawnSync(process.execPath, ['-e', `
        const assert = require('node:assert/strict');
        const fs = require('node:fs');
        const vm = require('node:vm');
        const logic = vm.createContext({ Date, Math });
        vm.runInContext(fs.readFileSync(process.argv[1], 'utf8'), logic);
        for (const [month, day, offset, week] of [
            [3, 3, -660, 13], [3, 5, -600, 14],
            [9, 2, -600, 39], [9, 4, -660, 40]
        ]) {
            const date = new Date(2021, month, day, 12);
            assert.equal(date.getTimezoneOffset(), offset);
            assert.equal(logic.isoWeek(date), week);
        }
    `, path.join(__dirname, '../linux/.config/quickshell/bar/BarLogic.js')], {
        env: { ...process.env, TZ: 'Australia/Sydney' }, encoding: 'utf8', timeout: 5000
    });
    assert.ifError(result.error);
    assert.equal(result.status, 0, result.stdout + result.stderr);
});
