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

  component GroupDetails: BorderSurface {
    id: groupDetails

    required property var modelData
    required property QtObject barHost

    readonly property color foreground: barHost ? barHost.barForeground : Color.foreground
    readonly property int inset: Style.space(4)

    width: ListView.view ? ListView.view.width : parent.width
    height: groupRow.implicitHeight + inset * 2
    radius: Style.cornerRadius
    color: Util.alpha(foreground, 0.06)

    Row {
      id: groupRow
      x: groupDetails.inset
      y: groupDetails.inset
      width: parent.width - groupDetails.inset * 2
      spacing: Style.space(4)

      AppIcon {
        id: appIcon
        source: groupDetails.modelData.icon
        label: groupDetails.modelData.name
        foreground: groupDetails.foreground
        size: Style.space(13)
      }

      Column {
        id: groupBody
        width: groupRow.width - appIcon.width - groupRow.spacing
        spacing: Style.space(1)

        Item {
          width: parent.width
          height: groupName.implicitHeight

          Text {
            id: groupName
            anchors.left: parent.left
            anchors.right: groupCount.left
            anchors.rightMargin: Style.space(3)
            text: groupDetails.modelData.name
            elide: Text.ElideRight
            color: groupDetails.foreground
            font.family: Style.font.family
            font.pixelSize: Style.font.body
            font.bold: true
          }

          Text {
            id: groupCount
            anchors.right: parent.right
            anchors.baseline: groupName.baseline
            text: groupDetails.modelData.count + (groupDetails.modelData.count === 1 ? " window" : " windows")
            color: groupDetails.foreground
            opacity: 0.65
            font.family: Style.font.family
            font.pixelSize: Style.font.bodySmall
            Accessible.ignored: true
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
              text: titleRow.modelData
              elide: Text.ElideRight
              color: groupDetails.foreground
              opacity: 0.75
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
    }
  }

  Column {
    id: contentColumn
    anchors.fill: parent
    spacing: Style.space(5)

    Item {
      id: header
      width: parent.width
      height: headerTitle.implicitHeight

      Text {
        id: headerTitle
        anchors.left: parent.left
        text: root.record ? "Workspace " + root.record.id : ""
        color: root.bar ? root.bar.barForeground : Color.foreground
        font.family: Style.font.family
        font.pixelSize: Style.font.body
        font.bold: true
      }

      Text {
        anchors.right: parent.right
        anchors.baseline: headerTitle.baseline
        text: root.record ? root.record.appCount + (root.record.appCount === 1 ? " app" : " apps") + " · " + root.record.windowCount + (root.record.windowCount === 1 ? " window" : " windows") : ""
        color: root.bar ? root.bar.barForeground : Color.foreground
        opacity: 0.65
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
        spacing: Style.space(3)

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
        spacing: Style.space(3)
        model: root.record ? root.record.groups : []

        delegate: GroupDetails {
          barHost: root.bar
        }
      }
    }
  }
}
