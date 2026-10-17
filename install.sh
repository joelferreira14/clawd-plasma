#!/usr/bin/env bash
# Installs (or upgrades) the Clawd plasmoid and registers its Claude Code hooks.
set -euo pipefail

repo=$(dirname "$(readlink -f "$0")")
id=org.joelferreira.clawd
settings="$HOME/.claude/settings.json"
hook="$HOME/.local/share/plasma/plasmoids/$id/contents/bin/clawd-hook"

if kpackagetool6 -t Plasma/Applet -s "$id" >/dev/null 2>&1; then
    kpackagetool6 -t Plasma/Applet -u "$repo/package"
else
    kpackagetool6 -t Plasma/Applet -i "$repo/package"
fi

# KWin script: places, shows and hides the Clawd window.
if kpackagetool6 -t KWin/Script -s clawd >/dev/null 2>&1; then
    kpackagetool6 -t KWin/Script -u "$repo/kwin"
else
    kpackagetool6 -t KWin/Script -i "$repo/kwin"
fi
kwriteconfig6 --file kwinrc --group Plugins --key clawdEnabled true
qdbus6 org.kde.KWin /KWin reconfigure

# Drop any previous clawd hooks, then add the current set.
cp "$settings" "$settings.pre-clawd"
jq --arg h "$hook" '
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

echo "Clawd installed. Settings backup: $settings.pre-clawd"
