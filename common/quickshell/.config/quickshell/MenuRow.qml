import QtQuick
import QtQuick.Layouts

// Clickable row inside popups: icon, label and an optional right-hand detail.
Rectangle {
    id: root

    property string icon: ""
    property color iconColor: Theme.fg
    property string text: ""
    property color textColor: Theme.fg
    property string detail: ""
    property bool active: false
    property int maxTextWidth: 240
    property int maxDetailWidth: 160

    signal clicked(var mouse)

    Layout.fillWidth: true
    implicitWidth: row.implicitWidth + 16
    implicitHeight: 28
    radius: 4
    color: active ? Theme.surface : mouse.containsMouse ? Theme.bg2 : "transparent"

    RowLayout {
        id: row
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        spacing: 8

        BarText {
            visible: root.icon !== ""
            text: root.icon
            color: root.iconColor
            font.pixelSize: 14
            Layout.preferredWidth: 16
        }
        // Long labels (a browser tab as a media player, an SSID) are cut with
        // "…" instead of stretching the whole popup to their full length.
        BarText {
            text: root.text
            color: root.textColor
            elide: Text.ElideRight
            Layout.fillWidth: true
            Layout.maximumWidth: root.maxTextWidth
        }
        BarText {
            visible: root.detail !== ""
            text: root.detail
            color: Theme.dim
            font.pixelSize: 11
            elide: Text.ElideRight
            Layout.maximumWidth: root.maxDetailWidth
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: m => root.clicked(m)
    }
}
