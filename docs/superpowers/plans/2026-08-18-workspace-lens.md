# Workspace Lens Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build and install a public Omarchy Shell widget that shows grouped application icons per Hyprland workspace and reveals window details on hover.

**Architecture:** A user-owned bar plugin replaces `omarchy.workspaces` through `omarchy.clonedFrom`. `BarWidget.qml` adapts live Quickshell objects into plain window records, `WorkspaceModel.js` performs deterministic grouping and overflow calculation, and focused QML components render the bar target and passive hover popover without polling or mutating windows.

**Tech Stack:** Quickshell 0.3.0, QtQuick/QML, Quickshell.Hyprland, Quickshell.Wayland, Omarchy Shell 4, plain JavaScript, Node.js 26 built-in test runner, Bash, jq.

**Spec:** `docs/superpowers/specs/2026-08-18-workspace-lens-design.md`

## Global Constraints

- Runtime plugin ID is exactly `jacobsennando.workspace-lens`.
- `manifest.json` sets `omarchy.clonedFrom` to `omarchy.workspaces`.
- Runtime installation is confined to `~/.config/omarchy/plugins/jacobsennando.workspace-lens/`.
- Never modify `/usr/share/omarchy/`; packaged files are read-only references.
- Preserve numbered workspaces 1–5 and add occupied numeric workspaces through 10.
- Show at most three application groups in the bar and render the remainder as `+N`.
- Open the popover after 180 ms and close it 220 ms after both target and popover lose hover.
- The popover is informational; workspace click remains the only navigation action.
- Consume live Quickshell/Hyprland models and signals; do not poll `hyprctl` or start a daemon.
- Use Omarchy `Style`, `Color`, `Border`, `BarWidget`, and `PopupCard` primitives; do not hard-code Hackerman colors.
- Preserve the built-in global workspace list on every monitor and anchor the popover to the bar that received the hover.
- Visual completion requires functional evidence, a screenshot comparison against an incumbent sibling, and real Hyprland data rendered.
- Use Conventional Commits in Portuguese with subjects no longer than 50 characters.

## File map

- `manifest.json`: plugin identity, clone relationship, entry point, and catalog metadata.
- `WorkspaceModel.js`: pure normalization, grouping, counts, summary slicing, and fallback labels.
- `tests/load-workspace-model.mjs`: loads the QML-compatible JavaScript into Node's VM for tests.
- `tests/workspace-model.test.mjs`: behavioral tests for every model state in the spec.
- `AppIcon.qml`: one HiDPI-safe icon renderer with a fixed-size fallback.
- `WorkspaceButton.qml`: stable workspace target, number, summary icons, badges, overflow, focus, hover, and click signals.
- `WorkspacePopover.qml`: anchored passive popover, application groups, titles, totals, and truncation.
- `BarWidget.qml`: live Hyprland adapter, metadata/icon resolution, workspace list, timers, popover coordination, and workspace activation.
- `scripts/install.sh`: non-destructive local installation and optional activation.
- `tests/install.test.sh`: isolated installer behavior test.
- `README.md`: installation, behavior, compatibility, development, and verification commands.
- `DESIGN.md`: durable visual system extracted from the verified implementation after visual QA.

---

### Task 1: Pure workspace grouping model

**Files:**
- Create: `WorkspaceModel.js`
- Create: `tests/load-workspace-model.mjs`
- Create: `tests/workspace-model.test.mjs`

**Interfaces:**
- Consumes: plain window records shaped as `{ appId: string, title: string, name: string, icon: string }`.
- Produces: `normalizeAppId(value) -> string`, `fallbackName(appId) -> string`, and `buildWorkspace(id, windows, focusedId, maxSummary) -> WorkspaceRecord`.
- `WorkspaceRecord` is `{ id, focused, occupied, appCount, windowCount, groups, summaryGroups, overflowCount }`.
- Each group is `{ key, appId, name, icon, count, titles }`.

