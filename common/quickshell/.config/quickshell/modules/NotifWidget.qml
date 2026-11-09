import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs

// Notification history (only when Notifs.enabled). Right-click = do not disturb.
BarModule {
    id: root

    visible: Notifs.enabled
    onClicked: m => {
        if (m.button === Qt.RightButton) Notifs.dnd = !Notifs.dnd;
        else popup.toggle();
    }

    BarText {
        text: Notifs.dnd ? Icons.bellOff : Icons.bell
        color: Notifs.list.length > 0 ? Theme.accent : Theme.dim
        font.pixelSize: 14
    }
    BarText {
        visible: Notifs.list.length > 0
        text: Notifs.list.length
    }

    BarPopup {
        id: popup
        anchorItem: root

        RowLayout {
            Layout.preferredWidth: 340

            SectionLabel {
                Layout.fillWidth: true
                Layout.topMargin: 0
                text: Notifs.dnd ? "Notifications — do not disturb" : "Notifications"
            }
            MenuRow {
                Layout.fillWidth: false
                visible: Notifs.list.length > 0
                text: "clear all"
                textColor: Theme.red
                onClicked: Notifs.clearAll()
            }
        }

        BarText {
            visible: Notifs.list.length === 0
            text: "Nothing here"
            color: Theme.muted
        }

        ScrollView {
            visible: Notifs.list.length > 0
            Layout.preferredWidth: 340
            Layout.preferredHeight: Math.min(480, cards.implicitHeight)
            clip: true

            ColumnLayout {
                id: cards
                width: 340
                spacing: 6

                Repeater {
                    model: Notifs.list.slice().reverse()

                    NotificationCard {
                        required property var modelData
                        notification: modelData
                        color: Theme.bg1
                    }
                }
            }
        }
    }
}
