-- Clawd window rules (Hyprland 0.56+, Lua config). Load this file from your
-- config, or copy it in. The window is placed and toggled by clawd-sidebar.
hl.window_rule({match = {class = "^(claude-sidebar)$"}, workspace = "special:claude silent"})
hl.window_rule({match = {class = "^(claude-sidebar)$"}, float = true})
-- Without this the window can inherit the maximized state of another one.
hl.window_rule({match = {class = "^(claude-sidebar)$"}, fullscreen_state = "0 0"})
-- Keep the width in sync with SMALL_RATIO in clawd-sidebar.
hl.window_rule({match = {class = "^(claude-sidebar)$"}, size = {"(monitor_w*0.30)", "(monitor_h-50)"} })
hl.window_rule({match = {class = "^(claude-sidebar)$"}, move = {5, 45}})
