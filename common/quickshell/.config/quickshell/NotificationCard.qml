import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications

// One notification: icon/image, summary, body, action buttons.
// As a toast it hides itself after the timeout; click dismisses.
Rectangle {
    id: root

    required property var notification
    property bool toast: false

    implicitWidth: 340
    implicitHeight: layout.implicitHeight + 20
    radius: Theme.radius
    color: Theme.bg
    border.width: 1
    border.color: notification.urgency === NotificationUrgency.Critical ? Theme.red : Theme.surface

    Timer {
        running: root.toast && Notifs.timeoutMs(root.notification) > 0 && !hover.containsMouse
        interval: Notifs.timeoutMs(root.notification)
        onTriggered: Notifs.markSeen(root.notification.id)
    }

    MouseArea {
        id: hover
        anchors.fill: parent
        hoverEnabled: true
        onClicked: root.notification.dismiss()
    }

    RowLayout {
        id: layout
        x: 10
        y: 10
        width: parent.width - 20
        spacing: 10

        IconImage {
            Layout.alignment: Qt.AlignTop
            implicitSize: 36
            visible: source != ""
            source: root.notification.image
                || (root.notification.appIcon ? Quickshell.iconPath(root.notification.appIcon, true) : "")
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 3

            RowLayout {
                Layout.fillWidth: true

                BarText {
                    Layout.fillWidth: true
                    text: root.notification.summary
                    font.bold: true
                    elide: Text.ElideRight
                }
                BarText {
                    text: root.notification.appName
                    color: Theme.muted
                    font.pixelSize: 10
                }
            }

            BarText {
                Layout.fillWidth: true
                visible: text !== ""
                text: root.notification.body
                textFormat: Text.StyledText
                wrapMode: Text.Wrap
                maximumLineCount: 5
                elide: Text.ElideRight
                color: Theme.dim
                onLinkActivated: link => Qt.openUrlExternally(link)
            }

            RowLayout {
                visible: root.notification.actions.length > 0
                Layout.topMargin: 4
                spacing: 4

                Repeater {
                    model: root.notification.actions

                    MenuRow {
                        required property var modelData
                        Layout.fillWidth: false
                        color: Theme.bg2
                        text: modelData.text
                        onClicked: modelData.invoke()
                    }
                }
            }
        }
    }
}
