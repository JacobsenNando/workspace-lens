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

test("uses the official system WhatsApp asset for Brave web-app ids", () => {
  const qml = readFileSync("BarWidget.qml", "utf8");
  assert.match(qml, /function systemIconPath\(appId\)/);
  assert.match(qml, /brave-web\.whatsapp\.com/);
  assert.match(qml, /\/usr\/share\/icons\/hicolor\/256x256\/apps\/whatsapp\.png/);
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
