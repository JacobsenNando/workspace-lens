function text(value) {
  return value === undefined || value === null ? "" : String(value).trim();
}

function normalizeAppId(value) {
  var id = text(value).toLowerCase();
  return id.slice(-8) === ".desktop" ? id.slice(0, -8) : id;
}

function hyprlandAppId(toplevel) {
  var value = toplevel || {};
  var attached = value.HyprlandToplevel || {};
  var handle = attached.handle || value;
  var ipc = handle.lastIpcObject || {};
  var wayland = value.wayland || {};
  return text(ipc.class) || text(value.appId) || text(wayland.appId);
}

function webAppIconPath(appId) {
  var id = normalizeAppId(appId);
  if (id.indexOf("brave-web.whatsapp.com") === 0)
    return "/usr/share/icons/hicolor/256x256/apps/whatsapp.png";
  if (id.indexOf("brave-discord.com") === 0)
    return "/usr/share/icons/hicolor/256x256/apps/omarchy-discord.png";
  return "";
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
