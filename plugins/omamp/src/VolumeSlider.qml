import QtQuick
import qs.Commons
import qs.Ui

Row {
  id: root

  property var bar: null
  property real volume: 1.0
  property bool volumeSupported: true
  property bool isDragging: false
  property real liveValue: volume

  onVolumeChanged: if (!isDragging) liveValue = volume

  signal volumeRequested(real value)

  width: parent ? parent.width : implicitWidth
  spacing: Style.space(8)

  readonly property real clampedVolume: Math.max(0, Math.min(1.0, liveValue))
  readonly property string volumeIcon: {
    if (clampedVolume <= 0.001) return "󰝟"
    if (clampedVolume < 0.34) return "󰕿"
    if (clampedVolume < 0.67) return "󰖀"
    return "󰕾"
  }

  Text {
    id: iconBtn
    textFormat: Text.PlainText
    text: root.volumeIcon
    color: root.bar ? root.bar.foreground : Color.foreground
    font.family: root.bar ? root.bar.fontFamily : Style.font.family
    font.pixelSize: Style.font.body
    anchors.verticalCenter: parent.verticalCenter
    width: Style.space(20)
    horizontalAlignment: Text.AlignHCenter
    renderType: Text.NativeRendering

    MouseArea {
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: root.volumeSupported ? Qt.PointingHandCursor : Qt.ArrowCursor
      enabled: root.volumeSupported
      onClicked: {
        var target = root.liveValue > 0.01 ? 0.0 : 1.0
        root.liveValue = target
        root.volumeRequested(target)
      }
    }
  }

  PanelSlider {
    id: slider
    bar: root.bar
    width: Math.max(Style.space(80), root.width - iconBtn.width - percentLabel.width - root.spacing * 2)
    anchors.verticalCenter: parent.verticalCenter
    minimum: 0
    maximum: 1.0
    value: root.volume
    liveValue: root.isDragging ? root.liveValue : root.volume
    dragging: root.isDragging
    enabled: root.volumeSupported
    step: 0.05
    opacity: root.volumeSupported ? 1.0 : 0.4
    onMoved: function(val) {
      root.isDragging = true
      root.liveValue = val
      root.volumeRequested(val)
    }
    onReleased: function(val) {
      root.liveValue = val
      root.volumeRequested(val)
      root.isDragging = false
    }
    onRightClicked: {
      if (!root.volumeSupported) return
      var target = root.liveValue > 0.01 ? 0.0 : 1.0
      root.liveValue = target
      root.volumeRequested(target)
    }
  }

  Text {
    id: percentLabel
    textFormat: Text.PlainText
    text: Math.round(root.clampedVolume * 100) + "%"
    color: Qt.darker(root.bar ? root.bar.foreground : Color.foreground, 1.35)
    font.family: root.bar ? root.bar.fontFamily : Style.font.family
    font.pixelSize: Style.font.caption
    anchors.verticalCenter: parent.verticalCenter
    width: Style.space(36)
    horizontalAlignment: Text.AlignRight
    renderType: Text.NativeRendering
  }
}