- [ ] **Step 1: Add the Node VM loader**

Create `tests/load-workspace-model.mjs`:

```js
import { readFileSync } from "node:fs";
import vm from "node:vm";

export function loadWorkspaceModel() {
  const source = readFileSync(new URL("../WorkspaceModel.js", import.meta.url), "utf8");
  const context = {};
  vm.createContext(context);
  vm.runInContext(source, context, { filename: "WorkspaceModel.js" });
  return context;
}
```

- [ ] **Step 2: Write failing model tests**

Create `tests/workspace-model.test.mjs` with concrete cases:

```js
import assert from "node:assert/strict";
import test from "node:test";
import { loadWorkspaceModel } from "./load-workspace-model.mjs";

const model = loadWorkspaceModel();

test("normalizes desktop ids", () => {
  assert.equal(model.normalizeAppId("  Org.GNOME.Nautilus.desktop  "), "org.gnome.nautilus");
});

test("builds an empty persistent workspace", () => {
  assert.deepEqual(
    JSON.parse(JSON.stringify(model.buildWorkspace(4, [], 2, 3))),
    { id: 4, focused: false, occupied: false, appCount: 0, windowCount: 0,
      groups: [], summaryGroups: [], overflowCount: 0 }
  );
});

test("groups repeated windows and preserves titles", () => {
  const result = model.buildWorkspace(1, [
    { appId: "com.mitchellh.ghostty", title: "jacobsen", name: "Ghostty", icon: "ghostty" },
    { appId: "com.mitchellh.ghostty", title: "nvim", name: "Ghostty", icon: "ghostty" },
    { appId: "org.gnome.Nautilus", title: "Downloads", name: "Files", icon: "org.gnome.Nautilus" }
  ], 1, 3);

  assert.equal(result.focused, true);
  assert.equal(result.appCount, 2);
  assert.equal(result.windowCount, 3);
  assert.equal(result.groups[0].count, 2);
  assert.deepEqual(Array.from(result.groups[0].titles), ["jacobsen", "nvim"]);
});

test("limits summary to three groups and reports overflow", () => {
  const windows = ["a", "b", "c", "d", "e"].map(id => ({
    appId: id, title: id.toUpperCase(), name: id.toUpperCase(), icon: id
  }));
  const result = model.buildWorkspace(3, windows, 2, 3);
  assert.deepEqual(Array.from(result.summaryGroups, group => group.key), ["a", "b", "c"]);
  assert.equal(result.overflowCount, 2);
});

test("keeps distinct web app ids separate", () => {
  const result = model.buildWorkspace(2, [
    { appId: "brave-web.whatsapp.com__-Default", title: "WhatsApp", name: "WhatsApp", icon: "brave" },
    { appId: "brave-calendar.google.com__-Default", title: "Calendar", name: "Calendar", icon: "brave" }
  ], 2, 3);
  assert.equal(result.appCount, 2);
});

test("derives safe fallbacks for missing metadata", () => {
  const result = model.buildWorkspace(5, [
    { appId: "", title: "Unknown Tool", name: "", icon: "" },
    { appId: "org.example.my-tool.desktop", title: "", name: "", icon: "" }
  ], 1, 3);
  assert.equal(result.groups[0].name, "Unknown Tool");
  assert.equal(result.groups[1].name, "My Tool");
  assert.equal(result.groups[1].titles[0], "My Tool");
});
```

- [ ] **Step 3: Run tests and verify the red state**

Run: `node --test tests/workspace-model.test.mjs`

Expected: FAIL because `WorkspaceModel.js` does not exist or `buildWorkspace` is undefined.

- [ ] **Step 4: Implement the minimal pure model**

Create `WorkspaceModel.js` using QML-compatible ES5-style functions. The implementation must:

