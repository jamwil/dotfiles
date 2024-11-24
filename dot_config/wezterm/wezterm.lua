local wezterm = require("wezterm")
local config = wezterm.config_builder()

config:set_strict_mode(true)

config.color_scheme = "Default Dark (base16)"

-- Tab bar
config.use_fancy_tab_bar = false
config.hide_tab_bar_if_only_one_tab = true
config.tab_bar_at_bottom = true

return config
