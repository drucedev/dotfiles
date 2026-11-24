const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const os = require('node:os');
const net = require('node:net');
const { spawn } = require('node:child_process');
const { test } = require('node:test');

const BAR = path.join(__dirname, '../linux/.config/quickshell/bar');

// Execute the same plain JavaScript that QML imports, without a second implementation.
const logic = vm.createContext({ Date, Math, JSON });
vm.runInContext(fs.readFileSync(path.join(BAR, 'BarLogic.js'), 'utf8'), logic);

// Runs a fixture beside the production components in offscreen qs; it must log PASS.
async function componentTest(fixture, extraEnv = {}) {
    const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'quickshell-bar-test-'));
    try {
        fs.cpSync(BAR, dir, { recursive: true });
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

const workspace = (id, output, idx, extra = {}) => ({
    id, output, idx, name: null, is_active: false, is_focused: false,
    is_urgent: false, active_window_id: null, ...extra
});

const niriWindow = (id, extra = {}) => ({
    id, title: null, app_id: null, is_focused: false, ...extra
});

// Array.from builds the result in this realm, so strict deepEqual ignores the VM's prototypes.
const ids = list => Array.from(list, item => item.id);

test('clock, audio, and tray components handle click and scroll signals under a German locale', () => componentTest('components.qml', {
    LC_ALL: 'de_DE.UTF-8', LANG: 'de_DE.UTF-8', LANGUAGE: 'de_DE'
}));

test('Niri adapter subscribes, focuses on a separate socket, and reconnects', async () => {
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
                    const windows = subscriptions === 1
                        ? [niriWindow(4, { app_id: 'bar-test-app', is_focused: true })]
                        : [niriWindow(8, { app_id: 'other-app', is_focused: true })];
                    socket.write(JSON.stringify({ WindowsChanged: { windows } }) + '\n');
                    // Split one event across writes to exercise frame buffering.
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

test('workspace snapshots replace state and sort across outputs', () => {
    const state = logic.workspaceEvent([], { WorkspacesChanged: {
        workspaces: [workspace(7, 'HDMI-A-5', 1), workspace(2, 'DP-5', 2), workspace(1, 'DP-5', 1)]
    } });
    assert.deepEqual(ids(state), [1, 2, 7]);
    const replaced = logic.workspaceEvent(state, { WorkspacesChanged: { workspaces: [workspace(7, 'HDMI-A-5', 1)] } });
    assert.deepEqual(ids(replaced), [7]);
});

test('workspace activation is per output and focus is global', () => {
    const state = [workspace(1, 'DP-5', 1, { is_active: true }),
        workspace(2, 'DP-5', 2), workspace(7, 'HDMI-A-5', 1, { is_active: true, is_focused: true })];
    const next = logic.workspaceEvent(state, { WorkspaceActivated: { id: 2, focused: true } });
    assert.deepEqual(next.map(ws => [ws.is_active, ws.is_focused]), [[false, false], [true, true], [true, false]]);
    assert.equal(state[2].is_focused, true, 'previous state is not mutated');
});

test('window focus follows open and focus events', () => {
    const replaced = logic.windowEvent([], { WindowsChanged: { windows: [
        niriWindow(1, { is_focused: true }), niriWindow(2)
    ] } });
    assert.equal(logic.focusedWindow(replaced).id, 1);
    const opened = logic.windowEvent(replaced, { WindowOpenedOrChanged: { window: niriWindow(3, { is_focused: true }) } });
    const focused = state => ids(state.filter(window => window.is_focused));
    assert.deepEqual(ids(opened), [1, 2, 3]);
    assert.deepEqual(focused(opened), [3]);
    assert.equal(replaced[0].is_focused, true, 'previous state is not mutated');
    const moved = logic.windowEvent(opened, { WindowFocusChanged: { id: 2 } });
    assert.deepEqual(focused(moved), [2]);
    assert.equal(logic.focusedWindow(logic.windowEvent(moved, { WindowFocusChanged: { id: null } })), null);
});

test('closing the focused window leaves nothing focused', () => {
    const state = [niriWindow(1), niriWindow(2, { is_focused: true })];
    const closed = logic.windowEvent(state, { WindowClosed: { id: 2 } });
    assert.deepEqual(ids(closed), [1]);
    assert.equal(logic.focusedWindow(closed), null);
});

test('CPU usage excludes guest time, counts iowait as idle, and waits after a reset', () => {
    const before = logic.cpuSample('cpu 100 0 50 800 50 0 0 0 20 0\ncpu0 50 0 25 400 25 0 0 0 10 0\nintr 1');
    const after = logic.cpuSample('cpu 120 0 60 850 70 0 0 0 25 0\ncpu0 60 0 30 425 35 0 0 0 12 0');
    assert.equal(logic.cpuUsage(before, after), 'Total: 30%\ncpu0: 30%');
    assert.equal(logic.cpuUsage(after, before), 'CPU: collecting usage…');
});

test('ISO week handles year boundaries', () => {
    for (const [year, month, day, week] of [[2021, 0, 1, 53], [2021, 0, 4, 1], [2024, 11, 30, 1]]) {
        assert.equal(logic.isoWeek(new Date(year, month, day, 12)), week);
    }
});

test('network icon distinguishes Wi-Fi off from disconnected', () => {
    assert.equal(logic.networkIcon('off', 0), '󰤭');
    assert.equal(logic.networkIcon('disconnected', 0), '󰤮');
    assert.equal(logic.networkIcon('wired', 0), '󰈀');
});

test('network tooltip reports Wi-Fi radio state', () => {
    const radio = (enabled, hardware = true) => ({ enabled, hardware });
    assert.equal(logic.networkTooltip('wlan0', '10.0.0.2', 'wifi', radio(true)), 'wlan0: 10.0.0.2');
    assert.equal(logic.networkTooltip('enp1', '', 'wired', radio(true)), 'enp1: Reading IP address…\nWi-Fi: on');
    assert.equal(logic.networkTooltip('enp1', '10.0.0.3', 'wired', radio(false)), 'enp1: 10.0.0.3\nWi-Fi: off');
    assert.equal(logic.networkTooltip('enp1', '10.0.0.3', 'wired', radio(true, false)),
        'enp1: 10.0.0.3\nWi-Fi blocked by hardware switch');
    assert.equal(logic.networkTooltip('', '', 'off', radio(false)), 'Wi-Fi off');
    assert.equal(logic.networkTooltip('', '', 'off', radio(true, false)), 'Wi-Fi blocked by hardware switch');
    assert.equal(logic.networkTooltip('', '', 'disconnected', radio(true)), 'Disconnected');
});
