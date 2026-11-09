import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets

// App launcher over DesktopEntries. A normal X11 window; the i3 config floats
// and centers it (for_window [title="^qs-launcher$"]).
// Toggle: click the bar icon or `qs ipc call launcher toggle`.
FloatingWindow {
    id: win

    readonly property var results: {
        const q = search.text.toLowerCase().trim();
        const apps = DesktopEntries.applications.values.filter(a => !a.noDisplay);
        if (q === "")
            return apps.slice().sort((a, b) => a.name.localeCompare(b.name));
        const score = a => {
            const name = a.name.toLowerCase();
            if (name.startsWith(q)) return 0;
            if (name.includes(q)) return 1;
            if ((a.genericName || "").toLowerCase().includes(q)) return 2;
            if (Array.from(a.keywords || []).some(k => k.toLowerCase().includes(q))) return 3;
            if ((a.comment || "").toLowerCase().includes(q)) return 4;
            return -1;
        };
        return apps.map(a => ({ a, s: score(a) }))
            .filter(x => x.s >= 0)
            .sort((x, y) => x.s - y.s || x.a.name.localeCompare(y.a.name))
            .map(x => x.a);
    }

    function launch(app) {
        if (!app) return;
        ShellState.launcherOpen = false;
        app.execute();
    }

    title: "qs-launcher"
    visible: false
    implicitWidth: 560
    implicitHeight: 440
    color: Theme.bg

    Connections {
        target: ShellState
        function onLauncherOpenChanged() { win.visible = ShellState.launcherOpen; }
    }

    onVisibleChanged: {
        if (visible) {
            search.text = "";
            list.currentIndex = 0;
            search.forceActiveFocus();
        } else {
            ShellState.launcherOpen = false;
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.bg
        border.color: Theme.accent
        border.width: 1

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 8

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 36
                radius: Theme.radius
                color: Theme.bg2

                TextInput {
                    id: search

                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    verticalAlignment: TextInput.AlignVCenter
                    color: Theme.fg
                    selectionColor: Theme.accent
                    font.family: Theme.font
                    font.pixelSize: 14
                    focus: true
                    onTextChanged: list.currentIndex = 0

                    Keys.onEscapePressed: ShellState.launcherOpen = false
                    Keys.onReturnPressed: win.launch(win.results[list.currentIndex])
                    Keys.onEnterPressed: win.launch(win.results[list.currentIndex])
                    Keys.onDownPressed: list.incrementCurrentIndex()
                    Keys.onUpPressed: list.decrementCurrentIndex()
                    Keys.onTabPressed: list.incrementCurrentIndex()

                    BarText {
                        visible: search.text === ""
                        text: "Search applications…"
                        color: Theme.muted
                        font.pixelSize: 14
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }

            ListView {
                id: list

                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                model: win.results
                highlightMoveDuration: 80
                highlight: Rectangle {
                    radius: Theme.radius
                    color: Theme.surface
                }

                delegate: Item {
                    id: entry

                    required property var modelData
                    required property int index

                    width: ListView.view.width
                    height: 44

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 12

                        IconImage {
                            implicitSize: 28
                            source: Quickshell.iconPath(entry.modelData.icon, "application-x-executable")
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0

                            BarText {
                                Layout.fillWidth: true
                                text: entry.modelData.name
                                font.bold: true
                                elide: Text.ElideRight
                            }
                            BarText {
                                Layout.fillWidth: true
                                visible: text !== ""
                                text: entry.modelData.comment || entry.modelData.genericName || ""
                                color: Theme.dim
                                font.pixelSize: 11
                                elide: Text.ElideRight
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: list.currentIndex = entry.index
                        onClicked: win.launch(entry.modelData)
                    }
                }
            }

            BarText {
                text: `${win.results.length} apps  ·  ↑↓ select  ·  Enter launch  ·  Esc close`
                color: Theme.muted
                font.pixelSize: 10
            }
        }
    }
}
