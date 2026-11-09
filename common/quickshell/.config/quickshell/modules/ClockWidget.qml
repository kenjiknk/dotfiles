import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs

// Clock; click for a calendar (scroll or arrows change month).
BarModule {
    id: root

    onClicked: {
        popup.month = clock.date.getMonth();
        popup.year = clock.date.getFullYear();
        popup.toggle();
    }

    SystemClock {
        id: clock
        precision: popup.visible ? SystemClock.Seconds : SystemClock.Minutes
    }

    BarText {
        text: Qt.formatDateTime(clock.date, "ddd dd MMM  HH:mm")
        font.bold: true
    }

    BarPopup {
        id: popup

        property int month: 0
        property int year: 2026

        function shift(delta) {
            const d = new Date(year, month + delta, 1);
            month = d.getMonth();
            year = d.getFullYear();
        }

        anchorItem: root

        BarText {
            Layout.alignment: Qt.AlignHCenter
            text: Qt.formatDateTime(clock.date, "HH:mm:ss")
            font.pixelSize: 30
            font.bold: true
            color: Theme.accent
        }
        BarText {
            Layout.alignment: Qt.AlignHCenter
            text: Qt.formatDateTime(clock.date, "dddd, d MMMM yyyy")
            color: Theme.dim
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 6

            MenuRow {
                Layout.fillWidth: false
                icon: Icons.chevronLeft
                onClicked: popup.shift(-1)
            }
            BarText {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: Qt.formatDate(new Date(popup.year, popup.month, 1), "MMMM yyyy")
                font.bold: true
            }
            MenuRow {
                Layout.fillWidth: false
                icon: Icons.chevronRight
                onClicked: popup.shift(1)
            }
        }

        DayOfWeekRow {
            Layout.fillWidth: true
            locale: grid.locale
            delegate: BarText {
                required property string shortName
                text: shortName
                horizontalAlignment: Text.AlignHCenter
                color: Theme.muted
                font.pixelSize: 11
            }
        }

        MonthGrid {
            id: grid

            Layout.fillWidth: true
            Layout.preferredWidth: 252
            month: popup.month
            year: popup.year
            spacing: 2

            delegate: Rectangle {
                required property var model
                readonly property bool today: model.today

                implicitWidth: 34
                implicitHeight: 26
                radius: 4
                color: today ? Theme.accent : "transparent"

                BarText {
                    anchors.centerIn: parent
                    text: parent.model.day
                    color: parent.today ? Theme.bg
                         : parent.model.month === grid.month ? Theme.fg : Theme.muted
                    font.bold: parent.today
                }
            }

            WheelHandler {
                onWheel: e => popup.shift(e.angleDelta.y > 0 ? -1 : 1)
            }
        }
    }
}
