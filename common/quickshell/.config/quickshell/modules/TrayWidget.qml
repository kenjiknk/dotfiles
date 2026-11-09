import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.SystemTray
import qs

// StatusNotifierItem tray. Left = activate, middle = secondary,
// right (or menu-only items) = DBus menu opened below the bar.
BarModule {
    id: root

    hoverable: false
    padding: 4
    visible: SystemTray.items.values.length > 0

    Repeater {
        model: SystemTray.items.values

        Item {
            id: item

            required property var modelData

            Layout.preferredWidth: 22
            Layout.preferredHeight: Theme.barHeight

            Rectangle {
                anchors.centerIn: parent
                width: 22
                height: 20
                radius: 4
                color: mouse.containsMouse ? Theme.bg2 : "transparent"
            }

            IconImage {
                anchors.centerIn: parent
                implicitSize: 16
                source: item.modelData.icon
            }

            QsMenuAnchor {
                id: menu
                menu: item.modelData.menu
                anchor.item: item
                anchor.edges: Edges.Bottom
                anchor.gravity: Edges.Bottom
            }

            MouseArea {
                id: mouse
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                onClicked: m => {
                    const it = item.modelData;
                    if (ShellState.activePopup) ShellState.activePopup.close();
                    if (m.button === Qt.MiddleButton) it.secondaryActivate();
                    else if ((m.button === Qt.RightButton || it.onlyMenu) && it.hasMenu) menu.open();
                    else it.activate();
                }
                onWheel: w => item.modelData.scroll(w.angleDelta.y, false)
            }
        }
    }
}