```js
function text(value) {
  return value === undefined || value === null ? "" : String(value).trim();
}

function normalizeAppId(value) {
  var id = text(value).toLowerCase();
  return id.slice(-8) === ".desktop" ? id.slice(0, -8) : id;
}

function fallbackName(appId) {
  var value = normalizeAppId(appId);
  var leaf = value.split(".").pop() || "application";
  return leaf.replace(/[-_]+/g, " ").replace(/\b\w/g, function(letter) {
    return letter.toUpperCase();
  });
}

function buildWorkspace(id, windows, focusedId, maxSummary) {
  var groups = [];
  var byKey = {};
  var source = windows || [];
  var limit = Math.max(0, Number(maxSummary) || 0);

  for (var i = 0; i < source.length; i++) {
    var window = source[i] || {};
    var appId = normalizeAppId(window.appId);
    var title = text(window.title);
    var key = appId || "unknown:" + normalizeAppId(title || "application");
    var group = byKey[key];
    if (!group) {
      var name = text(window.name) || title || fallbackName(appId);
      group = { key: key, appId: appId, name: name, icon: text(window.icon), count: 0, titles: [] };
      byKey[key] = group;
      groups.push(group);
    }
    group.count += 1;
    group.titles.push(title || group.name);
  }

  return {
    id: Number(id),
    focused: Number(id) === Number(focusedId),
    occupied: source.length > 0,
    appCount: groups.length,
    windowCount: source.length,
    groups: groups,
    summaryGroups: groups.slice(0, limit),
    overflowCount: Math.max(0, groups.length - limit)
  };
}
```

- [ ] **Step 5: Run model tests**

Run: `node --test tests/workspace-model.test.mjs`

Expected: all six tests PASS.

- [ ] **Step 6: Commit the model**

```bash
git add WorkspaceModel.js tests/load-workspace-model.mjs tests/workspace-model.test.mjs
git commit -m "feat: agrupar apps por workspace"
```

---

### Task 2: Plugin manifest and compact workspace summary

**Files:**
- Create: `manifest.json`
- Create: `AppIcon.qml`
- Create: `WorkspaceButton.qml`
- Create: `BarWidget.qml`
- Create: `tests/plugin-contract.test.mjs`

**Interfaces:**
- Consumes: `WorkspaceModel.buildWorkspace(id, windows, focusedId, 3)` from Task 1; `Hyprland.workspaces`; `DesktopEntries.byId(id)`; `bar.shell.appLibrary.iconSource(icon)`.
- Produces: a registered bar widget with module ID `jacobsennando.workspace-lens`, `workspaceRecord(id)`, `workspaceIds()`, `focusWorkspace(id)`, and button signals `hoverChanged(item, hovered)` and `activateRequested(id)`.

- [ ] **Step 1: Write a failing plugin contract test**

Create `tests/plugin-contract.test.mjs`:

```js
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import test from "node:test";

test("manifest replaces the built-in workspaces widget", () => {
  const manifest = JSON.parse(readFileSync("manifest.json", "utf8"));
  assert.equal(manifest.id, "jacobsennando.workspace-lens");
  assert.equal(manifest.entryPoints.barWidget, "BarWidget.qml");
  assert.equal(manifest.omarchy.clonedFrom, "omarchy.workspaces");
  assert.deepEqual(manifest.kinds, ["bar-widget"]);
});

test("bar adapter has no polling process", () => {
  const qml = readFileSync("BarWidget.qml", "utf8");
  assert.doesNotMatch(qml, /\bProcess\s*\{/);
  assert.doesNotMatch(qml, /hyprctl/);
  assert.match(qml, /Hyprland\.workspaces/);
  assert.match(qml, /WorkspaceModel\.buildWorkspace/);
});
```

- [ ] **Step 2: Run the contract test and verify the red state**

Run: `node --test tests/plugin-contract.test.mjs`

Expected: FAIL because the manifest and QML files do not exist.

- [ ] **Step 3: Add the exact plugin manifest**

