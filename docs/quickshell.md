# Quickshell bar (Linux)

The `bar` config is a lightweight, Omarchy Quattro-inspired status bar:
a 36px top bar on `DP-5`, Catppuccin Mocha at 92%
background opacity, and JetBrainsMono Nerd Font. It requires Quickshell 0.3.x
with Networking, PipeWire, and SystemTray support and Qt 6.8+ for windowed
popups (provided by NixOS here), NetworkManager's `nmcli`, and the existing Ghostty/btop and power-menu tools.

- Left: Niri workspaces from all outputs, ordered by output and workspace index;
  click to focus by stable ID. Named workspaces show a fixed icon; other workspaces
  show their number once created. The focused workspace is mauve. The focused
  application's name follows the workspaces: its desktop entry name, otherwise its
  app ID, otherwise its window title. Hover shows the window title when that differs.
  The name hides when no window is focused.
- Center: English weekday and 24-hour time; left-click toggles to English date, ISO
  week, and year. No clock tooltip or calendar popup.
- Right: 16px tray icons, network, audio, CPU, and power. Tray icons support
  primary/middle activation, context menus (including submenus), and scrolling.
- Audio: left-click mutes output, right-click mutes the microphone, scroll changes
  output volume in 5% steps, capped at 100%. Muted output is red; hover shows volume.
- Network: wired/Wi-Fi/disconnected icon and signal strength, preferring connected
  wired devices when both are up. Hover fetches the interface's IP address.
- CPU: hover shows total/per-core usage sampled every five seconds without
  subprocesses; left-click opens `ghostty -e btop`.
- Power: left-click opens the existing Fuzzel `power-menu`; hover turns the icon red.

Niri uses a reconnecting event stream for workspaces and windows, and a separate action socket. Audio,
network icons, and tray contents update through native services. The clock ticks
once a minute; `nmcli` runs only to fetch a hovered network tooltip. There is no
plugin framework, background command polling, or additional daemon.

## Running

Stowing the `linux` package links the config into `~/.config/quickshell/bar/`.
Niri starts `qs --no-duplicate -c bar` at login through `cfg/autostart.kdl`.
Config reloads do not run startup commands; to start the bar in an existing session:

```sh
niri msg action spawn -- qs --no-duplicate -c bar
```

For a foreground development run, use `qs --no-duplicate -c bar` (Ctrl+C stops
that process), or `qs --no-duplicate -p linux/.config/quickshell/bar` without
stowing. The bar disappears when `DP-5` is disconnected and returns when it
reconnects.

## Validation

```sh
node --test test/quickshell.test.cjs
```

The suite needs Node.js and `qs`. It tests the production JavaScript,
loads the actual QML components and checks windowed tooltips offscreen, drives
Niri IPC through a temporary Unix socket, and substitutes command executables to
avoid changing audio, launching applications, or invoking power actions. It does
not change startup settings. Real device signals, popup placement/submenu rendering,
and monitor hotplug still need a live desktop check.

For static checks, run `node --check` on `BarLogic.js` and the test runner, and
`qmllint -W 0` on the config's QML files with the installed Qt and Quickshell QML
import directories supplied via `-I`, and `-i linux/.config/quickshell/bar/qmldir`.
The narrow lint exemptions document Quickshell's runtime-selected PanelWindow
backend and opaque ObjectModel metadata; the component tests exercise those
service models at runtime.
