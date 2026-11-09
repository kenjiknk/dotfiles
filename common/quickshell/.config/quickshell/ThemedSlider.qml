import QtQuick
import QtQuick.Layouts

// 0..1 slider; emits moved() while dragging, clicking or scrolling.
Item {
    id: root

    property real value: 0
    property color fill: Theme.accent
    property bool interactive: true

    signal moved(real value)

    Layout.fillWidth: true
    implicitWidth: 200
    implicitHeight: 16

    function clamp(v) { return Math.max(0, Math.min(1, v)); }

    Rectangle {
        id: track
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: 6
        radius: 3
        color: Theme.bg2

        Rectangle {
            width: parent.width * root.clamp(root.value)
            height: parent.height
            radius: 3
            color: root.fill
            Behavior on width { enabled: !drag.pressed; NumberAnimation { duration: 80 } }
        }
    }

    Rectangle {
        visible: root.interactive
        x: track.width * root.clamp(root.value) - width / 2
        anchors.verticalCenter: parent.verticalCenter
        width: 12
        height: 12
        radius: 6
        color: Theme.fg
    }

    MouseArea {
        id: drag
        enabled: root.interactive
        anchors.fill: parent
        preventStealing: true
        onPressed: m => root.moved(root.clamp(m.x / width))
        onPositionChanged: m => { if (pressed) root.moved(root.clamp(m.x / width)); }
        onWheel: w => root.moved(root.clamp(root.value + (w.angleDelta.y > 0 ? 0.05 : -0.05)))
    }
}