Create `manifest.json`:

```json
{
  "schemaVersion": 1,
  "id": "jacobsennando.workspace-lens",
  "name": "Workspace Lens",
  "version": "0.1.0",
  "author": "JacobsenNando",
  "description": "Grouped application icons and hover details for Hyprland workspaces",
  "kinds": ["bar-widget"],
  "entryPoints": { "barWidget": "BarWidget.qml" },
  "barWidget": {
    "displayName": "Workspace Lens",
    "description": "See grouped applications in every workspace",
    "category": "Compositor",
    "allowMultiple": false
  },
  "omarchy": { "clonedFrom": "omarchy.workspaces" }
}
```

- [ ] **Step 4: Implement the reusable icon component**

Create `AppIcon.qml` as an `Item` with required `source`, `label`, and `size` properties. Render an asynchronous `Image` with `sourceSize` multiplied by `Screen.devicePixelRatio`; when `Image.Error` or the source is empty, render the first uppercase label character inside a `BorderSurface` using `Color.surface` and `Color.foreground`. Keep `implicitWidth` and `implicitHeight` equal to `size` in both states so failed icons never shift layout. Set `Accessible.name` to `label`; mark duplicate decorative count/overflow glyphs as ignored by the accessibility API.

Core shape:

```qml
Item {
  required property string source
  required property string label
  required property int size
  implicitWidth: size
  implicitHeight: size

  Image {
    id: image
    anchors.fill: parent
    source: parent.source
    asynchronous: true
    fillMode: Image.PreserveAspectFit
    sourceSize.width: width * Screen.devicePixelRatio
    sourceSize.height: height * Screen.devicePixelRatio
  }

  BorderSurface {
    anchors.fill: parent
    visible: !parent.source || image.status === Image.Error
    color: Color.surface
    radius: Style.cornerRadius
    Text { anchors.centerIn: parent; text: parent.parent.label.slice(0, 1).toUpperCase() || "?" }
  }
}
```

- [ ] **Step 5: Implement the stable workspace target**

Create `WorkspaceButton.qml` with required `record`, `bar`, and `vertical` properties plus signals:

```qml
signal hoverChanged(Item target, bool hovered)
signal activateRequested(int workspaceId)
```

Use a fixed number cell and a `Row`/`Column` chosen by `vertical`. Render `record.summaryGroups` through `Repeater`, each with `AppIcon`; render a count badge only when `group.count > 1`; render `+record.overflowCount` only when positive. Empty targets remain `Style.space(20)` wide in a horizontal bar. Active state uses both `BorderSurface` background and a two-pixel accent mark on the inner bar edge. A `MouseArea` owns hover and click, emits the two signals, and never changes implicit size on hover.

Expose the target as `Accessible.Button` with a name such as `Workspace 3, 4 apps, 6 windows`; update that name from `record` so assistive output follows live state.

- [ ] **Step 6: Implement the live adapter and summary grid**

Create `BarWidget.qml` by following the installed `Workspaces.qml` structure. Required imports:

```qml
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import qs.Commons
import qs.Ui
import "WorkspaceModel.js" as WorkspaceModel
```

Implement these exact adapter functions:

