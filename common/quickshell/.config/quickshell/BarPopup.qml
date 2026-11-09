import QtQuick
import QtQuick.Layouts
import Quickshell

// Popup panel below a bar widget. It is not a window of its own: the panel is
// drawn in its bar's popup layer (one transparent window per bar, see Bar.qml),
// so opening and closing are plain Qt animations. No window gets mapped or
// resized, and picom has nothing to animate. One popup is open at a time;
// clicking anywhere outside it closes it. Children go into a ColumnLayout.
QtObject {
    id: popup

    required property Item anchorItem
    default property alias content: body.data
    property int padding: 12
    property bool open: false
    // true from the start of the fade-in to the end of the fade-out
    readonly property bool visible: panel.opacity > 0
    property real centerX: 0

    // The bar's popup layer, found up the widget's parent chain.
    readonly property Item layer: {
        for (let p = anchorItem; p; p = p.parent)
            if (p.popupLayer !== undefined) return p.popupLayer;
        return null;
    }

    function toggle() { open = !open; }
    function close() { open = false; }

    onOpenChanged: {
        if (open) {
            if (ShellState.activePopup && ShellState.activePopup !== popup)
                ShellState.activePopup.close();
            ShellState.activePopup = popup;
            centerX = anchorItem.mapToItem(null, anchorItem.width / 2, 0).x;
        } else if (ShellState.activePopup === popup) {
            ShellState.activePopup = null;
        }
    }

    readonly property Item panelItem: Rectangle {
        id: panel

        parent: popup.layer
        // Hidden by opacity only: a visible: false item is not laid out, so the
        // panel would open at the size its content had last time, then jump.
        enabled: opacity > 0
        x: parent ? Math.max(6, Math.min(parent.width - width - 6, popup.centerX - width / 2)) : 0
        y: popup.open ? 6 : -6
        opacity: popup.open ? 1 : 0
        implicitWidth: body.implicitWidth + popup.padding * 2
        implicitHeight: body.implicitHeight + popup.padding * 2
        width: implicitWidth
        height: implicitHeight
        color: Theme.bg
        border.color: Theme.surface
        border.width: 1
        radius: Theme.radius

        Behavior on opacity { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
        Behavior on y { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

        // Clicks on the panel itself must not reach the layer's close handler.
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
        }

        ColumnLayout {
            id: body
            x: popup.padding
            y: popup.padding
            width: parent.width - popup.padding * 2
            spacing: 8
        }
    }
}
