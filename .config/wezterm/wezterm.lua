local wezterm = require("wezterm")

local config = wezterm.config_builder()

config.font_size = 18

config.enable_tab_bar = false

config.color_scheme = 'Catppuccin Mocha'

config.window_background_opacity = 0.8
config.macos_window_background_blur = 0

return config
