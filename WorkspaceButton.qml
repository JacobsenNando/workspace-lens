import QtQuick
import qs.Commons
import qs.Ui

Item {
  id: root

  required property var record
  required property var bar
  required property bool vertical

  signal hoverChanged(Item target, bool hovered)
  signal activateRequested(int workspaceId)

  // Bar click-target contract (see Ui/WidgetButton.qml): the bar host routes
  // presses to registered targets, so clicks behave like the built-in widget.
  property bool interactive: true
  property bool pressable: true
  property bool concealed: false
  property var registeredBar: null

  function triggerPress(button) {
    if (root.bar) root.bar.hideTooltip(root)
    if (root.pressable) root.activate()
  }

  function syncClickRegistration() {
    if (registeredBar && registeredBar.unregisterClickTarget) registeredBar.unregisterClickTarget(root)
    registeredBar = root.bar
    if (registeredBar && registeredBar.registerClickTarget) registeredBar.registerClickTarget(root)
  }

  onBarChanged: syncClickRegistration()
  Component.onCompleted: syncClickRegistration()
  Component.onDestruction: if (registeredBar && registeredBar.unregisterClickTarget) registeredBar.unregisterClickTarget(root)

  readonly property int barSize: bar ? bar.barSize : Style.bar.sizeHorizontal
  readonly property int iconSize: Style.space(12)
  readonly property color foreground: bar ? bar.barForeground : Color.foreground

  function activate() {
    root.activateRequested(root.record.id)
  }

  implicitWidth: vertical
    ? barSize
    : Math.max(Style.space(20), horizontalContent.implicitWidth + Style.space(6))
  implicitHeight: barSize
  Accessible.role: Accessible.Button
  Accessible.name: "Workspace " + record.id + ", " + record.appCount + " apps, " + record.windowCount + " windows"
  Accessible.onPressAction: root.activate()

  BorderSurface {
    anchors.fill: parent
    radius: Style.cornerRadius
    color: root.record.focused
      ? Style.selectedFillFor(root.foreground, Color.accent)
      : (mouse.containsMouse ? Style.hoverFillFor(root.foreground, Color.accent) : "transparent")
    borderSpec: root.record.focused
      ? Border.controlSpec("selected", root.foreground, Color.accent)
      : Border.none()
  }

  Rectangle {
    width: root.vertical ? Style.space(2) : parent.width
    height: root.vertical ? parent.height : Style.space(2)
    anchors.right: root.vertical ? parent.right : undefined
    anchors.bottom: root.vertical ? undefined : parent.bottom
    visible: root.record.focused
    color: Color.accent
    radius: Style.space(1)
    Accessible.ignored: true
  }

  Row {
    id: horizontalContent
    visible: !root.vertical
    anchors.centerIn: parent
    spacing: Style.space(4)

    Text {
      width: Style.space(8)
      anchors.verticalCenter: parent.verticalCenter
      horizontalAlignment: Text.AlignHCenter
      text: root.record.id === 10 ? "0" : String(root.record.id)
      color: root.foreground
      opacity: root.record.occupied || root.record.focused ? 1 : 0.5
      font.family: Style.font.family
      font.pixelSize: Style.font.body
      font.bold: root.record.focused
      Accessible.ignored: true
    }

    Repeater {
      model: root.record.summaryGroups

      Item {
        required property var modelData
        width: icon.implicitWidth
        height: icon.implicitHeight
        anchors.verticalCenter: parent.verticalCenter

        AppIcon {
          id: icon
          source: modelData.icon
          label: modelData.name
          size: root.iconSize
        }

        BorderSurface {
          visible: modelData.count > 1
          width: Style.space(8)
          height: Style.space(8)
          anchors.right: parent.right
          anchors.bottom: parent.bottom
          radius: width / 2
          color: Style.selectedFillFor(root.foreground, Color.accent)
          Accessible.ignored: true

          Text {
            anchors.centerIn: parent
            text: modelData.count
            color: root.foreground
            font.family: Style.font.family
            font.pixelSize: Style.font.caption
            Accessible.ignored: true
          }
        }
      }
    }

    Text {
      visible: root.record.overflowCount > 0
      anchors.verticalCenter: parent.verticalCenter
      text: "+" + root.record.overflowCount
      color: root.foreground
      font.family: Style.font.family
      font.pixelSize: Style.font.caption
      Accessible.ignored: true
    }
  }

  Column {
    id: verticalContent
    visible: root.vertical
    anchors.centerIn: parent
    spacing: Style.space(1)

    Text {
      width: Style.space(12)
      horizontalAlignment: Text.AlignHCenter
      text: root.record.id === 10 ? "0" : String(root.record.id)
      color: root.foreground
      opacity: root.record.occupied || root.record.focused ? 1 : 0.5
      font.family: Style.font.family
      font.pixelSize: Style.font.body
      font.bold: root.record.focused
      Accessible.ignored: true
    }

    Row {
      anchors.horizontalCenter: parent.horizontalCenter
      spacing: Style.space(2)

      Repeater {
        model: root.record.summaryGroups

        Item {
          required property var modelData
          width: icon.implicitWidth
          height: icon.implicitHeight

          AppIcon {
            id: icon
            source: modelData.icon
            label: modelData.name
            size: Style.space(8)
          }

          Text {
            visible: modelData.count > 1
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            text: modelData.count
            color: Color.accent
            font.family: Style.font.family
            font.pixelSize: Style.font.caption
            Accessible.ignored: true
          }
        }
      }

      Text {
        visible: root.record.overflowCount > 0
        text: "+" + root.record.overflowCount
        color: root.foreground
        font.family: Style.font.family
        font.pixelSize: Style.font.caption
        Accessible.ignored: true
      }
    }
  }

  // Hover only; presses arrive through the bar host via triggerPress().
  MouseArea {
    id: mouse
    anchors.fill: parent
    hoverEnabled: true
    acceptedButtons: Qt.NoButton
    cursorShape: Qt.PointingHandCursor
    onEntered: root.hoverChanged(root, true)
    onExited: root.hoverChanged(root, false)
  }
}