```qml
function workspaceById(id) { /* scan Hyprland.workspaces.values */ }
function workspaceIds() { /* start [1,2,3,4,5], add numeric ids 1..10, sort */ }
function desktopEntryFor(appId) {
  var raw = String(appId || "").trim()
  var candidates = [raw, raw.replace(/\.desktop$/i, "")]
  for (var i = 0; i < candidates.length; i++) {
    var entry = DesktopEntries.byId(candidates[i])
    if (entry) return entry
  }
  return null
}
function iconSource(icon, appId) {
  var library = root.bar && root.bar.shell ? root.bar.shell.appLibrary : null
  if (library) return library.iconSource(icon || appId)
  return Quickshell.iconPath(icon || appId || "application-x-executable", "application-x-executable")
}
function rawWindows(workspace) {
  var values = workspace && workspace.toplevels ? workspace.toplevels.values : []
  return values.map(function(toplevel) {
    var entry = root.desktopEntryFor(toplevel.appId)
    return {
      appId: String(toplevel.appId || ""),
      title: String(toplevel.title || ""),
      name: entry ? String(entry.name || "") : "",
      icon: root.iconSource(entry ? entry.icon : "", toplevel.appId)
    }
  })
}
function workspaceRecord(id) {
  var workspace = root.workspaceById(id)
  var focusedId = Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : -1
  return WorkspaceModel.buildWorkspace(id, root.rawWindows(workspace), focusedId, 3)
}
function focusWorkspace(id) {
  var workspace = root.workspaceById(id)
  if (workspace) workspace.activate()
  else if (root.bar) root.bar.run("hyprctl dispatch " + Util.shellQuote("hl.dsp.focus({ workspace = \"" + id + "\" })"))
}
```

Render records in a `GridLayout` mirroring the built-in orientation behavior. Depend on a `refreshSerial` incremented by `Connections { target: Hyprland; function onRawEvent(event) { root.refreshSerial++ } }` and read it inside `workspaceRecord` so app/title/move events refresh bindings without polling.

- [ ] **Step 7: Run automated checks**

Run:

```bash
node --test tests/*.test.mjs
jq -e '.id == "jacobsennando.workspace-lens" and .omarchy.clonedFrom == "omarchy.workspaces"' manifest.json
git diff --check
```

Expected: tests PASS, jq prints `true`, and `git diff --check` prints nothing.

- [ ] **Step 8: Commit the compact widget**

```bash
git add manifest.json AppIcon.qml WorkspaceButton.qml BarWidget.qml tests/plugin-contract.test.mjs
git commit -m "feat: mostrar apps na barra"
```

---

### Task 3: Contextual hover popover

**Files:**
- Create: `WorkspacePopover.qml`
- Modify: `BarWidget.qml`
- Modify: `tests/plugin-contract.test.mjs`

**Interfaces:**
- Consumes: the selected `WorkspaceRecord` and hovered `WorkspaceButton` from Task 2; Omarchy `PopupCard` in `triggerMode: "hover"`.
- Produces: `requestOpen(target, record)`, `requestClose()`, `close()`, `containsMouse`, and a bounded details surface.

- [ ] **Step 1: Extend the failing contract test**

Append tests that assert the chosen timings and passive trigger are present:

```js
test("popover uses the approved hover contract", () => {
  const popover = readFileSync("WorkspacePopover.qml", "utf8");
  const bar = readFileSync("BarWidget.qml", "utf8");
  assert.match(popover, /triggerMode:\s*"hover"/);
  assert.match(bar, /interval:\s*180/);
  assert.match(bar, /interval:\s*220/);
  assert.doesNotMatch(popover, /\.activate\s*\(/);
  assert.doesNotMatch(popover, /\.close\s*\(/);
});
```

- [ ] **Step 2: Run the test and verify the red state**

Run: `node --test tests/plugin-contract.test.mjs`

Expected: FAIL because `WorkspacePopover.qml` does not exist.

- [ ] **Step 3: Implement the passive popover**

Create `WorkspacePopover.qml` around `PopupCard`:

```qml
PopupCard {
  id: root
  required property Item anchorItem
  required property QtObject bar
  property var record: null
  triggerMode: "hover"
  contentWidth: fittedContentWidth(Style.space(340), Style.space(420))
  contentHeight: fittedContentHeight(contentColumn.implicitHeight, Style.space(520))
  open: record !== null
}
```

Inside `contentColumn`, render a header with `Workspace N` and the exact pluralized totals. Render `record.groups` with one flat application row per group: `AppIcon`, name, optional count badge, then a nested list of one-line ellipsized titles. Do not use nested card surfaces or click handlers. For truncated titles, use the bar's native tooltip functions on hover. Bound width and height with `PopupCard` fitting helpers and use a `ListView` only when content exceeds the cap.

