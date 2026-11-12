import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import "../theme"
import "../services"
import "../components"

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
        color: ShellState.glassEnabled ? "transparent" : Theme.bgModal
        border.color: ShellState.glassEnabled ? "transparent" : Theme.borderGlow
        border.width: ShellState.glassEnabled ? 0 : 1

        LiquidGlassSurface {
            radius: Theme.cardRadius
            visible: ShellState.glassEnabled
            accentColor: Theme.accentCyan
            showShadow: true
        }
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
                color: ShellState.glassEnabled ? "transparent" : Theme.bgBase
                border.color: ShellState.glassEnabled ? "transparent" : (searchInput.activeFocus ? Theme.accentCyan : Theme.borderDim)
                border.width: ShellState.glassEnabled ? 0 : 1

                LiquidGlassSurface {
                    radius: 12
                    visible: ShellState.glassEnabled
                    accentColor: searchInput.activeFocus ? Theme.accentCyan : Theme.borderDim
                    showShadow: false
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16
                    spacing: 10

                    Icon {
                        name: "search"
                        size: 16
                        color: Theme.accentCyan
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
                                Quickshell.execDetached(["laya-cmd", searchInput.text.trim()]);
                                ShellState.launcherOpen = false;
                            }
                        }

                        Keys.onEscapePressed: {
                            ShellState.launcherOpen = false;
                        }
                    }

                    Text {
                        text: (launcherWindow.filteredApps.length > 0) ? (launcherWindow.filteredApps.length + " apps") : (searchInput.text.trim().length > 0 ? "command mode" : "0 apps")
                        font.family: Theme.fontMono
                        font.pixelSize: 11
                        color: (launcherWindow.filteredApps.length === 0 && searchInput.text.trim().length > 0) ? Theme.accentCyan : Theme.textMuted
                    }
                }
            }

            // Results List
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 10
                color: ShellState.plasticEnabled ? "transparent" : Theme.bgBase
                border.color: ShellState.plasticEnabled ? "transparent" : Theme.borderDim
                border.width: ShellState.plasticEnabled ? 0 : 1
                clip: true

                LiquidGlassSurface {
                    radius: 10
                    visible: ShellState.plasticEnabled
                    accentColor: Theme.borderDim
                    showShadow: false
                }

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
                        readonly property bool isSelected: appList.currentIndex === appItem.index
                        readonly property bool isHovered: itemMouse.containsMouse

                        color: ShellState.plasticEnabled
                            ? "transparent"
                            : ((isSelected || isHovered) ? Theme.bgHover : "transparent")
                        border.color: ShellState.plasticEnabled
                            ? "transparent"
                            : (isSelected ? Theme.accentCyan : "transparent")
                        border.width: isSelected ? 1 : 0

                        LiquidGlassSurface {
                            radius: 8
                            visible: ShellState.plasticEnabled && (appItem.isSelected || appItem.isHovered)
                            accentColor: Theme.accentCyan
                            hovered: appItem.isHovered
                            pressed: itemMouse.pressed
                            showShadow: false
                        }

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
                                color: ShellState.plasticEnabled ? "transparent" : Theme.bgCard

                                LiquidGlassSurface {
                                    radius: 8
                                    visible: ShellState.plasticEnabled
                                    accentColor: Theme.accentViolet
                                    showShadow: false
                                }

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

                // Empty state or Natural Language Command Card
                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 12
                    visible: launcherWindow.filteredApps.length === 0
                    width: Math.min(parent.width - 40, 480)

                    Rectangle {
                        Layout.fillWidth: true
                        height: 64
                        radius: 10
                        color: Theme.bgCard
                        border.color: Theme.accentCyan
                        border.width: 1
                        visible: searchInput.text.trim().length > 0

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 12

                            Icon {
                                name: "zap"
                                size: 22
                                color: Theme.accentAmber
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                Text {
                                    text: "Execute Semantic Command"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 13
                                    font.bold: true
                                    color: Theme.accentCyan
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: '"' + searchInput.text.trim() + '"'
                                    font.family: Theme.fontMono
                                    font.pixelSize: 11
                                    color: Theme.textPrimary
                                    elide: Text.ElideRight
                                }
                            }

                            Rectangle {
                                width: 28
                                height: 28
                                radius: 6
                                color: Theme.bgHover
                                Text {
                                    anchors.centerIn: parent
                                    text: "↵"
                                    font.bold: true
                                    color: Theme.accentCyan
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                Quickshell.execDetached(["laya-cmd", searchInput.text.trim()]);
                                ShellState.launcherOpen = false;
                            }
                        }
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: searchInput.text.trim().length > 0 ? "Press Enter to run with Antigravity Engine" : "No applications found"
                        font.family: Theme.fontFamily
                        font.pixelSize: 12
                        color: Theme.textMuted
                    }
                }
            }
        }
    }
}
