import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import "../theme"
import "../services"

PanelWindow {
    id: launcherWindow

    visible: ShellState.launcherOpen
    color: "transparent"

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "quickshell:launcher"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: ShellState.launcherOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    property var filteredApps: AppService.search(searchInput.text)

    onVisibleChanged: {
        if (visible) {
            searchInput.text = "";
            appList.currentIndex = 0;
            Qt.callLater(() => {
                searchInput.forceActiveFocus();
            });
        }
    }

    // Backdrop click
    MouseArea {
        anchors.fill: parent
        onClicked: ShellState.launcherOpen = false

        Rectangle {
            anchors.fill: parent
            color: "#000000"
            opacity: 0.70
        }
    }

    // Modal Card
    Rectangle {
        id: card
        width: 620
        height: 520
        anchors.centerIn: parent
        radius: Theme.cardRadius
        color: Theme.bgModal
        border.color: Theme.borderGlow
        border.width: 1
        Keys.forwardTo: [searchInput]

        MouseArea {
            anchors.fill: parent
            onClicked: {}
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 14

            // Search Header
            Rectangle {
                Layout.fillWidth: true
                height: 48
                radius: 12
                color: Theme.bgBase
                border.color: searchInput.activeFocus ? Theme.accentCyan : Theme.borderDim
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16
                    spacing: 10

                    Text {
                        text: "🔍"
                        font.pixelSize: 14
                    }

                    TextInput {
                        id: searchInput
                        Layout.fillWidth: true
                        font.family: Theme.fontFamily
                        font.pixelSize: 14
                        color: Theme.textPrimary
                        clip: true
                        focus: true

                        Text {
                            text: "Search applications or run command..."
                            font.family: Theme.fontFamily
                            font.pixelSize: 14
                            color: Theme.textMuted
                            visible: !searchInput.text && !searchInput.activeFocus
                        }

                        onTextChanged: {
                            appList.currentIndex = 0;
                        }

                        Keys.onPressed: event => {
                            if (event.key === Qt.Key_Down) {
                                if (appList.count > 0) {
                                    appList.currentIndex = (appList.currentIndex + 1) % appList.count;
                                    appList.positionViewAtIndex(appList.currentIndex, ListView.Contain);
                                    event.accepted = true;
                                }
                            } else if (event.key === Qt.Key_Up) {
                                if (appList.count > 0) {
                                    appList.currentIndex = (appList.currentIndex - 1 + appList.count) % appList.count;
                                    appList.positionViewAtIndex(appList.currentIndex, ListView.Contain);
                                    event.accepted = true;
                                }
                            } else if (event.key === Qt.Key_PageDown) {
                                if (appList.count > 0) {
                                    appList.currentIndex = Math.min(appList.count - 1, appList.currentIndex + 5);
                                    appList.positionViewAtIndex(appList.currentIndex, ListView.Contain);
                                    event.accepted = true;
                                }
                            } else if (event.key === Qt.Key_PageUp) {
                                if (appList.count > 0) {
                                    appList.currentIndex = Math.max(0, appList.currentIndex - 5);
                                    appList.positionViewAtIndex(appList.currentIndex, ListView.Contain);
                                    event.accepted = true;
                                }
                            }
                        }

                        onAccepted: {
                            if (launcherWindow.filteredApps && launcherWindow.filteredApps.length > 0) {
                                const idx = Math.max(0, Math.min(appList.currentIndex, launcherWindow.filteredApps.length - 1));
                                launcherWindow.filteredApps[idx].execute();
                                ShellState.launcherOpen = false;
                            } else if (searchInput.text.trim().length > 0) {
                                Quickshell.execDetached(["bash", "-c", searchInput.text.trim()]);
                                ShellState.launcherOpen = false;
                            }
                        }

                        Keys.onEscapePressed: {
                            ShellState.launcherOpen = false;
                        }
                    }

                    Text {
                        text: launcherWindow.filteredApps.length + " apps"
                        font.family: Theme.fontMono
                        font.pixelSize: 11
                        color: Theme.textMuted
                    }
                }
            }

            // Results List
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 10
                color: Theme.bgBase
                border.color: Theme.borderDim
                border.width: 1
                clip: true

                ListView {
                    id: appList
                    anchors.fill: parent
                    anchors.margins: 6
                    model: launcherWindow.filteredApps
                    spacing: 4
                    currentIndex: 0
                    keyNavigationEnabled: false
                    Keys.forwardTo: [searchInput]
                    boundsBehavior: Flickable.StopAtBounds

                    ScrollBar.vertical: ScrollBar {
                        active: true
                        policy: ScrollBar.AsNeeded
                    }

                    delegate: Rectangle {
                        id: appItem
                        required property var modelData
                        required property int index

                        width: appList.width - 12
                        height: 52
                        radius: 8
                        color: (appList.currentIndex === appItem.index || itemMouse.containsMouse) ? Theme.bgHover : "transparent"
                        border.color: (appList.currentIndex === appItem.index) ? Theme.accentCyan : "transparent"
                        border.width: (appList.currentIndex === appItem.index) ? 1 : 0

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 12

                            // App Icon
                            Rectangle {
                                width: 36
                                height: 36
                                radius: 8
                                color: Theme.bgCard

                                Image {
                                    id: appIcon
                                    anchors.centerIn: parent
                                    width: 28
                                    height: 28
                                    sourceSize.width: 28
                                    sourceSize.height: 28
                                    fillMode: Image.PreserveAspectFit
                                    source: Quickshell.iconPath(appItem.modelData.icon) || ""
                                    asynchronous: true
                                }

                                // Fallback letter badge if icon not loaded
                                Text {
                                    anchors.centerIn: parent
                                    text: (appItem.modelData.name || "A").charAt(0).toUpperCase()
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 14
                                    font.bold: true
                                    color: Theme.accentViolet
                                    visible: appIcon.status !== Image.Ready
                                }
                            }

                            // App Title and Description
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                Text {
                                    text: appItem.modelData.name || ""
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 13
                                    font.bold: true
                                    color: (appList.currentIndex === appItem.index) ? Theme.accentCyan : Theme.textPrimary
                                    elide: Text.ElideRight
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: appItem.modelData.comment || appItem.modelData.execString || ""
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 10
                                    color: Theme.textMuted
                                    elide: Text.ElideRight
                                    visible: text.length > 0
                                }
                            }

                            // Launch indicator on selection or hover
                            Text {
                                text: "↵"
                                font.pixelSize: 14
                                color: Theme.accentCyan
                                visible: appList.currentIndex === appItem.index || itemMouse.containsMouse
                            }
                        }

                        MouseArea {
                            id: itemMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: {
                                appList.currentIndex = appItem.index;
                            }
                            onClicked: {
                                appItem.modelData.execute();
                                ShellState.launcherOpen = false;
                            }
                        }
                    }
                }

                // Empty state
                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 8
                    visible: launcherWindow.filteredApps.length === 0

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "No applications found"
                        font.family: Theme.fontFamily
                        font.pixelSize: 13
                        color: Theme.textMuted
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "Press Enter to run as terminal command"
                        font.family: Theme.fontMono
                        font.pixelSize: 11
                        color: Theme.accentSky
                    }
                }
            }
        }
    }
}
