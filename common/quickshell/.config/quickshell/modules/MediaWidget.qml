import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Mpris
import qs

// MPRIS: now playing. Click = popup, middle = play/pause, scroll = next/prev.
BarModule {
    id: root

    property real maxTextWidth: 200
    readonly property var players: Mpris.players.values
    readonly property var player: players.find(p => p.isPlaying) ?? players[0] ?? null

    function fmt(seconds) {
        if (!isFinite(seconds) || seconds < 0) return "0:00";
        const s = Math.floor(seconds);
        return `${Math.floor(s / 60)}:${String(s % 60).padStart(2, "0")}`;
    }

    visible: player !== null
    onClicked: m => {
        if (m.button === Qt.MiddleButton) player.togglePlaying();
        else popup.toggle();
    }
    onScrolled: step => step > 0 ? player.previous() : player.next()

    BarText {
        text: root.player && root.player.isPlaying ? Icons.music : Icons.pause
        color: Theme.green
        font.pixelSize: 14
    }
    BarText {
        visible: root.maxTextWidth >= 40
        text: root.player ? [root.player.trackTitle, root.player.trackArtist].filter(s => s).join(" — ") : ""
        elide: Text.ElideRight
        Layout.maximumWidth: root.maxTextWidth
    }

    BarPopup {
        id: popup
        anchorItem: root

        // MPRIS position is not pushed by players; poll it while visible.
        Timer {
            running: popup.visible && root.player !== null && root.player.isPlaying
            interval: 1000
            repeat: true
            onTriggered: root.player.positionChanged()
        }

        RowLayout {
            spacing: 12

            ClippingRectangle {
                Layout.preferredWidth: 110
                Layout.preferredHeight: 110
                radius: Theme.radius
                color: Theme.bg2

                Image {
                    anchors.fill: parent
                    source: root.player ? root.player.trackArtUrl : ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                }
            }

            ColumnLayout {
                Layout.preferredWidth: 260
                spacing: 4

                BarText {
                    Layout.fillWidth: true
                    text: root.player ? root.player.trackTitle : ""
                    font.bold: true
                    font.pixelSize: 14
                    elide: Text.ElideRight
                }
                BarText {
                    Layout.fillWidth: true
                    text: root.player ? root.player.trackArtist : ""
                    elide: Text.ElideRight
                }
                BarText {
                    Layout.fillWidth: true
                    text: root.player ? root.player.trackAlbum : ""
                    color: Theme.dim
                    elide: Text.ElideRight
                }

                ThemedSlider {
                    Layout.topMargin: 6
                    value: root.player && root.player.length > 0 ? root.player.position / root.player.length : 0
                    fill: Theme.green
                    interactive: root.player !== null && root.player.canSeek
                    onMoved: v => root.player.position = v * root.player.length
                }
                RowLayout {
                    BarText {
                        text: root.player ? root.fmt(root.player.position) : ""
                        color: Theme.dim
                        font.pixelSize: 10
                    }
                    Item { Layout.fillWidth: true }
                    BarText {
                        text: root.player ? root.fmt(root.player.length) : ""
                        color: Theme.dim
                        font.pixelSize: 10
                    }
                }

                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 4

                    MenuRow {
                        Layout.fillWidth: false
                        icon: Icons.prev
                        onClicked: root.player.previous()
                    }
                    MenuRow {
                        Layout.fillWidth: false
                        icon: root.player && root.player.isPlaying ? Icons.pause : Icons.play
                        iconColor: Theme.green
                        onClicked: root.player.togglePlaying()
                    }
                    MenuRow {
                        Layout.fillWidth: false
                        icon: Icons.next
                        onClicked: root.player.next()
                    }
                }
            }
        }

        // Every MPRIS player on the bus; click one to raise it.
        SectionLabel {
            text: "Players"
            visible: root.players.length > 1
        }
        Repeater {
            model: root.players.length > 1 ? root.players : []

            MenuRow {
                required property var modelData
                icon: modelData.isPlaying ? Icons.play : Icons.pause
                text: modelData.identity
                detail: modelData.trackTitle
                active: modelData === root.player
                onClicked: if (modelData.canRaise) modelData.raise()
            }
        }
    }
}
