local wezterm = require("wezterm")
local config = wezterm.config_builder()

config:set_strict_mode(true)

config.color_scheme = "Default Dark (base16)"

return config
