// Window manager side of Clawd. clawd-window owns the state and pushes it here
// through these (keyless) shortcuts; clawd-toggle invokes "Clawd Toggle".
// The window is borderless and kept above, in one of three positions:
//   center: drop-down centred under the top panel (size sets width and height)
//   left:   full-height panel on the left edge (size sets the width only)
//   right:  same, on the right edge
// Unpinned, it hides as soon as it loses focus.

const OUTPUT = "DP-1";
const CENTER_SIZES = [[1100, 420], [1600, 620], [2200, 1000]];
const SIDE_WIDTHS = [600, 900, 1200];
const GAP = 6;
const CENTER = 0, LEFT = 1, RIGHT = 2;

const state = { pinned: false, position: CENTER, size: 1 };
let lastActive = null;
let autoHiddenAt = 0;

function clawd() {
    return workspace.windowList().find(w => w.resourceClass === "clawd") || null;
}

function workArea() {
    const output = workspace.screens.find(o => o.name === OUTPUT) || workspace.activeScreen;
    return workspace.clientArea(KWin.MaximizeArea, output, workspace.currentDesktop);
}

function geometry() {
    const area = workArea();
    if (state.position === CENTER) {
        const [width, height] = CENTER_SIZES[state.size];
        return { x: area.x + Math.round((area.width - width) / 2), y: area.y + GAP, width: width, height: height };
    }
    const width = SIDE_WIDTHS[state.size];
    const x = state.position === LEFT ? area.x + GAP : area.x + area.width - width - GAP;
    return { x: x, y: area.y + GAP, width: width, height: area.height - 2 * GAP };
}

function apply(w) {
    w.skipTaskbar = true;
    w.skipSwitcher = true;
    w.skipPager = true;
    w.noBorder = true;
    w.keepAbove = true;
    w.frameGeometry = geometry();
}

function show(w) {
    w.minimized = false;
    workspace.activeWindow = w;
}

function set(key, value) {
    if (state[key] === value)
        return;
    state[key] = value;
    const w = clawd();
    if (w)
        apply(w);
}

function toggle() {
    const w = clawd();
    if (!w)
        return;
    // Clicking the panel icon first steals focus (auto-hiding the window), then
    // toggles; treat that as a hide instead of showing it again.
    if (Date.now() - autoHiddenAt < 400)
        return;
    if (w.minimized || workspace.activeWindow !== w)
        show(w);
    else
        w.minimized = true;
}

workspace.windowAdded.connect(w => {
    if (w.resourceClass !== "clawd")
        return;
    apply(w);
    show(w);
});

workspace.windowActivated.connect(w => {
    const c = clawd();
    if (c && lastActive === c && w !== c && !state.pinned && !c.minimized) {
        c.minimized = true;
        autoHiddenAt = Date.now();
    }
    lastActive = w;
});

// Adopt a window that already exists when the script (re)loads.
const existing = clawd();
if (existing)
    apply(existing);

registerShortcut("Clawd Toggle", "Clawd: show/hide", "", toggle);
registerShortcut("Clawd Pin On", "Clawd: pin", "", () => set("pinned", true));
registerShortcut("Clawd Pin Off", "Clawd: unpin", "", () => set("pinned", false));
["center", "left", "right"].forEach((name, i) =>
    registerShortcut("Clawd Position " + i, "Clawd: " + name, "", () => set("position", i)));
CENTER_SIZES.forEach((_, i) =>
    registerShortcut("Clawd Size " + i, "Clawd: size " + "SML"[i], "", () => set("size", i)));
