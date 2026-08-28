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
  assert.doesNotMatch(qml, /hyprctl\s+-j/);
  assert.match(qml, /Hyprland\.workspaces/);
  assert.match(qml, /WorkspaceModel\.buildWorkspace/);
});

test("resolves web apps through desktop entries, not a hard-coded table", () => {
  const model = readFileSync("WorkspaceModel.js", "utf8");
  const bar = readFileSync("BarWidget.qml", "utf8");
  assert.match(model, /function findWebAppEntry\(host, entries\)/);
  assert.doesNotMatch(model, /\/usr\/share\/icons/);
  assert.match(bar, /WorkspaceModel\.findWebAppEntry\(host, DesktopEntries\.applications\.values\)/);
});

test("bar adapter filters Hyprland events and caches metadata", () => {
  const bar = readFileSync("BarWidget.qml", "utf8");
  assert.match(bar, /WorkspaceModel\.isWorkspaceEvent\(event\.name\)/);
  assert.match(bar, /metadataCache: Object\.create\(null\)/);
  assert.match(bar, /onApplicationsChanged/);
  assert.match(bar, /icon: root\.iconSource\(meta\.iconName, appId\)/);
});

test("workspace button is a bar click target", () => {
  const button = readFileSync("WorkspaceButton.qml", "utf8");
  assert.match(button, /function triggerPress\(button\)/);
  assert.match(button, /registerClickTarget/);
  assert.match(button, /acceptedButtons:\s*Qt\.RightButton \| Qt\.MiddleButton/);
});

test("popover is click-through while fading out", () => {
  const popover = readFileSync("WorkspacePopover.qml", "utf8");
  assert.match(popover, /mask:\s*open \? null : emptyMask/);
  assert.match(popover, /property var emptyMask: Region \{ \}/);
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

test("popover renders application-controlled text as plain text", () => {
  const popover = readFileSync("WorkspacePopover.qml", "utf8");
  const appIcon = readFileSync("AppIcon.qml", "utf8");
  assert.match(popover, /id:\s*groupName[\s\S]*?textFormat:\s*Text\.PlainText/);
  assert.match(popover, /id:\s*titleLabel[\s\S]*?textFormat:\s*Text\.PlainText/);
  assert.match(popover, /function tooltipPlainText\(value\)/);
  assert.match(popover, /showTooltip\(titleHover, root\.tooltipPlainText\(titleLabel\.text\)\)/);
  assert.match(appIcon, /text:\s*root\.label\.slice\(0, 1\)\.toUpperCase\(\) \|\| "\?"[\s\S]*?textFormat:\s*Text\.PlainText/);
});
