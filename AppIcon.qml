import QtQuick
import QtQuick.Window
import qs.Commons
import qs.Ui

Item {
  id: root

  required property string source
  required property string label
  required property int size

  implicitWidth: size
  implicitHeight: size
  Accessible.name: label

  Image {
    id: image
    anchors.fill: parent
    source: root.source
    asynchronous: true
    fillMode: Image.PreserveAspectFit
    sourceSize.width: width * Screen.devicePixelRatio
    sourceSize.height: height * Screen.devicePixelRatio
    Accessible.ignored: true
  }

  BorderSurface {
    anchors.fill: parent
    visible: !root.source || image.status === Image.Error
    color: Color.surface
    radius: Style.cornerRadius

    Text {
      anchors.centerIn: parent
      text: root.label.slice(0, 1).toUpperCase() || "?"
      color: Color.foreground
      font.family: Style.font.family
      font.pixelSize: Math.max(1, Math.round(root.size * 0.65))
      Accessible.ignored: true
    }
  }
}
