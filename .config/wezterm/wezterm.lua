local wezterm = require("wezterm")

local config = wezterm.config_builder()

config.font_size = 18

config.enable_tab_bar = false

config.color_scheme = 'Tokyo Night'

config.window_background_opacity = 0.85
config.macos_window_background_blur = 5

return config