- [ ] **Step 4: Coordinate open and close timers in the bar**

In `BarWidget.qml`, add:

```qml
property Item pendingAnchor: null
property var pendingRecord: null
property Item activeAnchor: null
property var activeRecord: null

function requestPopover(target, record) {
  closeTimer.stop()
  pendingAnchor = target
  pendingRecord = record
  openTimer.restart()
}
function leavePopoverTarget(target) {
  if (pendingAnchor === target) openTimer.stop()
  if (activeAnchor === target && !popoverLoader.item.containsMouse) closeTimer.restart()
}
function closePopover() {
  openTimer.stop()
  closeTimer.stop()
  pendingAnchor = null
  pendingRecord = null
  activeAnchor = null
  activeRecord = null
}
Timer { id: openTimer; interval: 180; onTriggered: { root.activeAnchor = root.pendingAnchor; root.activeRecord = root.pendingRecord } }
Timer { id: closeTimer; interval: 220; onTriggered: root.closePopover() }
```

Use a `Loader` so the `PopupCard` exists only when an active anchor exists. Wire each button's `hoverChanged` to `requestPopover`/`leavePopoverTarget`. Observe `containsMouse` so entering the popover cancels `closeTimer` and leaving restarts it. If the active workspace record becomes empty or its workspace disappears, call `closePopover()`.

- [ ] **Step 5: Run automated checks**

Run:

```bash
node --test tests/*.test.mjs
jq empty manifest.json
git diff --check
```

Expected: all tests PASS and both validation commands are silent.

- [ ] **Step 6: Commit the hover details**

```bash
git add WorkspacePopover.qml BarWidget.qml tests/plugin-contract.test.mjs
git commit -m "feat: detalhar workspace no hover"
```

---

### Task 4: Safe installer and public documentation

**Files:**
- Create: `scripts/install.sh`
- Create: `tests/install.test.sh`
- Modify: `README.md`

**Interfaces:**
- Consumes: runtime files from Tasks 1–3 and optional `WORKSPACE_LENS_INSTALL_ROOT` for isolated tests.
- Produces: an idempotent install into `$WORKSPACE_LENS_INSTALL_ROOT/jacobsennando.workspace-lens` or the default `~/.config/omarchy/plugins/jacobsennando.workspace-lens`.

- [ ] **Step 1: Write the failing installer test**

Create `tests/install.test.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

test_root=$(mktemp -d)
trap 'rm -rf "$test_root"' EXIT

WORKSPACE_LENS_INSTALL_ROOT="$test_root/plugins" bash scripts/install.sh --no-enable
target="$test_root/plugins/jacobsennando.workspace-lens"

test -f "$target/manifest.json"
test -f "$target/BarWidget.qml"
test -f "$target/WorkspaceModel.js"
test -f "$target/WorkspaceButton.qml"
test -f "$target/WorkspacePopover.qml"
test -f "$target/AppIcon.qml"
jq -e '.omarchy.clonedFrom == "omarchy.workspaces"' "$target/manifest.json" >/dev/null
```

- [ ] **Step 2: Run the test and verify the red state**

Run: `bash tests/install.test.sh`

Expected: FAIL because `scripts/install.sh` does not exist.

- [ ] **Step 3: Implement non-destructive installation**

Create `scripts/install.sh` with `set -euo pipefail`. Resolve the repository root from the script path, default the plugin root to `$HOME/.config/omarchy/plugins`, and accept only `--no-enable`. Copy the six runtime files into a temporary sibling directory, then:

