import QtQuick
import qs.Commons
import qs.Ui
import "MediaModel.js" as MediaModel

Row {
  id: root

  property var bar: null
  property real trackPosition: 0
  property real trackLength: 0
  property bool canSeek: false
  property bool isSeeking: false
  property real liveValue: trackPosition

  onTrackPositionChanged: if (!isSeeking) liveValue = trackPosition

  signal seekRequested(real position)

  width: parent ? parent.width : implicitWidth
  spacing: Style.space(8)

  Text {
    id: elapsedLabel
    textFormat: Text.PlainText
    text: MediaModel.formatTime(root.liveValue)
    color: Qt.darker(root.bar ? root.bar.foreground : Color.foreground, 1.35)
    font.family: root.bar ? root.bar.fontFamily : Style.font.family
    font.pixelSize: Style.font.caption
    anchors.verticalCenter: parent.verticalCenter
    width: Math.max(Style.space(36), implicitWidth)
    horizontalAlignment: Text.AlignRight
  }

  PanelSlider {
    id: slider
    bar: root.bar
    width: Math.max(Style.space(80), root.width - elapsedLabel.width - durationLabel.width - root.spacing * 2)
    anchors.verticalCenter: parent.verticalCenter
    minimum: 0
    maximum: root.trackLength > 0 ? root.trackLength : 0.0001
    value: root.trackPosition
    liveValue: root.isSeeking ? root.liveValue : root.trackPosition
    dragging: root.isSeeking
    enabled: root.canSeek
    step: 5
    opacity: root.canSeek ? 1.0 : 0.4
    onMoved: function(val) {
      root.isSeeking = true
      root.liveValue = val
    }
    onReleased: function(val) {
      root.liveValue = val
      root.seekRequested(val)
      root.isSeeking = false
    }
  }

  Text {
    id: durationLabel
    textFormat: Text.PlainText
    text: root.trackLength > 0 ? MediaModel.formatTime(root.trackLength) : "--:--"
    color: Qt.darker(root.bar ? root.bar.foreground : Color.foreground, 1.35)
    font.family: root.bar ? root.bar.fontFamily : Style.font.family
    font.pixelSize: Style.font.caption
    anchors.verticalCenter: parent.verticalCenter
    width: Math.max(Style.space(36), implicitWidth)
    horizontalAlignment: Text.AlignLeft
  }
}
