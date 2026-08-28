import assert from "node:assert/strict";
import test from "node:test";
import { loadWorkspaceModel } from "./load-workspace-model.mjs";

const model = loadWorkspaceModel();

test("normalizes desktop ids", () => {
  assert.equal(model.normalizeAppId("  Org.GNOME.Nautilus.desktop  "), "org.gnome.nautilus");
});

test("prefers the Hyprland IPC class over the Wayland app id", () => {
  const toplevel = {
    lastIpcObject: { class: "brave-discord.com__channels_@me-Default" },
    wayland: { appId: "brave-browser" }
  };
  assert.equal(model.hyprlandAppId(toplevel), "brave-discord.com__channels_@me-Default");
  assert.equal(model.hyprlandAppId({ wayland: { appId: "kitty" } }), "kitty");
  assert.equal(model.hyprlandAppId(null), "");
});

test("extracts the site host from browser web-app classes", () => {
  assert.equal(model.webAppHost("brave-web.whatsapp.com__-Default"), "web.whatsapp.com");
  assert.equal(model.webAppHost("brave-discord.com__channels_@me-Default"), "discord.com");
  assert.equal(model.webAppHost("chrome-www.youtube.com__-Default"), "youtube.com");
  assert.equal(model.webAppHost("brave-browser"), "");
  assert.equal(model.webAppHost("kitty"), "");
});

test("matches a web-app class to the desktop entry launching that site", () => {
  const entries = [
    { name: "YouTube", icon: "youtube", execString: "omarchy-launch-webapp https://youtube.com/" },
    { name: "WhatsApp", icon: "whatsapp", execString: "omarchy-launch-webapp https://web.whatsapp.com/" },
    { name: "Ghostty", icon: "ghostty", execString: "ghostty" },
    null
  ];
  assert.equal(model.findWebAppEntry("web.whatsapp.com", entries).name, "WhatsApp");
  assert.equal(model.findWebAppEntry("www.youtube.com", entries).name, "YouTube");
  assert.equal(model.findWebAppEntry("example.com", entries), null);
  assert.equal(model.findWebAppEntry("", entries), null);
  assert.equal(model.findWebAppEntry("youtube.com", undefined), null);
});

test("refreshes only on Hyprland events that change workspace contents", () => {
  for (const name of ["openwindow", "closewindow", "movewindowv2", "windowtitlev2", "workspacev2", "focusedmonv2", "destroyworkspacev2"]) {
    assert.equal(model.isWorkspaceEvent(name), true, name);
  }
  for (const name of ["activelayout", "submap", "monitoradded", "screencast", "", undefined]) {
    assert.equal(model.isWorkspaceEvent(name), false, String(name));
  }
});

test("tolerates missing windows, zero summary and string ids", () => {
  const record = model.buildWorkspace("3", undefined, 3, 0);
  assert.equal(record.id, 3);
  assert.equal(record.focused, true);
  assert.equal(record.occupied, false);
  assert.equal(record.summaryGroups.length, 0);
  assert.equal(record.overflowCount, 0);

  const capped = model.buildWorkspace(1, [{ appId: "a" }, { appId: "b" }], 2, 0);
  assert.equal(capped.summaryGroups.length, 0);
  assert.equal(capped.overflowCount, 2);
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