- abort with a clear message if the final target already exists and is not a prior Workspace Lens installation;
- if the target contains `manifest.json` with ID `jacobsennando.workspace-lens`, replace it through a sibling backup plus atomic rename;
- remove the backup only after the new target is complete;
- when not passed `--no-enable`, run `omarchy-shell shell rescanPlugins` and `omarchy plugin enable jacobsennando.workspace-lens`;
- print the installed path and whether activation ran.

Do not use `sudo`, touch `/usr/share/omarchy`, or modify `shell.json` directly.

- [ ] **Step 4: Document installation and development**

Update `README.md` with:

- requirements: Omarchy 4, Quickshell 0.3, Hyprland;
- `bash scripts/install.sh` installation command;
- explanation that enabling replaces `omarchy.workspaces` through manifest metadata;
- behavior: three icons, counts, `+N`, 180/220 ms hover, informational panel;
- test command: `node --test tests/*.test.mjs && bash tests/install.test.sh`;
- safe removal command: `omarchy plugin disable jacobsennando.workspace-lens`, followed by removal of the exact user plugin directory only;
- project status and link to the design spec.

- [ ] **Step 5: Run installer checks**

Run:

```bash
bash -n scripts/install.sh tests/install.test.sh
bash tests/install.test.sh
node --test tests/*.test.mjs
git diff --check
```

Expected: all commands succeed with no diff whitespace errors.

- [ ] **Step 6: Commit installer and docs**

```bash
git add scripts/install.sh tests/install.test.sh README.md
git commit -m "feat: instalar plugin com segurança"
```

---

### Task 5: Live Omarchy integration and visual completion

**Files:**
- Modify: runtime QML/JS files only for defects found by live verification.
- Create: `.impeccable/review/bar-normal.png`
- Create: `.impeccable/review/bar-hover.png`
- Create: `.impeccable/review/bar-overflow.png`
- Create: `DESIGN.md`
- Modify: `README.md` only if verified behavior differs from its instructions.

**Interfaces:**
- Consumes: installed plugin, running Omarchy Shell, real Hyprland workspace/toplevel data, approved Workspace Lens direction, and incumbent Omarchy sibling widgets.
- Produces: live functional proof, validated screenshots, durable design documentation, and a clean plugin load.

- [ ] **Step 1: Load the Impeccable implementation floor before UI edits**

Read `/home/jacobsen/.agents/skills/impeccable/reference/craft-floor.md` completely, then inspect `BarWidget.qml`, `WorkspaceButton.qml`, `WorkspacePopover.qml`, and the installed sibling widgets `Workspaces.qml` and `ActiveWindow.qml`. Treat this as the required pre-edit quality gate.

- [ ] **Step 2: Run the full pre-install suite**

Run:

```bash
node --test tests/*.test.mjs
bash tests/install.test.sh
jq empty manifest.json
git diff --check
```

Expected: every command succeeds before changing the live shell.

- [ ] **Step 3: Install and confirm discovery**

Run:

```bash
bash scripts/install.sh
omarchy-shell shell rescanPlugins
omarchy plugin list
```

Expected: `jacobsennando.workspace-lens` is enabled and reports `omarchy.workspaces` as its clone source; the built-in workspace widget is replaced in its existing left-bar position.

- [ ] **Step 4: Verify runtime errors and real data**

Exercise the bar, then inspect the running Omarchy Quickshell instance and the latest shell logs:

```bash
quickshell list --all
quickshell log --path /usr/share/omarchy/shell --tail 200 --no-color
hyprctl -j clients | jq '[.[] | {workspace: .workspace.id, class, title}]'
```

Confirm no QML errors refer to Workspace Lens. Confirm the bar shows the actual applications/classes reported by `hyprctl`, including repeated-window grouping when available. If a runtime error occurs, state its root cause in one sentence before patching it, then rerun the focused automated test and live check.

- [ ] **Step 5: Exercise the functional matrix**

Verify manually with real windows:

