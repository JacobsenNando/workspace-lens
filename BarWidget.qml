import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import qs.Commons
import qs.Ui
import "WorkspaceModel.js" as WorkspaceModel

BarWidget {
    id: root
    moduleName: "jacobsennando.workspace-lens"

    property int refreshSerial: 0
    property Item pendingAnchor: null
    property var pendingRecord: null
    property Item activeAnchor: null
    property var activeRecord: null
    readonly property real trailingGap: root.vertical ? 0 : Style.spaceReal(1.5)

    function workspaceById(id) {
        var values = Hyprland.workspaces.values;
        for (var i = 0; i < values.length; i++) {
            if (values[i].id === id)
                return values[i];
        }
        return null;
    }

    function workspaceIds() {
        var ids = [1, 2, 3, 4, 5];
        var values = Hyprland.workspaces.values;
        for (var i = 0; i < values.length; i++) {
            var id = Number(values[i].id);
            if (id >= 1 && id <= 10 && ids.indexOf(id) === -1)
                ids.push(id);
        }
        ids.sort(function (left, right) {
            return left - right;
        });
        return ids;
    }

    function desktopEntryFor(appId) {
        var raw = String(appId || "").trim();
        var candidates = [raw, raw.replace(/\.desktop$/i, "")];
        for (var i = 0; i < candidates.length; i++) {
            var entry = DesktopEntries.byId(candidates[i]);
            if (entry)
                return entry;
        }
        return null;
    }

    function iconSource(icon, appId) {
        var library = root.bar && root.bar.shell ? root.bar.shell.appLibrary : null;
        if (library)
            return library.iconSource(icon || appId);
        return Quickshell.iconPath(icon || appId || "application-x-executable", "application-x-executable");
    }

    function rawWindows(workspace) {
        var values = workspace && workspace.toplevels ? workspace.toplevels.values : [];
        return values.map(function (toplevel) {
            var entry = root.desktopEntryFor(toplevel.appId);
            return {
                appId: String(toplevel.appId || ""),
                title: String(toplevel.title || ""),
                name: entry ? String(entry.name || "") : "",
                icon: root.iconSource(entry ? entry.icon : "", toplevel.appId)
            };
        });
    }

    function workspaceRecord(id) {
        var serial = root.refreshSerial;
        var workspace = root.workspaceById(id);
        var focusedId = Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : -1;
        return WorkspaceModel.buildWorkspace(id, root.rawWindows(workspace), focusedId, 3);
    }

    function focusWorkspace(id) {
        var workspace = root.workspaceById(id);
        if (workspace)
            workspace.activate();
        else if (root.bar)
            root.bar.run("hyprctl dispatch " + Util.shellQuote("hl.dsp.focus({ workspace = \"" + id + "\" })"));
    }

    function requestPopover(target, record) {
        closeTimer.stop();
        if (!record || !record.occupied) {
            closePopover();
            return;
        }
        pendingAnchor = target;
        pendingRecord = record;
        openTimer.restart();
    }

    function leavePopoverTarget(target) {
        if (pendingAnchor === target)
            openTimer.stop();
        if ((activeAnchor === target || pendingAnchor === target) && !(popoverLoader.item && popoverLoader.item.containsMouse))
            closeTimer.restart();
    }

    function closePopover() {
        openTimer.stop();
        closeTimer.stop();
        pendingAnchor = null;
        pendingRecord = null;
        activeAnchor = null;
        activeRecord = null;
    }

    function refreshPopoverRecords() {
        if (pendingRecord) {
            var pendingWorkspace = workspaceById(pendingRecord.id);
            var refreshedPending = workspaceRecord(pendingRecord.id);
            if (!pendingWorkspace || !refreshedPending.occupied) {
                openTimer.stop();
                pendingAnchor = null;
                pendingRecord = null;
            } else {
                pendingRecord = refreshedPending;
            }
        }

        if (activeRecord) {
            var activeWorkspace = workspaceById(activeRecord.id);
            var refreshedActive = workspaceRecord(activeRecord.id);
            if (!activeWorkspace || !refreshedActive.occupied)
                closePopover();
            else
                activeRecord = refreshedActive;
        }
    }

    implicitWidth: grid.implicitWidth + trailingGap
    implicitHeight: grid.implicitHeight

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            root.refreshSerial++;
            root.refreshPopoverRecords();
        }
    }

    Timer {
        id: openTimer
        interval: 180
        onTriggered: {
            if (!root.pendingAnchor || !root.pendingRecord || !root.pendingRecord.occupied)
                return;
            root.activeAnchor = root.pendingAnchor;
            root.activeRecord = root.pendingRecord;
        }
    }

    Timer {
        id: closeTimer
        interval: 220
        onTriggered: root.closePopover()
    }

    Loader {
        id: popoverLoader
        active: root.activeAnchor !== null && root.activeRecord !== null && root.activeRecord.occupied

        sourceComponent: WorkspacePopover {
            anchorItem: root.activeAnchor
            bar: root.bar
            record: root.activeRecord
            onContainsMouseChanged: {
                if (containsMouse)
                    closeTimer.stop();
                else if (root.activeAnchor !== null)
                    closeTimer.restart();
            }
        }
    }

    GridLayout {
        id: grid
        anchors.fill: parent
        anchors.rightMargin: root.trailingGap
        columns: root.vertical ? 1 : root.workspaceIds().length
        columnSpacing: root.vertical ? 0 : Style.space(1)
        rowSpacing: root.vertical ? Style.space(2) : 0

        Repeater {
            model: root.workspaceIds()

            WorkspaceButton {
                required property int modelData
                record: root.workspaceRecord(modelData)
                bar: root.bar
                vertical: root.vertical
                onHoverChanged: function (target, hovered) {
                    if (hovered)
                        root.requestPopover(target, target.record);
                    else
                        root.leavePopoverTarget(target);
                }
                onActivateRequested: function (workspaceId) {
                    root.focusWorkspace(workspaceId);
                }
            }
        }
    }
}
