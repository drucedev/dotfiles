# Theme

Everything runs Catppuccin Mocha, dark, with mauve (`#cba6f7`) as the accent —
no per-app themes, no light mode. fastfetch and other TUI apps without a theme
of their own inherit the palette from ghostty's ANSI overrides.

Touch points (a flavor switch touches exactly these):

| App | File | Carries color |
| --- | --- | --- |
| ghostty | `common/.config/ghostty/common.conf` | `theme =` |
| zed | `common/.config/zed/settings.json` | `theme`, `icon_theme` |
| nvim | `common/.config/nvim/lua/plugins/colorscheme.lua` | `flavour` |
| Pi | `common/.pi/agent/themes/catppuccin-mocha.json` | whole theme |
| btop | `common/.config/btop/btop.conf` | vendored theme file |
| quickshell | `linux/.config/quickshell/bar/Style.qml` | Mocha palette and bar dimensions |
| fuzzel | `linux/.config/fuzzel/catppuccin-mocha.ini` | `include=` in `fuzzel.ini` |
| swaylock | `linux/.config/swaylock/config` | whole file |
| niri | `linux/.config/niri/cfg/layout.kdl` | focus-ring colors |

Vendored files are verbatim from the official catppuccin ports — don't hand-edit
them. Future direction: a `theme` script here flips the fuzzel `include` to a
sibling flavor file and rewrites the Quickshell palette and remaining references.
Deliberately no home-manager; catppuccin/nix's home-manager modules were considered
and rejected for that reason.

Ghostty keeps shared settings in `common/.config/ghostty/common.conf`; the
macOS and Linux packages provide the platform wrapper. macOS starts Ghostty
maximized, while Linux leaves window state to the compositor.
