#!/usr/bin/env bash
# Installs (or upgrades) Clawd.
# Plasma: the plasmoid, the KWin script and the Claude Code hooks.
# Hyprland: the scripts in ~/.local/share/clawd/bin and the Claude Code hooks;
# the rules, shortcuts and bar are left to your config (see hyprland/).
# Usage: install.sh [plasma|hyprland]   (default: the running desktop)
set -euo pipefail

repo=$(dirname "$(readlink -f "$0")")
settings="$HOME/.claude/settings.json"

# Claude Code hooks: every session records whether it is working, for the
# panel widget (or the bar) to run Clawd. Drops any previous clawd hooks first.
register_hooks() {  # path to clawd-hook
    cp "$settings" "$settings.pre-clawd"
    jq --arg h "$1" '
        def add($ev; $st):
            .hooks[$ev] += [{"hooks": [{"type": "command", "command": ("\u0027" + $h + "\u0027 " + $st), "timeout": 5}]}];
        (.hooks |= with_entries(.value |= map(select(any(.hooks[]; .command | test("clawd-hook")) | not))))
        | add("UserPromptSubmit"; "working")
        | add("PreToolUse"; "working")
        | add("PostToolUse"; "working")
        | add("Notification"; "idle")
        | add("Stop"; "idle")
        | add("SessionEnd"; "end")
    ' "$settings.pre-clawd" > "$settings"
}

target=${1:-}
[[ -n $target ]] || { [[ -n ${HYPRLAND_INSTANCE_SIGNATURE:-} ]] && target=hyprland || target=plasma; }

if [[ $target == hyprland ]]; then
    bin="$HOME/.local/share/clawd/bin"
    mkdir -p "$bin"
    for f in "$repo"/package/contents/bin/* "$repo/hyprland/clawd-sidebar"; do
        [[ -f $f ]] || continue
        [[ $(basename "$f") == quotes.txt ]] && mode=644 || mode=755
        install -m "$mode" "$f" "$bin/"
    done
    register_hooks "$bin/clawd-hook"
    echo "Clawd installed in $bin. Settings backup: $settings.pre-clawd"
    echo "Load hyprland/rules.lua and hyprland/keybinds.lua from your Hyprland config, or copy them in."
    exit 0
fi
[[ $target == plasma ]] || { echo "usage: install.sh [plasma|hyprland]" >&2; exit 2; }
id=org.joelferreira.clawd
hook="$HOME/.local/share/plasma/plasmoids/$id/contents/bin/clawd-hook"

if kpackagetool6 -t Plasma/Applet -s "$id" >/dev/null 2>&1; then
    kpackagetool6 -t Plasma/Applet -u "$repo/package"
else
    kpackagetool6 -t Plasma/Applet -i "$repo/package"
fi

# Icon for the widget list (the theme lookup does not see icons inside the package).
icons="$HOME/.local/share/icons/hicolor"
install -Dm644 "$repo/package/contents/icons/$id.svg" "$icons/scalable/apps/$id.svg"
touch "$icons"

# KWin script: places, shows and hides the Clawd window.
if kpackagetool6 -t KWin/Script -s clawd >/dev/null 2>&1; then
    kpackagetool6 -t KWin/Script -u "$repo/kwin"
else
    kpackagetool6 -t KWin/Script -i "$repo/kwin"
fi
kwriteconfig6 --file kwinrc --group Plugins --key clawdEnabled true
qdbus6 org.kde.KWin /KWin reconfigure

register_hooks "$hook"
echo "Clawd installed. Settings backup: $settings.pre-clawd"