1. click workspaces 1–5 and confirm focus changes;
2. open two windows of one app and confirm one icon plus a count;
3. populate four application groups and confirm three icons plus `+1`;
4. move a window to another workspace and confirm both summaries update immediately;
5. retitle and close windows and confirm the popover updates;
6. cross from target to popover without flicker;
7. move rapidly across workspace targets and confirm no stranded popover;
8. confirm an empty workspace stays numbered and opens no panel;
9. temporarily move the bar to the bottom and one vertical edge through the supported Omarchy bar settings, confirm inward anchoring and readable compact targets, then restore the original top position;
10. if multiple monitors are connected, confirm every popup remains on its originating monitor.

- [ ] **Step 6: Capture one bounded screenshot round**

Use `omarchy capture screenshot` or the installed capture tool to save valid crops as:

- `.impeccable/review/bar-normal.png`: empty, occupied, and active states;
- `.impeccable/review/bar-hover.png`: grouped apps and titles in the popover;
- `.impeccable/review/bar-overflow.png`: three icons plus `+N` backed by real windows.

Open every image once and confirm it is nonblank, correctly framed, and shows the named state. Compare them against the Workspace Lens section of the spec and the incumbent `omarchy.active-window`/`omarchy.workspaces` visual language. Batch all material corrections from this comparison into one edit pass.

- [ ] **Step 7: Confirm the visual correction batch**

Rerun the automated suite and live functional cases affected by edits. Capture at most one second screenshot round using the same filenames and validate every image. If only functional proof succeeds, report exactly `implementado, não verificado` and do not claim visual completion.

- [ ] **Step 8: Record the verified visual system**

Create `DESIGN.md` from the verified implementation, documenting only durable facts: inherited Omarchy tokens, workspace target anatomy, active/hover/empty/overflow states, popover hierarchy, icon sizing rule, 180/220 ms timing, truncation, orientation behavior, and anti-patterns. Do not record Hackerman hex values as product tokens.

- [ ] **Step 9: Run final verification**

Run:

```bash
node --test tests/*.test.mjs
bash tests/install.test.sh
jq empty manifest.json
git diff --check
git status --short
```

Expected: tests and validators succeed; `git status` lists only the intended runtime fixes, `DESIGN.md`, and gitignored screenshots do not appear.

- [ ] **Step 10: Commit the verified integration**

```bash
git add BarWidget.qml WorkspaceButton.qml WorkspacePopover.qml AppIcon.qml WorkspaceModel.js README.md DESIGN.md
git commit -m "feat: concluir workspace lens"
```

Only add files that actually changed; omit unchanged paths from `git add`.

---

### Task 6: Repository verification and publication

**Files:**
- Modify: none unless verification reveals a scoped documentation error.

**Interfaces:**
- Consumes: all commits from Tasks 1–5.
- Produces: a clean `main` branch pushed to `origin` with passing tests and an installed, verified local plugin.

- [ ] **Step 1: Verify all repository evidence**

Run:

```bash
node --test tests/*.test.mjs
bash tests/install.test.sh
jq empty manifest.json
git diff --check
git status --short --branch
git log --oneline --decorate -8
```

Expected: tests pass, validators are silent, worktree is clean, and task commits use Portuguese Conventional Commit subjects at most 50 characters long.

- [ ] **Step 2: Verify the remote target before publication**

Run:

```bash
git remote get-url origin
gh repo view JacobsenNando/workspace-lens --json nameWithOwner,visibility,defaultBranchRef,url
```

Expected: origin is `https://github.com/JacobsenNando/workspace-lens.git`, visibility is `PUBLIC`, and default branch is `main`.

- [ ] **Step 3: Push the implementation**

Run: `git push origin main`

Expected: Git reports `main -> main` or `Everything up-to-date`.

- [ ] **Step 4: Confirm the published commit**

Run:

```bash
git rev-parse HEAD
gh api repos/JacobsenNando/workspace-lens/commits/main --jq .sha
```

Expected: both SHA values are identical.
