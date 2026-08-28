import assert from "node:assert/strict";
import test from "node:test";
import { loadWorkspaceModel } from "./load-workspace-model.mjs";

const model = loadWorkspaceModel();

test("normalizes desktop ids", () => {
  assert.equal(model.normalizeAppId("  Org.GNOME.Nautilus.desktop  "), "org.gnome.nautilus");
});

test("prefers the Hyprland IPC class for Brave web apps", () => {
  const toplevel = {
    appId: "brave-browser",
    HyprlandToplevel: {
      handle: { lastIpcObject: { class: "brave-discord.com__channels_@me-Default" } }
    }
  };
  assert.equal(model.hyprlandAppId(toplevel), "brave-discord.com__channels_@me-Default");
});

test("resolves system icons for WhatsApp and Discord Brave web apps", () => {
  assert.equal(
    model.webAppIconPath("brave-web.whatsapp.com__-Default"),
    "/usr/share/icons/hicolor/256x256/apps/whatsapp.png"
  );
  assert.equal(
    model.webAppIconPath("brave-discord.com__channels_@me-Default"),
    "/usr/share/icons/hicolor/256x256/apps/omarchy-discord.png"
  );
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

test("groups application ids that match object prototype keys", () => {
  const result = model.buildWorkspace(2, [
    { appId: "constructor", title: "A", name: "Constructor", icon: "" },
    { appId: "constructor", title: "B", name: "Constructor", icon: "" }
  ], 2, 3);
  assert.equal(result.appCount, 1);
  assert.equal(result.groups[0].count, 2);
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
