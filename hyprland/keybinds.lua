-- Clawd shortcuts (Hyprland 0.56+, Lua config). Load this file from your
-- config, or copy it in. Super+Alt keeps clear of Claude Code's own Ctrl keys.
local clawd = os.getenv("HOME") .. "/.local/share/clawd/bin/clawd-sidebar"
hl.bind("SUPER + O", hl.dsp.exec_cmd(clawd .. " toggle"), { description = "Clawd: Show/hide" })
hl.bind("SUPER + ALT + O", hl.dsp.exec_cmd(clawd .. " expand"), { description = "Clawd: Size" })
hl.bind("SUPER + ALT + C", hl.dsp.exec_cmd(clawd .. " position"), { description = "Clawd: Position (left/center/right)" })
hl.bind("SUPER + ALT + P", hl.dsp.exec_cmd(clawd .. " pin"), { description = "Clawd: Pin (reserve space)" })
hl.bind("SUPER + ALT + D", hl.dsp.exec_cmd(clawd .. " detach"), { description = "Clawd: Detach/dock" })

-- A left click outside the docked window hides it. Clicks on the bar
-- (the monitor's reserved top) are ignored, so a bar button can toggle it.
hl.bind("mouse:272", function()
    local special = hl.get_active_special_workspace()
    if not special or special.name ~= "special:claude" then return end

    local pos = hl.get_cursor_pos()
    local mon = hl.get_active_monitor()
    if not pos or not mon then return end
    if pos.y < mon.y + mon.reserved.top then return end

    for _, w in ipairs(hl.get_windows()) do
        if w.class == "claude-sidebar" then
            local inside = pos.x >= w.at.x and pos.x < w.at.x + w.size.x
                and pos.y >= w.at.y and pos.y < w.at.y + w.size.y
            if inside then return end
        end
    end

    hl.dispatch(hl.dsp.workspace.toggle_special("claude"))
end, { non_consuming = true })
