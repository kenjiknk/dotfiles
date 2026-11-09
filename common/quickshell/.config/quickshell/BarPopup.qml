import QtQuick
import QtQuick.Layouts
import Quickshell

// Popup that opens below a bar widget. Children go into a ColumnLayout.
PopupWindow {
    id: popup

    required property Item anchorItem
    default property alias content: body.data
    property int padding: 12

    function toggle() { visible = !visible; }

    anchor.item: anchorItem
    anchor.edges: Edges.Bottom
    anchor.gravity: Edges.Bottom
    anchor.adjustment: PopupAdjustment.Slide
    grabFocus: true
    color: "transparent"
    implicitWidth: frame.implicitWidth
    implicitHeight: frame.implicitHeight + 6

    Rectangle {
        id: frame
        y: 6
        width: parent.width
        height: implicitHeight
        implicitWidth: body.implicitWidth + popup.padding * 2
        implicitHeight: body.implicitHeight + popup.padding * 2
        color: Theme.bg
        border.color: Theme.surface
        border.width: 1
        radius: Theme.radius

        ColumnLayout {
            id: body
            x: popup.padding
            y: popup.padding
            width: parent.width - popup.padding * 2
            spacing: 8
        }
    }
}
