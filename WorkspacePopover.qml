import QtQuick
import Quickshell
import qs.Commons
import qs.Ui

PopupCard {
  id: root

  property var record: null
  // While fading out the window is still mapped; an empty mask makes it
  // click-through so a fast click below the bar reaches the app underneath.
  readonly property var emptyMask: Region { }
  mask: open ? null : emptyMask
  readonly property bool scrollable: contentHeight < contentColumn.implicitHeight + verticalContentInset

  triggerMode: "hover"
  contentWidth: fittedContentWidth(Style.space(340), Style.space(420))
  contentHeight: fittedContentHeight(contentColumn.implicitHeight, Style.space(520))

  component GroupDetails: Column {
    id: groupDetails

    required property var modelData
    required property QtObject barHost

    readonly property color foreground: barHost ? barHost.barForeground : Color.foreground

    width: ListView.view ? ListView.view.width : parent.width
    spacing: Style.space(2)

    Row {
      id: groupHeader
      width: parent.width
      spacing: Style.space(3)

      AppIcon {
        id: appIcon
        source: groupDetails.modelData.icon
        label: groupDetails.modelData.name
        foreground: groupDetails.foreground
        size: Style.space(10)
      }

      Text {
        width: Math.max(0, groupHeader.width - appIcon.width - groupHeader.spacing - countBadge.width - (countBadge.visible ? groupHeader.spacing : 0))
        anchors.verticalCenter: parent.verticalCenter
        text: groupDetails.modelData.name
        elide: Text.ElideRight
        color: groupDetails.foreground
        font.family: Style.font.family
        font.pixelSize: Style.font.body
        font.bold: true
      }

      BorderSurface {
        id: countBadge
        visible: groupDetails.modelData.count > 1
        width: visible ? Style.space(8) : 0
        height: visible ? Style.space(8) : 0
        anchors.verticalCenter: parent.verticalCenter
        color: Style.selectedFillFor(groupDetails.foreground, Color.accent)
        radius: width / 2
        Accessible.ignored: true

        Text {
          anchors.centerIn: parent
          text: groupDetails.modelData.count
          color: groupDetails.foreground
          font.family: Style.font.family
          font.pixelSize: Style.font.caption
          Accessible.ignored: true
        }
      }
    }

    Repeater {
      model: groupDetails.modelData.titles

      Item {
        id: titleRow

        required property string modelData
        width: parent.width
        height: titleLabel.implicitHeight

        Text {
          id: titleLabel
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.leftMargin: Style.space(13)
          text: titleRow.modelData
          elide: Text.ElideRight
          color: groupDetails.foreground
          font.family: Style.font.family
          font.pixelSize: Style.font.bodySmall
          Accessible.name: text
        }

        MouseArea {
          id: titleHover
          anchors.fill: parent
          hoverEnabled: true
          acceptedButtons: Qt.NoButton
          onEntered: if (titleLabel.truncated && groupDetails.barHost)
            groupDetails.barHost.showTooltip(titleHover, titleLabel.text)
          onExited: if (groupDetails.barHost)
            groupDetails.barHost.hideTooltip(titleHover)
        }
      }
    }
  }

  Column {
    id: contentColumn
    anchors.fill: parent
    spacing: Style.space(5)

    Row {
      id: header
      width: parent.width
      spacing: Style.space(4)

      Text {
        text: root.record ? "Workspace " + root.record.id : ""
        color: root.bar ? root.bar.barForeground : Color.foreground
        font.family: Style.font.family
        font.pixelSize: Style.font.body
        font.bold: true
      }

      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: root.record ? root.record.appCount + (root.record.appCount === 1 ? " app" : " apps") + " · " + root.record.windowCount + (root.record.windowCount === 1 ? " window" : " windows") : ""
        color: root.bar ? root.bar.barForeground : Color.foreground
        font.family: Style.font.family
        font.pixelSize: Style.font.bodySmall
        Accessible.ignored: true
      }
    }

    Item {
      id: groupsViewport
      width: parent.width
      height: root.scrollable ? Math.max(0, parent.height - header.implicitHeight - contentColumn.spacing) : groupsColumn.implicitHeight
      clip: root.scrollable

      Column {
        id: groupsColumn
        visible: !root.scrollable
        width: parent.width
        spacing: Style.space(5)

        Repeater {
          model: root.record ? root.record.groups : []

          GroupDetails {
            barHost: root.bar
          }
        }
      }

      ListView {
        visible: root.scrollable
        anchors.fill: parent
        clip: true
        spacing: Style.space(5)
        model: root.record ? root.record.groups : []

        delegate: GroupDetails {
          barHost: root.bar
        }
      }
    }
  }
}
