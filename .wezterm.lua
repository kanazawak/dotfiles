local wezterm = require 'wezterm'
local config = wezterm.config_builder()

config.native_macos_fullscreen_mode = true
config.hide_tab_bar_if_only_one_tab = true
config.window_padding = { left = 0, right = 0, top = 0, bottom = 0 }
config.font_size = 15
config.font = wezterm.font('Ricty Diminished')
config.treat_east_asian_ambiguous_width_as_wide = true
config.color_scheme = 'GruvboxDark'
config.keys = {
  {
    key = "¥",
    action = wezterm.action.SendKey { key = '\\' }
  },
  {
    key = "¥", mods = 'CTRL',
    action = wezterm.action.SendKey { key = '\\', mods = 'CTRL' }
  }
}
config.use_ime = true
config.macos_forward_to_ime_modifier_mask = "SHIFT|CTRL"

return config
