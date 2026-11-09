import QtQuick
import QtQuick.Layouts

// Base for every bar widget: hover highlight, click and (smoothed) scroll.
Item {
    id: root

    default property alias content: row.data
    property alias spacing: row.spacing
    property bool hoverable: true
    readonly property alias hovered: mouse.containsMouse
    property int padding: 8

    signal clicked(var mouse)
    signal scrolled(int step) // +1 = wheel up, -1 = wheel down

    implicitWidth: row.implicitWidth + padding * 2
    implicitHeight: Theme.barHeight
    Layout.fillHeight: true

    Rectangle {
        anchors.fill: parent
        anchors.topMargin: 3
        anchors.bottomMargin: 3
        radius: Theme.radius
        color: Theme.bg2
        opacity: root.hoverable && mouse.containsMouse ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 120 } }
    }

    MouseArea {
        id: mouse
        property int acc: 0
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onClicked: m => root.clicked(m)
        onWheel: w => {
            acc += w.angleDelta.y;
            while (acc >= 120) { acc -= 120; root.scrolled(1); }
            while (acc <= -120) { acc += 120; root.scrolled(-1); }
        }
    }

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 6
    }
}
