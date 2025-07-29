local wezterm = require("wezterm")

local config = wezterm.config_builder()

config.font_size = 16

config.color_scheme = 'Catppuccin Mocha'

config.window_background_opacity = 0.85
config.macos_window_background_blur = 5
config.native_macos_fullscreen_mode = true

return config
