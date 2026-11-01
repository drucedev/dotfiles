function audioIcon(volume, muted, headphones) {
    if (muted) return "";
    if (headphones) return "";
    return ["", "", ""][Math.min(2, Math.floor(Math.max(0, volume) * 3))];
}

// strength is Quickshell WifiNetwork.signalStrength (0.0-1.0), not a percentage.
// Five icons match Waybar format-icons: integer percent / 20, clamped to the last icon.
function networkIcon(kind, strength) {
    if (kind === "wired") return "󰈀";
    if (kind !== "wifi") return "󰤮";
    return ["󰤯", "󰤟", "󰤢", "󰤥", "󰤨"][Math.min(4, Math.floor(Math.round(Math.max(0, Math.min(1, strength)) * 100) / 20))];
}

function networkAddress(text) {
    const addresses = text.trim().split("\n").filter(line => line.includes("/"));
    const address = addresses.find(line => /^\d+\./.test(line)) || addresses[0];
    return address ? address.split("/")[0] : "No IP address";
}

function cpuSample(text) {
    const sample = {};
    for (const line of text.trim().split("\n")) {
        const fields = line.trim().split(/\s+/);
        if (!/^cpu\d*$/.test(fields[0]) || fields.length < 5) continue;
        // guest and guest_nice are already included in user and nice.
        const times = fields.slice(1, 9).map(Number);
        sample[fields[0]] = {
            total: times.reduce((sum, value) => sum + value, 0),
            idle: times[3] + (times[4] || 0)
        };
    }
    return sample;
}

function cpuUsage(previous, current) {
    const lines = [];
    for (const name of Object.keys(current)) {
        if (!previous || !previous[name]) continue;
        const total = current[name].total - previous[name].total;
        const idle = current[name].idle - previous[name].idle;
        if (total <= 0 || idle < 0) continue;
        const usage = Math.round(100 * Math.max(0, Math.min(1, 1 - idle / total)));
        lines.push((name === "cpu" ? "Total" : name) + ": " + usage + "%");
    }
    return lines.length ? lines.join("\n") : "CPU: collecting usage…";
}

function workspaceEvent(state, event) {
    if (event.WorkspacesChanged) {
        return event.WorkspacesChanged.workspaces.slice().sort((a, b) => {
            if (a.output !== b.output) return (a.output || "").localeCompare(b.output || "");
            return a.idx - b.idx || a.id - b.id;
        });
    }
    if (event.WorkspaceActivated) {
        const activation = event.WorkspaceActivated;
        const target = state.find(workspace => workspace.id === activation.id);
        if (!target) return state;
        return state.map(workspace => Object.assign({}, workspace, {
            is_active: workspace.output === target.output ? workspace.id === target.id : workspace.is_active,
            is_focused: activation.focused ? workspace.id === target.id : workspace.is_focused
        }));
    }
    if (event.WorkspaceUrgencyChanged) {
        const change = event.WorkspaceUrgencyChanged;
        return state.map(workspace => workspace.id === change.id
            ? Object.assign({}, workspace, { is_urgent: change.urgent }) : workspace);
    }
    if (event.WorkspaceActiveWindowChanged) {
        const change = event.WorkspaceActiveWindowChanged;
        return state.map(workspace => workspace.id === change.workspace_id
            ? Object.assign({}, workspace, { active_window_id: change.active_window_id }) : workspace);
    }
    return state;
}

const workspaceMarks = {
    terminal: { icon: "", label: "Ghostty" },
    code: { icon: "", label: "T3 Code, Zed" },
    apps: { icon: "󰀻", label: "X, Cliamp, Steam" },
    discord: { icon: "󰙯", label: "Discord" },
    browser: { icon: "󰖟", label: "Brave" }
};

function workspaceIcon(workspace) {
    const mark = workspaceMarks[workspace.name];
    if (mark) return mark.icon;
    const name = workspace.name || String(workspace.idx);
    if (/^[1-9]$/.test(name)) return name;
    return workspace.idx >= 1 && workspace.idx <= 9 ? String(workspace.idx) : "";
}

function workspaceLabel(workspace) {
    const mark = workspaceMarks[workspace.name];
    return mark ? mark.label : "Workspace " + (workspace.name || workspace.idx);
}

// Use local calendar fields, then UTC arithmetic so DST cannot shift the week.
function isoWeek(date) {
    const day = new Date(Date.UTC(date.getFullYear(), date.getMonth(), date.getDate()));
    day.setUTCDate(day.getUTCDate() + 4 - (day.getUTCDay() || 7));
    const start = new Date(Date.UTC(day.getUTCFullYear(), 0, 1));
    return Math.ceil(((day - start) / 86400000 + 1) / 7);
}

function clockFormat(date, alternate) {
    if (!alternate) return "dddd HH:mm";
    const week = String(isoWeek(date)).padStart(2, "0");
    return "dd MMMM 'W" + week + "' yyyy";
}
