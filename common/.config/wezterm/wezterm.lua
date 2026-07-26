local wezterm = require 'wezterm'
local mux = wezterm.mux

wezterm.on('gui-startup', function()
  local tab, pane, window = mux.spawn_window({})
  window:gui_window():maximize()
end)

local config = wezterm.config_builder()

config.font_size = 16
config.color_scheme = 'Catppuccin Mocha'

config.window_background_opacity = 0.85
config.macos_window_background_blur = 5

config.native_macos_fullscreen_mode = true

config.use_fancy_tab_bar = false
config.hide_tab_bar_if_only_one_tab = true
config.tab_bar_at_bottom = true

config.keys = {
    {key="Enter", mods="SHIFT", action=wezterm.action{SendString="\x1b\r"}},
}

return config
