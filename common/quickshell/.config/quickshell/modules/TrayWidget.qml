import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.SystemTray
import qs

// Tray drawer: the bar shows a chevron and how many apps sit in the tray;
// click it for the list. Items asking for attention stay on the bar as icons.
// In the list: left = activate, middle = secondary action, right (or menu-only
// items) = the app's menu.
BarModule {
    id: root

    readonly property var items: SystemTray.items.values
    readonly property var urgent: items.filter(i => i.status === Status.NeedsAttention)

    function nameOf(item) {
        return item.tooltipTitle || item.title || item.id || "Unknown";
    }

    // Activate, secondary-activate or open the menu, as the tray convention goes.
    function use(item, button, menu) {
        if (button === Qt.MiddleButton) {
            item.secondaryActivate();
        } else if ((button === Qt.RightButton || item.onlyMenu) && item.hasMenu) {
            menu.open();
            return; // keep the drawer while the menu is up
        } else {
            item.activate();
        }
        popup.close();
    }

    visible: items.length > 0
    spacing: 4
    onClicked: popup.toggle()

    // Apps that need attention, always visible.
    Repeater {
        model: root.urgent

        IconImage {
            required property var modelData
            implicitSize: 16
            source: modelData.icon
        }
    }

    BarText {
        text: Icons.chevronDown
        color: Theme.dim
        font.pixelSize: 14
        rotation: popup.open ? 180 : 0
        Behavior on rotation { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
    }
    BarText {
        text: root.items.length
        color: Theme.dim
    }

    BarPopup {
        id: popup
        anchorItem: root

        SectionLabel {
            Layout.topMargin: 0
            Layout.preferredWidth: 240
            text: "Running in the background"
        }

        Repeater {
            model: root.items

            Rectangle {
                id: row

                required property var modelData

                Layout.fillWidth: true
                implicitWidth: rowLayout.implicitWidth + 16
                implicitHeight: 32
                radius: 4
                color: mouse.containsMouse ? Theme.bg2 : "transparent"

                RowLayout {
                    id: rowLayout
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    spacing: 10

                    IconImage {
                        implicitSize: 18
                        source: row.modelData.icon
                    }
                    BarText {
                        Layout.fillWidth: true
                        text: root.nameOf(row.modelData)
                        elide: Text.ElideRight
                    }
                    // Status dot when the app asks for attention.
                    Rectangle {
                        visible: row.modelData.status === Status.NeedsAttention
                        implicitWidth: 6
                        implicitHeight: 6
                        radius: 3
                        color: Theme.accent
                    }
                    BarText {
                        visible: row.modelData.hasMenu
                        text: Icons.chevronRight
                        color: Theme.muted
                    }
                }

                QsMenuAnchor {
                    id: menu
                    menu: row.modelData.menu
                    anchor.item: row
                    anchor.edges: Edges.Right
                    anchor.gravity: Edges.Right
                    onClosed: popup.close()
                }

                MouseArea {
                    id: mouse
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                    onClicked: m => root.use(row.modelData, m.button, menu)
                    onWheel: w => row.modelData.scroll(w.angleDelta.y, false)
                }
            }
        }
    }
}
