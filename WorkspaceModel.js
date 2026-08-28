function text(value) {
  return value === undefined || value === null ? "" : String(value).trim();
}

function normalizeAppId(value) {
  var id = text(value).toLowerCase();
  return id.slice(-8) === ".desktop" ? id.slice(0, -8) : id;
}

function hyprlandAppId(toplevel) {
  var value = toplevel || {};
  var ipc = value.lastIpcObject || {};
  var wayland = value.wayland || {};
  return text(ipc.class) || text(wayland.appId) || text(value.appId);
}

// Hyprland events that can change what a workspace contains or which one is
// focused. Everything else (keyboard layout, submap, monitor added, ...) is
// ignored so the bar is not rebuilt on unrelated activity.
var WORKSPACE_EVENTS = {
  "openwindow": true,
  "closewindow": true,
  "movewindow": true,
  "movewindowv2": true,
  "windowtitle": true,
  "windowtitlev2": true,
  "workspace": true,
  "workspacev2": true,
  "createworkspace": true,
  "createworkspacev2": true,
  "destroyworkspace": true,
  "destroyworkspacev2": true,
  "moveworkspace": true,
  "moveworkspacev2": true,
  "focusedmon": true,
  "focusedmonv2": true,
  "activewindow": true,
  "activewindowv2": true,
  "urgent": true
};

function isWorkspaceEvent(name) {
  return WORKSPACE_EVENTS[text(name).toLowerCase()] === true;
}

// Browser web apps get a window class such as "brave-web.whatsapp.com__-Default"
// or "chrome-youtube.com__-Default". The host between the browser prefix and
// "__" identifies the site the app was installed for.
function webAppHost(appId) {
  var match = /^(?:brave|chrome|chromium|msedge|vivaldi|opera)-([a-z0-9.-]+)__/i.exec(text(appId));
  return match ? stripWww(match[1].toLowerCase()) : "";
}

function stripWww(host) {
  return host.indexOf("www.") === 0 ? host.slice(4) : host;
}

function execHost(execString) {
  var match = /https?:\/\/([^\/\s'"]+)/i.exec(text(execString));
  return match ? stripWww(match[1].toLowerCase()) : "";
}

// Some Omarchy web apps launch through "omarchy-webapp-handler-<slug> %u"
// instead of a literal URL (HEY, Zoom). The slug names the site.
function execHandlerSlug(execString) {
  var match = /omarchy-webapp-handler-([a-z0-9-]+)/i.exec(text(execString));
  return match ? match[1].toLowerCase() : "";
}

function hostHasLabel(host, label) {
  if (!label) return false;
  var labels = host.split(".");
  labels.pop(); // never match the TLD
  return labels.indexOf(label) !== -1;
}

// Omarchy web apps are desktop entries whose Exec launches the site, either
// as a literal URL or through a handler script. Match the window-class host
// against that so installed web apps resolve to their own name and icon
// without a hand-written table. A URL match wins over a handler match.
function findWebAppEntry(host, entries) {
  var wanted = stripWww(text(host).toLowerCase());
  if (!wanted) return null;
  var source = entries || [];
  var byHandler = null;
  for (var i = 0; i < source.length; i++) {
    var entry = source[i];
    if (!entry) continue;
    if (execHost(entry.execString) === wanted) return entry;
    if (!byHandler && hostHasLabel(wanted, execHandlerSlug(entry.execString))) byHandler = entry;
  }
  return byHandler;
}

// Browsers and many apps append " - AppName" to the window title; the group
// header already names the app, so the suffix only repeats it.
function stripAppSuffix(title, name) {
  var value = text(title);
  var app = text(name);
  if (!value || !app) return value;
  var lower = value.toLowerCase();
  var suffixes = [" - ", " \u2014 ", " \u2013 ", " | "];
  for (var i = 0; i < suffixes.length; i++) {
    var suffix = suffixes[i] + app.toLowerCase();
    if (lower.length > suffix.length && lower.slice(-suffix.length) === suffix)
      return value.slice(0, value.length - suffix.length).trim();
  }
  return value;
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
  var byKey = Object.create(null);
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
    group.titles.push(stripAppSuffix(title, group.name) || group.name);
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
