import QtQuick
import qs.Commons
import qs.Ui
import "MediaModel.js" as MediaModel

PopupCard {
  id: root

  property var playerWidget: null

  readonly property var activePlayer: playerWidget ? playerWidget.activePlayer : null
  readonly property var sourcePlayers: playerWidget ? playerWidget.sourcePlayers : []
  readonly property var trackHistory: playerWidget ? playerWidget.trackHistory : []
  readonly property var nativeQueue: playerWidget ? playerWidget.nativeQueue : []
  readonly property var upcomingQueue: playerWidget ? playerWidget.upcomingQueue : []
  readonly property bool hasNativeQueue: playerWidget ? playerWidget.hasNativeQueue : false
  readonly property bool hasUpcomingQueue: playerWidget ? playerWidget.hasUpcomingQueue : false
  readonly property bool isPlaying: playerWidget ? playerWidget.isPlaying : false
  readonly property string artUrl: playerWidget ? playerWidget.artUrl : ""
  readonly property string title: playerWidget ? playerWidget.title : ""
  readonly property string artist: playerWidget ? playerWidget.artist : ""
  readonly property string album: playerWidget ? playerWidget.album : ""
  readonly property real trackPosition: playerWidget ? playerWidget.trackPosition : 0
  readonly property real trackLength: playerWidget ? playerWidget.trackLength : 0
  readonly property bool canSeek: playerWidget ? playerWidget.canSeek : false

  readonly property bool canRaise: activePlayer ? (activePlayer.canRaise === true) : false
  readonly property bool shuffleSupported: activePlayer ? activePlayer.shuffleSupported : false
  readonly property bool loopSupported: activePlayer ? activePlayer.loopSupported : false
  readonly property string appName: MediaModel.playerDisplayName(activePlayer)

  property string activeTab: "queue"

  contentWidth: root.fittedContentWidth(Style.space(340))
  contentHeight: root.fittedContentHeight(layout.implicitHeight)

  readonly property real artSize: Style.space(64)

  Item {
    anchors.fill: parent

    Column {
      id: layout
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      spacing: Style.space(10)

      // Header: Album art and track info
      Row {
        width: parent.width
        spacing: Style.space(10)

        AlbumArt {
          id: art
          width: root.artSize
          height: root.artSize
          anchors.verticalCenter: parent.verticalCenter
          artSource: root.artUrl
          canRaise: root.canRaise
          foreground: root.bar ? root.bar.foreground : Color.foreground
          fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
          onRaiseRequested: {
            if (root.activePlayer && root.activePlayer.canRaise) {
              root.activePlayer.raise()
            }
          }
        }

        Column {
          width: parent.width - art.width - parent.spacing
          anchors.verticalCenter: parent.verticalCenter
          spacing: Style.space(3)

          Row {
            width: parent.width
            spacing: Style.space(6)

            Text {
              textFormat: Text.PlainText
              width: Math.max(0, parent.width - (appBadge.visible ? appBadge.width + parent.spacing : 0))
              text: root.title || "Nothing playing"
              color: root.bar ? root.bar.foreground : Color.foreground
              font.family: root.bar ? root.bar.fontFamily : Style.font.family
              font.pixelSize: Style.font.subtitle
              font.bold: true
              renderType: Text.NativeRendering
              elide: Text.ElideRight
              anchors.verticalCenter: parent.verticalCenter
            }

            BorderSurface {
              id: appBadge
              visible: root.appName !== ""
              radius: 0
              anchors.verticalCenter: parent.verticalCenter
              implicitWidth: appLabel.implicitWidth + Style.space(8)
              implicitHeight: appLabel.implicitHeight + Style.space(2)
              color: "transparent"
              borderSpec: Border.controlSpec("normal", root.bar ? root.bar.foreground : Color.foreground, Color.accent)

              Text {
                id: appLabel
                textFormat: Text.PlainText
                anchors.centerIn: parent
                text: root.appName.toUpperCase()
                color: Qt.darker(root.bar ? root.bar.foreground : Color.foreground, 1.4)
                font.family: root.bar ? root.bar.fontFamily : Style.font.family
                font.pixelSize: Style.font.caption - 2
                font.bold: true
                renderType: Text.NativeRendering
              }
            }
          }

          Text {
            textFormat: Text.PlainText
            text: root.artist
            color: Qt.darker(root.bar ? root.bar.foreground : Color.foreground, 1.3)
            font.family: root.bar ? root.bar.fontFamily : Style.font.family
            font.pixelSize: Style.font.bodySmall
            renderType: Text.NativeRendering
            elide: Text.ElideRight
            width: parent.width
            visible: text !== ""
          }

          Text {
            textFormat: Text.PlainText
            text: root.album
            color: Qt.darker(root.bar ? root.bar.foreground : Color.foreground, 1.6)
            font.family: root.bar ? root.bar.fontFamily : Style.font.family
            font.pixelSize: Style.font.caption
            renderType: Text.NativeRendering
            elide: Text.ElideRight
            width: parent.width
            visible: text !== ""
          }
        }
      }

      // Time and seek slider
      Column {
        width: parent.width
        spacing: Style.space(4)
        visible: root.playerWidget ? root.playerWidget.hasMedia : false

        TimeSlider {
          id: timeSlider
          bar: root.bar
          width: parent.width
          trackPosition: root.trackPosition
          trackLength: root.trackLength
          canSeek: root.canSeek
          onSeekRequested: function(pos) {
            if (root.playerWidget) root.playerWidget.seekTo(pos)
          }
        }
      }

      // Playback Controls Row
      Row {
        id: controlsRow
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: Style.space(6)

        Button {
          id: shuffleBtn
          radius: 0
          iconText: "󰒝"
          tooltipText: "Shuffle"
          foreground: root.bar ? root.bar.foreground : Color.foreground
          iconSize: Style.font.icon
          width: Style.space(34)
          height: Style.space(30)
          horizontalPadding: 0
          verticalPadding: 0
          anchors.verticalCenter: parent.verticalCenter
          selected: root.activePlayer && root.activePlayer.shuffle
          enabled: root.activePlayer && root.shuffleSupported
          opacity: enabled ? 1.0 : 0.35
          onClicked: if (root.activePlayer) root.activePlayer.shuffle = !root.activePlayer.shuffle
        }

        Button {
          id: prevBtn
          radius: 0
          iconText: "󰒮"
          tooltipText: "Previous"
          foreground: root.bar ? root.bar.foreground : Color.foreground
          iconSize: Style.font.icon
          width: Style.space(38)
          height: Style.space(30)
          horizontalPadding: 0
          verticalPadding: 0
          anchors.verticalCenter: parent.verticalCenter
          enabled: root.activePlayer && root.activePlayer.canGoPrevious
          opacity: enabled ? 1.0 : 0.35
          onClicked: if (root.playerWidget) root.playerWidget.runAction("previous")
        }

        Button {
          id: playPauseBtn
          radius: 0
          iconText: root.isPlaying ? "󰏤" : "󰐊"
          tooltipText: root.isPlaying ? "Pause" : "Play"
          foreground: root.bar ? root.bar.foreground : Color.foreground
          iconSize: Style.font.icon
          width: Style.space(48)
          height: Style.space(30)
          horizontalPadding: 0
          verticalPadding: 0
          anchors.verticalCenter: parent.verticalCenter
          enabled: root.activePlayer && (root.activePlayer.canTogglePlaying || root.activePlayer.canPlay || root.activePlayer.canPause)
          opacity: enabled ? 1.0 : 0.35
          onClicked: if (root.playerWidget) root.playerWidget.runAction("playPause")
        }

        Button {
          id: nextBtn
          radius: 0
          iconText: "󰒭"
          tooltipText: "Next"
          foreground: root.bar ? root.bar.foreground : Color.foreground
          iconSize: Style.font.icon
          width: Style.space(38)
          height: Style.space(30)
          horizontalPadding: 0
          verticalPadding: 0
          anchors.verticalCenter: parent.verticalCenter
          enabled: root.activePlayer && root.activePlayer.canGoNext
          opacity: enabled ? 1.0 : 0.35
          onClicked: if (root.playerWidget) root.playerWidget.runAction("next")
        }

        Button {
          id: loopBtn
          radius: 0
          iconText: (root.activePlayer && root.activePlayer.loopState === 1) ? "󰑘" : "󰑖"
          tooltipText: "Loop"
          foreground: root.bar ? root.bar.foreground : Color.foreground
          iconSize: Style.font.icon
          width: Style.space(34)
          height: Style.space(30)
          horizontalPadding: 0
          verticalPadding: 0
          anchors.verticalCenter: parent.verticalCenter
          selected: root.activePlayer && root.activePlayer.loopState > 0
          enabled: root.activePlayer && root.loopSupported
          opacity: enabled ? 1.0 : 0.35
          onClicked: {
            if (!root.activePlayer) return
            var nextState = (root.activePlayer.loopState + 1) % 3
            root.activePlayer.loopState = nextState
          }
        }
      }

      // Separator
      PanelSeparator {
        visible: root.sourcePlayers.length > 1 || root.hasUpcomingQueue
        foreground: root.bar ? root.bar.foreground : Color.foreground
      }

      // Tab switcher when both multiple sources and upcoming queue are available
      Row {
        visible: root.sourcePlayers.length > 1 && root.hasUpcomingQueue
        width: parent.width
        spacing: Style.space(6)

        Button {
          width: (parent.width - parent.spacing) / 2
          height: Style.space(26)
          radius: 0
          selected: root.activeTab === "queue"
          text: "Queue (" + root.upcomingQueue.length + ")"
          foreground: root.bar ? root.bar.foreground : Color.foreground
          onClicked: root.activeTab = "queue"
        }

        Button {
          width: (parent.width - parent.spacing) / 2
          height: Style.space(26)
          radius: 0
          selected: root.activeTab === "sources"
          text: "Sources (" + root.sourcePlayers.length + ")"
          foreground: root.bar ? root.bar.foreground : Color.foreground
          onClicked: root.activeTab = "sources"
        }
      }

      // Upcoming Queue View (renders strictly upcoming tracks)
      Column {
        id: queueSection
        visible: (root.activeTab === "queue" || root.sourcePlayers.length <= 1) && root.hasUpcomingQueue
        width: parent.width
        spacing: Style.space(4)

        PanelSectionHeader {
          width: parent.width
          text: "UPCOMING QUEUE (" + root.upcomingQueue.length + ")"
          foreground: root.bar ? root.bar.foreground : Color.foreground
        }

        Repeater {
          model: root.upcomingQueue

          BorderSurface {
            id: queueRow
            required property var modelData
            required property int index

            readonly property var item: modelData

            width: queueSection.width
            height: queueInner.implicitHeight + Style.space(6)
            radius: 0
            color: queueHover.containsMouse ? Style.hoverFillFor(root.bar ? root.bar.foreground : Color.foreground, Color.accent) : "transparent"
            borderSpec: Border.none()

            Row {
              id: queueInner
              anchors.left: parent.left
              anchors.right: parent.right
              anchors.verticalCenter: parent.verticalCenter
              anchors.leftMargin: queueRow.borderLeft + Style.space(8)
              anchors.rightMargin: queueRow.borderRight + Style.space(8)
              spacing: Style.space(8)

              Text {
                textFormat: Text.PlainText
                text: String(queueRow.index + 1)
                color: Qt.darker(root.bar ? root.bar.foreground : Color.foreground, 1.6)
                font.family: root.bar ? root.bar.fontFamily : Style.font.family
                font.pixelSize: Style.font.caption
                font.bold: true
                width: Style.space(16)
                renderType: Text.NativeRendering
                horizontalAlignment: Text.AlignHCenter
                anchors.verticalCenter: parent.verticalCenter
              }

              Column {
                width: parent.width - Style.space(64)
                spacing: Style.space(1)
                anchors.verticalCenter: parent.verticalCenter

                Text {
                  textFormat: Text.PlainText
                  text: queueRow.item ? queueRow.item.title : ""
                  color: root.bar ? root.bar.foreground : Color.foreground
                  font.family: root.bar ? root.bar.fontFamily : Style.font.family
                  font.pixelSize: Style.font.bodySmall
                  renderType: Text.NativeRendering
                  elide: Text.ElideRight
                  width: parent.width
                }

                Text {
                  textFormat: Text.PlainText
                  text: queueRow.item ? queueRow.item.artist : ""
                  color: Qt.darker(root.bar ? root.bar.foreground : Color.foreground, 1.5)
                  font.family: root.bar ? root.bar.fontFamily : Style.font.family
                  font.pixelSize: Style.font.caption
                  renderType: Text.NativeRendering
                  elide: Text.ElideRight
                  width: parent.width
                  visible: text !== ""
                }
              }

              Text {
                textFormat: Text.PlainText
                text: queueRow.item && queueRow.item.length > 0 ? MediaModel.formatTime(queueRow.item.length) : ""
                color: Qt.darker(root.bar ? root.bar.foreground : Color.foreground, 1.6)
                font.family: root.bar ? root.bar.fontFamily : Style.font.family
                font.pixelSize: Style.font.caption
                renderType: Text.NativeRendering
                anchors.verticalCenter: parent.verticalCenter
                width: Style.space(36)
                horizontalAlignment: Text.AlignRight
              }
            }

            MouseArea {
              id: queueHover
              anchors.fill: parent
              hoverEnabled: true
              enabled: !!(queueRow.item && queueRow.item.trackId)
              cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
              onClicked: {
                if (queueRow.item && queueRow.item.trackId && root.playerWidget) {
                  root.playerWidget.goToTrack(queueRow.item.trackId)
                }
              }
            }
          }
        }
      }

      // Multi-source player selector View
      Column {
        id: sourceList
        visible: (root.activeTab === "sources" || !root.hasUpcomingQueue) && root.sourcePlayers.length > 1
        width: parent.width
        spacing: Style.space(4)

        Repeater {
          model: root.sourcePlayers

          BorderSurface {
            id: sourceRow
            required property var modelData

            readonly property var player: modelData
            readonly property bool selected: root.activePlayer && player
              && MediaModel.keyFor(root.activePlayer) === MediaModel.keyFor(player)
            readonly property string sourceTitle: player ? (MediaModel.cleanTitle(player.trackTitle) || player.identity || player.desktopEntry || "Media source") : "Media source"
            readonly property string sourceDetail: player && player.trackArtist ? MediaModel.normalizeArtist(player.trackArtist) : (player && player.identity ? player.identity : "")

            width: sourceList.width
            height: sourceInner.implicitHeight + Style.space(8)
            radius: 0
            color: selected ? Style.selectedFillFor(root.bar ? root.bar.foreground : Color.foreground, Color.accent) : (sourceHover.containsMouse ? Style.hoverFillFor(root.bar ? root.bar.foreground : Color.foreground, Color.accent) : "transparent")
            borderSpec: selected ? Border.controlSpec("normal", root.bar ? root.bar.foreground : Color.foreground, Color.accent) : Border.none()

            Row {
              id: sourceInner
              anchors.left: parent.left
              anchors.right: parent.right
              anchors.verticalCenter: parent.verticalCenter
              anchors.leftMargin: sourceRow.borderLeft + Style.space(8)
              anchors.rightMargin: sourceRow.borderRight + Style.space(8)
              spacing: Style.space(8)

              Text {
                textFormat: Text.PlainText
                text: sourceRow.player && sourceRow.player.isPlaying ? "󰏤" : "󰐊"
                color: root.bar ? root.bar.foreground : Color.foreground
                font.family: root.bar ? root.bar.fontFamily : Style.font.family
                font.pixelSize: Style.font.body
                width: Style.space(16)
                renderType: Text.NativeRendering
                horizontalAlignment: Text.AlignHCenter
                anchors.verticalCenter: parent.verticalCenter
              }

              Column {
                width: parent.width - Style.space(24)
                spacing: Style.space(1)
                anchors.verticalCenter: parent.verticalCenter

                Text {
                  textFormat: Text.PlainText
                  text: sourceRow.sourceTitle
                  color: root.bar ? root.bar.foreground : Color.foreground
                  font.family: root.bar ? root.bar.fontFamily : Style.font.family
                  font.pixelSize: Style.font.bodySmall
                  font.bold: sourceRow.selected
                  renderType: Text.NativeRendering
                  elide: Text.ElideRight
                  width: parent.width
                }

                Text {
                  textFormat: Text.PlainText
                  text: sourceRow.sourceDetail
                  color: Qt.darker(root.bar ? root.bar.foreground : Color.foreground, 1.5)
                  font.family: root.bar ? root.bar.fontFamily : Style.font.family
                  font.pixelSize: Style.font.caption
                  renderType: Text.NativeRendering
                  elide: Text.ElideRight
                  width: parent.width
                  visible: text !== ""
                }
              }
            }

            MouseArea {
              id: sourceHover
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: if (root.playerWidget) root.playerWidget.selectPlayer(MediaModel.keyFor(sourceRow.player))
            }
          }
        }
      }
    }
  }
}

