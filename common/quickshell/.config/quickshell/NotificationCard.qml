import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications

// One notification: icon/image, summary, app, body, action buttons, close.
//
// As a toast it hides after its timeout (Notifs runs it; paused while
// hovered) and stays in the history. Clicks follow the old dunst setup:
// left = close (the toast), middle = the default action, right = close every
// toast.
// In the history list: left = the default action (if the app has one),
// × or right = remove.
Rectangle {
    id: root

    required property var notification
    property bool toast: false

    function close() {
        if (toast) Notifs.markSeen(notification.id);
        else notification.dismiss();
    }

    // Invoking an action already closes a non-resident notification (and
    // destroys this object), so nothing may touch it afterwards.
    function runDefault() {
        const action = Notifs.defaultAction(notification);
        if (!action) return;
        if (toast) Notifs.markSeen(notification.id);
        action.invoke();
    }

    implicitWidth: 340
    implicitHeight: layout.implicitHeight + 20
    radius: Theme.radius
    color: Theme.bg
    border.width: 1
    border.color: notification.urgency === NotificationUrgency.Critical ? Theme.red : Theme.surface

    // The timeout itself lives in Notifs (one timer per notification); a toast
    // only tells it when the pointer rests on it.
    Binding {
        when: root.toast && mouse.containsMouse
        target: Notifs
        property: "hoveredId"
        value: root.notification.id
        restoreMode: Binding.RestoreValue
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
        onClicked: m => {
            if (root.toast) {
                if (m.button === Qt.MiddleButton) root.runDefault();
                else if (m.button === Qt.RightButton) Notifs.markAllSeen();
                else root.close();
            } else {
                if (m.button === Qt.RightButton) root.close();
                else root.runDefault();
            }
        }
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
                spacing: 6

                BarText {
                    Layout.fillWidth: true
                    text: root.notification.summary
                    font.bold: true
                    color: root.notification.urgency === NotificationUrgency.Critical ? Theme.red : Theme.fg
                    elide: Text.ElideRight
                }
                BarText {
                    text: root.notification.appName
                    color: Theme.muted
                    font.pixelSize: 10
                }
                // ×: hide the toast, or remove it from the history.
                BarText {
                    text: Icons.close
                    color: closeArea.containsMouse ? Theme.fg : Theme.muted

                    MouseArea {
                        id: closeArea
                        anchors.fill: parent
                        anchors.margins: -4
                        hoverEnabled: true
                        onClicked: root.close()
                    }
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

            // Named actions; "default" is the click itself, not a button.
            RowLayout {
                readonly property var buttons: root.notification.actions.filter(a => a.identifier !== "default" && a.text !== "")
                visible: buttons.length > 0
                Layout.topMargin: 4
                spacing: 4

                Repeater {
                    model: parent.buttons

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
