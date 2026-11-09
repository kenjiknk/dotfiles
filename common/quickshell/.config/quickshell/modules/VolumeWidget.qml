import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Pipewire
import qs

// PipeWire mixer. Scroll = volume, right = mute, middle = wiremix, click = popup with
// output/input sliders, peak meter, device picker and per-app volume.
BarModule {
    id: root

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource
    readonly property real volume: sink && sink.audio ? sink.audio.volume : 0
    readonly property bool muted: sink && sink.audio ? sink.audio.muted : false

    function nodeName(n) {
        return n.properties["application.name"] || n.description || n.nickname || n.name;
    }

    PwObjectTracker { objects: [root.sink, root.source] }

    onScrolled: step => {
        if (!sink || !sink.audio) return;
        sink.audio.muted = false;
        sink.audio.volume = Math.max(0, Math.min(1.5, volume + step * 0.05));
    }
    onClicked: m => {
        if (m.button === Qt.LeftButton) popup.toggle();
        else if (m.button === Qt.MiddleButton) Quickshell.execDetached(["kitty", "-e", "wiremix"]);
        else if (sink && sink.audio) sink.audio.muted = !sink.audio.muted;
    }

    BarText {
        text: Icons.volume(root.volume, root.muted)
        color: root.muted ? Theme.muted : Theme.yellow
        font.pixelSize: 14
    }
    BarText {
        text: root.muted ? "mute" : `${Math.round(root.volume * 100)}%`
        color: root.muted ? Theme.muted : Theme.fg
    }

    BarPopup {
        id: popup
        anchorItem: root

        PwNodeLinkTracker {
            id: links
            node: root.sink
        }

        readonly property var streams: links.linkGroups.map(g => g.source).filter(n => n && n.isStream)
        readonly property var sinks: Pipewire.nodes.values.filter(n => n.isSink && !n.isStream && n.audio)

        PwObjectTracker { objects: popup.streams }

        PwNodePeakMonitor {
            id: peak
            node: root.sink
            enabled: popup.visible
        }

        SectionLabel {
            Layout.topMargin: 0
            text: "Output — " + (root.sink ? root.nodeName(root.sink) : "none")
        }
        RowLayout {
            Layout.preferredWidth: 320

            BarText {
                text: Icons.volume(root.volume, root.muted)
                color: root.muted ? Theme.muted : Theme.yellow
                font.pixelSize: 14
                MouseArea { anchors.fill: parent; onClicked: root.sink.audio.muted = !root.muted }
            }
            ThemedSlider {
                value: root.volume
                fill: root.muted ? Theme.muted : Theme.yellow
                onMoved: v => { root.sink.audio.muted = false; root.sink.audio.volume = v; }
            }
            BarText {
                text: `${Math.round(root.volume * 100)}%`
                Layout.preferredWidth: 36
                horizontalAlignment: Text.AlignRight
            }
        }

        // Live peak meter from PwNodePeakMonitor.
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 4
            radius: 2
            color: Theme.bg2

            Rectangle {
                width: parent.width * Math.min(1, peak.peak)
                height: parent.height
                radius: 2
                color: peak.peak > 0.9 ? Theme.red : Theme.green
                Behavior on width { NumberAnimation { duration: 60 } }
            }
        }

        SectionLabel { text: "Input — " + (root.source ? root.nodeName(root.source) : "none") }
        RowLayout {
            visible: root.source !== null && root.source.audio !== null
            Layout.fillWidth: true

            BarText {
                readonly property bool micMuted: root.source && root.source.audio ? root.source.audio.muted : true
                text: micMuted ? Icons.micOff : Icons.mic
                color: micMuted ? Theme.muted : Theme.aqua
                font.pixelSize: 14
                MouseArea { anchors.fill: parent; onClicked: root.source.audio.muted = !root.source.audio.muted }
            }
            ThemedSlider {
                value: root.source && root.source.audio ? root.source.audio.volume : 0
                fill: Theme.aqua
                onMoved: v => root.source.audio.volume = v
            }
            BarText {
                text: root.source && root.source.audio ? `${Math.round(root.source.audio.volume * 100)}%` : ""
                Layout.preferredWidth: 36
                horizontalAlignment: Text.AlignRight
            }
        }

        SectionLabel { text: "Devices" }
        Repeater {
            model: popup.sinks

            MenuRow {
                required property var modelData
                icon: Icons.speaker
                text: modelData.description || modelData.name
                active: modelData === root.sink
                onClicked: Pipewire.preferredDefaultAudioSink = modelData
            }
        }

        SectionLabel {
            text: "Applications"
            visible: popup.streams.length > 0
        }
        Repeater {
            model: popup.streams

            RowLayout {
                required property var modelData
                Layout.fillWidth: true

                IconImage {
                    implicitSize: 16
                    source: Quickshell.iconPath(modelData.properties["application.icon-name"] || "", "audio-x-generic")
                }
                BarText {
                    text: root.nodeName(modelData)
                    elide: Text.ElideRight
                    Layout.preferredWidth: 90
                }
                ThemedSlider {
                    value: modelData.audio ? modelData.audio.volume : 0
                    fill: Theme.orange
                    onMoved: v => modelData.audio.volume = v
                }
                BarText {
                    text: modelData.audio ? `${Math.round(modelData.audio.volume * 100)}%` : ""
                    Layout.preferredWidth: 36
                    horizontalAlignment: Text.AlignRight
                }
            }
        }
    }
}
