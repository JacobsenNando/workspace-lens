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

test("bar adapter consumes live Hyprland state without polling", () => {
  const qml = readFileSync("BarWidget.qml", "utf8");
  assert.doesNotMatch(qml, /\bProcess\s*\{/);
  assert.doesNotMatch(qml, /hyprctl\s+(?:clients|workspaces|activeworkspace)\b/);
  assert.match(qml, /Hyprland\.workspaces/);
  assert.match(qml, /WorkspaceModel\.buildWorkspace/);
  assert.match(qml, /function\s+onRawEvent\s*\(event\)/);
  assert.match(qml, /hyprctl dispatch/);
});

test("bar adapter derives application ids from Hyprland IPC data", () => {
  const qml = readFileSync("BarWidget.qml", "utf8");
  assert.match(qml, /toplevel\.lastIpcObject/);
  assert.match(qml, /ipc\.class/);
  assert.doesNotMatch(qml, /desktopEntryFor\(toplevel\.appId\)/);
});

test("popover uses the approved hover contract", () => {
  const popover = readFileSync("WorkspacePopover.qml", "utf8");
  const bar = readFileSync("BarWidget.qml", "utf8");
  assert.match(popover, /triggerMode:\s*"hover"/);
  assert.match(bar, /interval:\s*180/);
  assert.match(bar, /interval:\s*220/);
  assert.doesNotMatch(popover, /\.activate\s*\(/);
  assert.doesNotMatch(popover, /\.close\s*\(/);
});

test("popover leaves Column implicit height under Qt ownership", () => {
  const popover = readFileSync("WorkspacePopover.qml", "utf8");
  assert.doesNotMatch(
    popover,
    /id:\s*contentColumn[\s\S]{0,180}\bimplicitHeight\s*:/,
  );
});

test("icon fallback uses an Omarchy color token", () => {
  const icon = readFileSync("AppIcon.qml", "utf8");
  assert.doesNotMatch(icon, /Color\.surface\b/);
  assert.match(icon, /Color\.background\b/);
});

test("popover initializes inherited PopupCard requirements", () => {
  const popover = readFileSync("WorkspacePopover.qml", "utf8");
  assert.doesNotMatch(popover, /required property Item anchorItem\b/);
  assert.doesNotMatch(popover, /required property QtObject bar\b/);
});

test("group delegate receives modelData as a required property", () => {
  const popover = readFileSync("WorkspacePopover.qml", "utf8");
  assert.match(
    popover,
    /component GroupDetails:\s*Column\s*\{[\s\S]{0,160}required property var modelData\b/,
  );
  assert.doesNotMatch(
    popover,
    /GroupDetails\s*\{[\s\S]{0,100}\bgroup:\s*modelData\b/,
  );
});
