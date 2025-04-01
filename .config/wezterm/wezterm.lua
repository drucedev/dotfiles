local wezterm = require("wezterm")
local mux = wezterm.mux

wezterm.on('gui-startup', function(cmd)
    local tab, pane, window = mux.spawn_window(cmd or {})
    window:gui_window():toggle_fullscreen()
end)

local config = wezterm.config_builder()

config.font_size = 16

config.enable_tab_bar = false

config.color_scheme = 'Catppuccin Mocha'

config.window_background_opacity = 0.85
config.macos_window_background_blur = 5
config.native_macos_fullscreen_mode = true

return config
