import QtQuick
import QtQuick.Effects
import qs.Commons
import qs.Ui

BorderSurface {
  id: root

  property string artSource: ""
  property color foreground: Color.foreground
  property string fontFamily: Style.font.family
  property real glyphSize: Style.font.displayLarge
  property real inset: Style.space(2)
  property bool canRaise: false

  signal raiseRequested()

  radius: Style.cornerRadius
  color: Style.normalFillFor(root.foreground, Color.accent)
  borderSpec: Border.controlSpec("normal", root.foreground, Color.accent)

  Item {
    id: artClip
    anchors.fill: parent
    anchors.margins: root.inset
    visible: art.status === Image.Ready
    layer.enabled: true
    layer.smooth: true
    layer.effect: MultiEffect {
      maskEnabled: true
      maskSource: artMask
      maskThresholdMin: 0.5
      maskSpreadAtMin: 0.1
    }

    Image {
      id: art
      anchors.fill: parent
      fillMode: Image.PreserveAspectCrop
      asynchronous: true
      source: root.artSource
    }
  }

  Rectangle {
    id: artMask
    anchors.fill: artClip
    radius: Math.max(0, root.radius - root.inset)
    color: "black"
    visible: false
    layer.enabled: true
    layer.smooth: true
  }

  Text {
    anchors.centerIn: parent
    visible: !artClip.visible
    textFormat: Text.PlainText
    text: "󰝚"
    color: root.foreground
    font.family: root.fontFamily
    font.pixelSize: root.glyphSize
    renderType: Text.NativeRendering
  }

  MouseArea {
    anchors.fill: parent
    enabled: root.canRaise
    cursorShape: root.canRaise ? Qt.PointingHandCursor : Qt.ArrowCursor
    onClicked: root.raiseRequested()
  }
}
