import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import "../theme"
import "../services"
import "../components"

PanelWindow {
    id: controlCenterWindow

    visible: ShellState.controlCenterOpen
    color: "transparent"

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "quickshell:controlcenter"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: ShellState.controlCenterOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    property string activeTab: "controls"

    // Backdrop click to close
    MouseArea {
        anchors.fill: parent
        onClicked: ShellState.controlCenterOpen = false

        Rectangle {
            anchors.fill: parent
            color: "#000000"
            opacity: 0.45
        }
    }

    // Dropdown Card anchored to top-right below the bar
    Rectangle {
        id: menuCard
        width: 380
        anchors.top: parent.top
        anchors.topMargin: 56
        anchors.right: parent.right
        anchors.rightMargin: 16
        height: Math.min(mainCol.implicitHeight + 36, controlCenterWindow.height - 76)
        radius: Theme.cardRadius
        clip: true
        color: Theme.bgModal
        border.color: Theme.borderGlow
        border.width: 1

        // Consume clicks inside
        MouseArea {
            anchors.fill: parent
            onClicked: {}
        }

        Flickable {
            id: mainFlickable
            anchors.fill: parent
            anchors.margins: 18
            contentWidth: width
            contentHeight: mainCol.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            ScrollBar.vertical: ScrollBar {
                active: mainFlickable.moving || mainFlickable.flicking
                policy: mainFlickable.contentHeight > mainFlickable.height ? ScrollBar.AsNeeded : ScrollBar.AlwaysOff
            }

            ColumnLayout {
                id: mainCol
                width: mainFlickable.width
                spacing: 16

            // Header Row
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Icon {
                    name: "sliders"
                    size: 13
                    color: Theme.accentCyan
                }

                Text {
                    text: "CONNECTIVITY & CONTROLS"
                    font.family: Theme.fontMono
                    font.pixelSize: 11
                    font.bold: true
                    color: Theme.accentCyan
                }
                Item { Layout.fillWidth: true }
                // Refresh button
                Rectangle {
                    width: 24
                    height: 24
                    radius: 12
                    color: refreshMouse.containsMouse ? Theme.bgHover : "transparent"

                    Icon {
                        anchors.centerIn: parent
                        name: "refresh-cw"
                        size: 12
                        color: refreshMouse.containsMouse ? Theme.accentCyan : Theme.textMuted
                    }

                    MouseArea {
                        id: refreshMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: NetworkService.refresh()
                    }
                }
            }

            // Segmented Tab Switcher (Controls vs Notifications)
            Rectangle {
                Layout.fillWidth: true
                height: 32
                radius: 8
                color: Theme.bgBase
                border.color: Theme.borderDim
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 3
                    spacing: 4

                    // Controls Tab
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 6
                        readonly property bool active: controlCenterWindow.activeTab === "controls"
                        color: active ? Theme.accentViolet : (ctrlTabM.containsMouse ? Theme.bgHover : "transparent")

                        Behavior on color { ColorAnimation { duration: 150 } }

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 6

                            Icon {
                                name: "sliders"
                                size: 12
                                color: parent.parent.active ? Theme.textOnAccent : Theme.textMuted
                            }

                            Text {
                                text: "Controls"
                                font.family: Theme.fontFamily
                                font.pixelSize: 11
                                font.bold: parent.parent.active
                                color: parent.parent.active ? Theme.textOnAccent : Theme.textPrimary
                            }
                        }

                        MouseArea {
                            id: ctrlTabM
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: controlCenterWindow.activeTab = "controls"
                        }
                    }

                    // Notifications Tab
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 6
                        readonly property bool active: controlCenterWindow.activeTab === "notifications"
                        color: active ? Theme.accentViolet : (notifTabM.containsMouse ? Theme.bgHover : "transparent")

                        Behavior on color { ColorAnimation { duration: 150 } }

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 6

                            Icon {
                                name: NotificationService.unreadCount > 0 ? "bell-ring" : "bell"
                                size: 12
                                color: parent.parent.active ? Theme.textOnAccent : (NotificationService.unreadCount > 0 ? Theme.accentRose : Theme.textMuted)
                            }

                            Text {
                                text: "Notifications" + (NotificationService.unreadCount > 0 ? " (" + NotificationService.unreadCount + ")" : "")
                                font.family: Theme.fontFamily
                                font.pixelSize: 11
                                font.bold: parent.parent.active
                                color: parent.parent.active ? Theme.textOnAccent : (NotificationService.unreadCount > 0 ? Theme.accentRose : Theme.textPrimary)
                            }
                        }

                        MouseArea {
                            id: notifTabM
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                controlCenterWindow.activeTab = "notifications";
                                NotificationService.markAllRead();
                            }
                        }
                    }
                }
            }

            // --- CONTROLS CONTENT WRAPPER ---
            ColumnLayout {
                id: controlsCol
                Layout.fillWidth: true
                spacing: 16
                visible: controlCenterWindow.activeTab === "controls"

                // Quick Toggle Tiles (Wi-Fi & Bluetooth)
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                // Wi-Fi Toggle Tile
                Rectangle {
                    Layout.fillWidth: true
                    height: 58
                    radius: 12
                    color: NetworkService.wifiEnabled ? Theme.bgCard : Theme.bgPill
                    border.color: NetworkService.wifiEnabled ? Theme.accentCyan : Theme.borderDim
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 10

                        Icon {
                            name: NetworkService.wifiEnabled ? "wifi" : "wifi-off"
                            size: 20
                            color: NetworkService.wifiEnabled ? Theme.accentCyan : Theme.textMuted
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            Text {
                                text: "Wi-Fi"
                                font.family: Theme.fontFamily
                                font.pixelSize: 12
                                font.bold: true
                                color: Theme.textPrimary
                            }
                            Text {
                                text: NetworkService.wifiEnabled ? (NetworkService.activeSsid ? NetworkService.activeSsid : "On") : "Disabled"
                                font.family: Theme.fontFamily
                                font.pixelSize: 10
                                color: Theme.textMuted
                                elide: Text.ElideRight
                                Layout.maximumWidth: 100
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: NetworkService.toggleWifi()
                    }
                }

                // Bluetooth Toggle Tile
                Rectangle {
                    Layout.fillWidth: true
                    height: 58
                    radius: 12
                    color: NetworkService.btPowered ? Theme.bgCard : Theme.bgPill
                    border.color: NetworkService.btPowered ? Theme.accentSky : Theme.borderDim
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 10

                        Icon {
                            name: NetworkService.btPowered ? "bluetooth" : "bluetooth-off"
                            size: 20
                            color: NetworkService.btPowered ? Theme.accentSky : Theme.textMuted
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            Text {
                                text: "Bluetooth"
                                font.family: Theme.fontFamily
                                font.pixelSize: 12
                                font.bold: true
                                color: Theme.textPrimary
                            }
                            Text {
                                text: NetworkService.btPowered ? "Enabled" : "Disabled"
                                font.family: Theme.fontFamily
                                font.pixelSize: 10
                                color: Theme.textMuted
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: NetworkService.toggleBluetooth()
                    }
                }
            }

            // Now Playing Media Player Card
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: mediaRow.implicitHeight + 24
                radius: 14
                color: Theme.bgCard
                border.color: MediaService.isPlaying ? Theme.accentViolet : Theme.borderDim
                border.width: 1
                visible: MediaService.hasMedia

                RowLayout {
                    id: mediaRow
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 12

                    // Album Art / Disc
                    Rectangle {
                        width: 72
                        height: 72
                        radius: 10
                        color: Theme.bgSurface
                        clip: true
                        border.color: Theme.borderDim
                        border.width: 1

                        Image {
                            anchors.fill: parent
                            source: MediaService.trackArtUrl
                            fillMode: Image.PreserveAspectCrop
                            visible: MediaService.trackArtUrl.length > 0
                        }

                        Icon {
                            anchors.centerIn: parent
                            name: "music"
                            size: 28
                            color: Theme.accentViolet
                            visible: MediaService.trackArtUrl.length === 0
                        }
                    }

                    // Metadata & Controls
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4

                        Text {
                            Layout.fillWidth: true
                            text: MediaService.trackTitle || "Not Playing"
                            font.family: Theme.fontFamily
                            font.pixelSize: 12
                            font.bold: true
                            color: Theme.textPrimary
                            elide: Text.ElideRight
                        }

                        Text {
                            Layout.fillWidth: true
                            text: MediaService.trackArtist || "Unknown Artist"
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                            color: Theme.textMuted
                            elide: Text.ElideRight
                        }

                        // Progress Bar & Time
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 6

                            Text {
                                text: MediaService.positionStr
                                font.family: Theme.fontMono
                                font.pixelSize: 9
                                color: Theme.textMuted
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                height: 4
                                radius: 2
                                color: Theme.bgSurface

                                Rectangle {
                                    width: parent.width * MediaService.progress
                                    height: parent.height
                                    radius: 2
                                    color: Theme.accentViolet
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: mouse => {
                                        MediaService.seekFraction(mouse.x / width);
                                    }
                                }
                            }

                            Text {
                                text: MediaService.lengthStr
                                font.family: Theme.fontMono
                                font.pixelSize: 9
                                color: Theme.textMuted
                            }
                        }

                        // Controls Row
                        RowLayout {
                            Layout.alignment: Qt.AlignHCenter
                            spacing: 16

                            Rectangle {
                                width: 28
                                height: 28
                                radius: 14
                                color: prevMediaM.containsMouse ? Theme.bgHover : "transparent"

                                Icon {
                                    anchors.centerIn: parent
                                    name: "skip-back"
                                    size: 14
                                    color: prevMediaM.containsMouse ? Theme.accentCyan : Theme.textMuted
                                }

                                MouseArea {
                                    id: prevMediaM
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: MediaService.previous()
                                }
                            }

                            Rectangle {
                                width: 32
                                height: 32
                                radius: 16
                                color: playMediaM.containsMouse ? Theme.accentCyan : Theme.accentViolet
                                Behavior on color { ColorAnimation { duration: 150 } }

                                Icon {
                                    anchors.centerIn: parent
                                    name: MediaService.isPlaying ? "pause" : "play"
                                    size: 14
                                    color: Theme.textOnAccent
                                }

                                MouseArea {
                                    id: playMediaM
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: MediaService.playPause()
                                }
                            }

                            Rectangle {
                                width: 28
                                height: 28
                                radius: 14
                                color: nextMediaM.containsMouse ? Theme.bgHover : "transparent"

                                Icon {
                                    anchors.centerIn: parent
                                    name: "skip-forward"
                                    size: 14
                                    color: nextMediaM.containsMouse ? Theme.accentCyan : Theme.textMuted
                                }

                                MouseArea {
                                    id: nextMediaM
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: MediaService.next()
                                }
                            }
                        }
                    }
                }
            }

            // TuneD Power & Performance Section
            Rectangle {
                Layout.fillWidth: true
                radius: 12
                color: Theme.bgCard
                border.color: Theme.borderDim
                border.width: 1
                visible: TunedService.available
                implicitHeight: tunedCol.implicitHeight + 20

                property bool showAllProfiles: false

                ColumnLayout {
                    id: tunedCol
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 8

                    // Header Row
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        Icon {
                            name: "gauge"
                            size: 12
                            color: TunedService.activeMeta.color || Theme.accentAmber
                        }

                        Text {
                            text: "TUNED PERFORMANCE PROFILES"
                            font.family: Theme.fontMono
                            font.pixelSize: 10
                            font.bold: true
                            color: Theme.textMuted
                        }

                        Item { Layout.fillWidth: true }

                        // Active Profile Badge Pill
                        Rectangle {
                            height: 20
                            implicitWidth: badgeRow.implicitWidth + 12
                            radius: 10
                            color: Qt.alpha(TunedService.activeMeta.color || Theme.accentAmber, 0.15)
                            border.color: TunedService.activeMeta.color || Theme.accentAmber
                            border.width: 1

                            RowLayout {
                                id: badgeRow
                                anchors.centerIn: parent
                                spacing: 4

                                Icon {
                                    name: TunedService.activeMeta.icon || "zap"
                                    size: 11
                                    color: TunedService.activeMeta.color || Theme.accentAmber
                                }

                                Text {
                                    text: TunedService.activeMeta.name || TunedService.activeProfile
                                    font.family: Theme.fontMono
                                    font.pixelSize: 9
                                    font.bold: true
                                    color: TunedService.activeMeta.color || Theme.accentAmber
                                }
                            }
                        }

                        // Toggle all profiles button
                        Rectangle {
                            width: 20
                            height: 20
                            radius: 10
                            color: moreMouse.containsMouse ? Theme.bgHover : "transparent"

                            Icon {
                                anchors.centerIn: parent
                                name: tunedCol.parent.showAllProfiles ? "chevron-up" : "chevron-down"
                                size: 12
                                color: moreMouse.containsMouse ? Theme.textPrimary : Theme.textMuted
                            }

                            MouseArea {
                                id: moreMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: tunedCol.parent.showAllProfiles = !tunedCol.parent.showAllProfiles
                            }
                        }
                    }

                    // Primary 4 Profile Quick Tiles Row
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        Repeater {
                            model: [
                                { id: "powersave", name: "Power", icon: "leaf", color: "#10B981" },
                                { id: "balanced", name: "Balanced", icon: "gauge", color: "#06B6D4" },
                                { id: "throughput-performance", name: "Performance", icon: "zap", color: "#F59E0B" },
                                { id: "latency-performance", name: "Low Latency", icon: "flame", color: "#EF4444" }
                            ]

                            delegate: Rectangle {
                                id: profTile
                                Layout.fillWidth: true
                                height: 50
                                radius: 8
                                readonly property bool isActive: TunedService.activeProfile === modelData.id
                                color: isActive ? Qt.alpha(modelData.color, 0.18) : (tileMouse.containsMouse ? Theme.bgHover : Theme.bgPill)
                                border.color: isActive ? modelData.color : (tileMouse.containsMouse ? Theme.borderGlow : Theme.borderDim)
                                border.width: isActive ? 1.5 : 1

                                Behavior on color { ColorAnimation { duration: 150 } }
                                Behavior on border.color { ColorAnimation { duration: 150 } }

                                ColumnLayout {
                                    anchors.centerIn: parent
                                    spacing: 3

                                    Icon {
                                        Layout.alignment: Qt.AlignHCenter
                                        name: modelData.icon
                                        size: 15
                                        color: profTile.isActive ? modelData.color : (tileMouse.containsMouse ? Theme.textPrimary : Theme.textSecondary)
                                    }

                                    Text {
                                        Layout.alignment: Qt.AlignHCenter
                                        text: modelData.name
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 10
                                        font.bold: profTile.isActive
                                        color: profTile.isActive ? Theme.textPrimary : Theme.textSecondary
                                    }
                                }

                                MouseArea {
                                    id: tileMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: TunedService.switchProfile(modelData.id)
                                }
                            }
                        }
                    }

                    // Active Profile Description Banner
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6
                        visible: !tunedCol.parent.showAllProfiles

                        Icon {
                            name: "sparkles"
                            size: 11
                            color: TunedService.activeMeta.color || Theme.accentAmber
                        }

                        Text {
                            Layout.fillWidth: true
                            text: TunedService.activeMeta.summary || TunedService.activeMeta.description || ""
                            font.family: Theme.fontMono
                            font.pixelSize: 9
                            color: Theme.textMuted
                            elide: Text.ElideRight
                        }
                    }

                    // Expanded All Profiles List (when showAllProfiles is true)
                    Rectangle {
                        Layout.fillWidth: true
                        height: 180
                        radius: 8
                        color: Theme.bgPill
                        border.color: Theme.borderDim
                        border.width: 1
                        clip: true
                        visible: tunedCol.parent.showAllProfiles

                        ListView {
                            id: tunedListView
                            anchors.fill: parent
                            anchors.margins: 4
                            spacing: 4
                            clip: true
                            boundsBehavior: Flickable.StopAtBounds
                            model: TunedService.profiles

                            ScrollBar.vertical: ScrollBar {
                                active: tunedListView.moving || tunedListView.flicking
                                policy: ScrollBar.AsNeeded
                            }

                            delegate: Rectangle {
                                width: tunedListView.width - 8
                                height: 32
                                radius: 6
                                readonly property bool isSelected: TunedService.activeProfile === modelData.id
                                color: isSelected ? Qt.alpha(modelData.color || Theme.accentCyan, 0.15) : (rowMouse.containsMouse ? Theme.bgHover : "transparent")
                                border.color: isSelected ? (modelData.color || Theme.accentCyan) : "transparent"
                                border.width: 1

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 8
                                    anchors.rightMargin: 8
                                    spacing: 8

                                    Icon {
                                        name: modelData.icon || "sliders"
                                        size: 13
                                        color: modelData.color || Theme.textMuted
                                    }

                                    Text {
                                        text: modelData.name || modelData.id
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 10
                                        font.bold: isSelected
                                        color: isSelected ? Theme.textPrimary : Theme.textSecondary
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: modelData.summary || modelData.description || ""
                                        font.family: Theme.fontMono
                                        font.pixelSize: 8
                                        color: Theme.textMuted
                                        elide: Text.ElideRight
                                    }

                                    Icon {
                                        name: "check"
                                        size: 11
                                        color: modelData.color || Theme.accentEmerald
                                        visible: isSelected
                                    }
                                }

                                MouseArea {
                                    id: rowMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: TunedService.switchProfile(modelData.id)
                                }
                            }
                        }
                    }
                }
            }

            // Theme Switcher Section
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Icon {
                        name: "palette"
                        size: 12
                        color: Theme.textMuted
                    }

                    Text {
                        text: "THEME PALETTE"
                        font.family: Theme.fontMono
                        font.pixelSize: 10
                        font.bold: true
                        color: Theme.textMuted
                    }
                    Item { Layout.fillWidth: true }
                    // Auto-cycle toggle button
                    Rectangle {
                        height: 22
                        implicitWidth: cycleRow.implicitWidth + 12
                        radius: 6
                        color: Theme.autoCycle ? Theme.accentViolet : Theme.bgPill
                        border.color: Theme.autoCycle ? Theme.accentViolet : Theme.borderDim
                        border.width: 1

                        RowLayout {
                            id: cycleRow
                            anchors.centerIn: parent
                            spacing: 4

                            Icon {
                                name: "refresh-cw"
                                size: 10
                                color: Theme.autoCycle ? Theme.textOnAccent : Theme.accentViolet
                            }

                            Text {
                                text: Theme.autoCycle ? "10s Cycle: ON" : "10s Cycle: OFF"
                                font.family: Theme.fontMono
                                font.pixelSize: 9
                                font.bold: true
                                color: Theme.autoCycle ? Theme.textOnAccent : Theme.textMuted
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Theme.autoCycle = !Theme.autoCycle
                        }
                    }
                }

                // Theme Chips Grid (2 columns x 3 rows)
                GridLayout {
                    Layout.fillWidth: true
                    columns: 2
                    columnSpacing: 6
                    rowSpacing: 6

                    Repeater {
                        model: Theme.themeKeys

                        Rectangle {
                            Layout.fillWidth: true
                            height: 32
                            radius: 8
                            readonly property bool isSelected: Theme.currentThemeKey === modelData
                            readonly property var pal: Theme.palettes[modelData]

                            color: isSelected ? Theme.bgCard : (chipMouse.containsMouse ? Theme.bgHover : Theme.bgPill)
                            border.color: isSelected ? pal.accentViolet : Theme.borderDim
                            border.width: isSelected ? 1.5 : 1

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                anchors.rightMargin: 8
                                spacing: 8

                                // Color preview dots
                                Row {
                                    spacing: 3
                                    Rectangle {
                                        width: 8
                                        height: 8
                                        radius: 4
                                        color: pal.accentViolet
                                    }
                                    Rectangle {
                                        width: 8
                                        height: 8
                                        radius: 4
                                        color: pal.accentSky
                                    }
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: pal.name
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 10
                                    font.bold: isSelected
                                    color: isSelected ? pal.accentViolet : Theme.textPrimary
                                    elide: Text.ElideRight
                                }

                                Icon {
                                    visible: isSelected
                                    name: "check"
                                    size: 11
                                    color: pal.accentViolet
                                }
                            }

                            MouseArea {
                                id: chipMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    Theme.setTheme(modelData);
                                }
                            }
                        }
                    }
                }
            }

            // Wallpaper Controller Section
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Icon {
                        name: "image"
                        size: 12
                        color: Theme.textMuted
                    }

                    Text {
                        text: "WALLPAPER"
                        font.family: Theme.fontMono
                        font.pixelSize: 10
                        font.bold: true
                        color: Theme.textMuted
                    }
                    Item { Layout.fillWidth: true }

                    // Previous Wallpaper
                    Rectangle {
                        width: 22
                        height: 22
                        radius: 6
                        color: wpPrevMouse.containsMouse ? Theme.bgHover : Theme.bgPill
                        border.color: Theme.borderDim
                        border.width: 1

                        Icon {
                            anchors.centerIn: parent
                            name: "chevron-left"
                            size: 12
                            color: Theme.accentViolet
                        }

                        MouseArea {
                            id: wpPrevMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: WallpaperService.prevWallpaper()
                        }
                    }

                    // Next Wallpaper
                    Rectangle {
                        width: 22
                        height: 22
                        radius: 6
                        color: wpNextMouse.containsMouse ? Theme.bgHover : Theme.bgPill
                        border.color: Theme.borderDim
                        border.width: 1

                        Icon {
                            anchors.centerIn: parent
                            name: "chevron-right"
                            size: 12
                            color: Theme.accentViolet
                        }

                        MouseArea {
                            id: wpNextMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: WallpaperService.nextWallpaper()
                        }
                    }
                }

                // Mode Selector Bar (Theme, Custom, Gradient)
                Rectangle {
                    Layout.fillWidth: true
                    height: 30
                    radius: 8
                    color: Theme.bgPill
                    border.color: Theme.borderDim
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 3
                        spacing: 3

                        // Theme Matched Mode
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: 6
                            readonly property bool active: WallpaperService.mode === "theme"
                            color: active ? Theme.accentViolet : (modeThemeM.containsMouse ? Theme.bgHover : "transparent")

                            Text {
                                anchors.centerIn: parent
                                text: "Theme Match"
                                font.family: Theme.fontFamily
                                font.pixelSize: 10
                                font.bold: parent.active
                                color: parent.active ? Theme.textOnAccent : Theme.textMuted
                            }

                            MouseArea {
                                id: modeThemeM
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: WallpaperService.setMode("theme")
                            }
                        }

                        // Custom / Manual Mode
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: 6
                            readonly property bool active: WallpaperService.mode === "manual"
                            color: active ? Theme.accentViolet : (modeManM.containsMouse ? Theme.bgHover : "transparent")

                            Text {
                                anchors.centerIn: parent
                                text: "Wallpapers (" + WallpaperService.wallpapers.length + ")"
                                font.family: Theme.fontFamily
                                font.pixelSize: 10
                                font.bold: parent.active
                                color: parent.active ? Theme.textOnAccent : Theme.textMuted
                            }

                            MouseArea {
                                id: modeManM
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (WallpaperService.manualWallpaper.length === 0 && WallpaperService.wallpapers.length > 0) {
                                        WallpaperService.nextWallpaper();
                                    } else {
                                        WallpaperService.setMode("manual");
                                    }
                                }
                            }
                        }

                        // Gradient Mode
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: 6
                            readonly property bool active: WallpaperService.mode === "gradient"
                            color: active ? Theme.accentViolet : (modeGradM.containsMouse ? Theme.bgHover : "transparent")

                            Text {
                                anchors.centerIn: parent
                                text: "Gradient"
                                font.family: Theme.fontFamily
                                font.pixelSize: 10
                                font.bold: parent.active
                                color: parent.active ? Theme.textOnAccent : Theme.textMuted
                            }

                            MouseArea {
                                id: modeGradM
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: WallpaperService.setMode("gradient")
                            }
                        }
                    }
                }

                // Current Wallpaper Info Pill
                Rectangle {
                    Layout.fillWidth: true
                    height: 26
                    radius: 6
                    color: Theme.bgCard
                    border.color: Theme.borderDim
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        spacing: 6

                        Icon {
                            name: "image"
                            size: 11
                            color: Theme.accentViolet
                        }

                        Text {
                            Layout.fillWidth: true
                            text: WallpaperService.currentFileName
                            font.family: Theme.fontMono
                            font.pixelSize: 9
                            color: Theme.textSecondary
                            elide: Text.ElideMiddle
                        }
                    }
                }
            }

            // Wi-Fi Section
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Icon {
                        name: "wifi"
                        size: 12
                        color: Theme.textMuted
                    }

                    Text {
                        text: "AVAILABLE WI-FI NETWORKS"
                        font.family: Theme.fontMono
                        font.pixelSize: 10
                        font.bold: true
                        color: Theme.textMuted
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: NetworkService.networks.length + " found"
                        font.family: Theme.fontMono
                        font.pixelSize: 10
                        color: Theme.accentCyan
                    }
                }

                // Networks Scroll List
                Rectangle {
                    Layout.fillWidth: true
                    height: 150
                    radius: 10
                    color: Theme.bgPill
                    border.color: Theme.borderDim
                    border.width: 1
                    clip: true

                    ListView {
                        id: wifiListView
                        anchors.fill: parent
                        anchors.margins: 6
                        spacing: 4
                        model: NetworkService.networks

                        ScrollBar.vertical: ScrollBar {
                            active: true
                            policy: ScrollBar.AsNeeded
                        }

                        delegate: Rectangle {
                            width: wifiListView.width - 12
                            height: 34
                            radius: 6
                            color: modelData.inUse ? Theme.bgCard : (netMouse.containsMouse ? Theme.bgHover : "transparent")
                            border.color: modelData.inUse ? Theme.accentCyan : "transparent"
                            border.width: 1

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                anchors.rightMargin: 8
                                spacing: 8

                                Icon {
                                    name: modelData.inUse ? "check" : (modelData.security.includes("WPA") ? "lock" : "globe")
                                    size: 12
                                    color: modelData.inUse ? Theme.accentCyan : Theme.textMuted
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.ssid
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 11
                                    font.bold: modelData.inUse
                                    color: modelData.inUse ? Theme.accentCyan : Theme.textPrimary
                                    elide: Text.ElideRight
                                }

                                Text {
                                    text: modelData.signal + "%"
                                    font.family: Theme.fontMono
                                    font.pixelSize: 10
                                    color: Theme.textMuted
                                }
                            }

                            MouseArea {
                                id: netMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (!modelData.inUse) {
                                        NetworkService.connectWifi(modelData.ssid);
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Bluetooth Section
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Icon {
                        name: "bluetooth"
                        size: 12
                        color: Theme.textMuted
                    }

                    Text {
                        text: "BLUETOOTH DEVICES"
                        font.family: Theme.fontMono
                        font.pixelSize: 10
                        font.bold: true
                        color: Theme.textMuted
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: NetworkService.btDevices.length + " paired"
                        font.family: Theme.fontMono
                        font.pixelSize: 10
                        color: Theme.accentSky
                    }
                }

                // Devices List
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    Repeater {
                        model: NetworkService.btDevices
                        Rectangle {
                            Layout.fillWidth: true
                            height: 36
                            radius: 8
                            color: modelData.connected ? Theme.bgCard : (devMouse.containsMouse ? Theme.bgHover : Theme.bgPill)
                            border.color: modelData.connected ? Theme.accentSky : Theme.borderDim
                            border.width: 1

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 10
                                spacing: 8

                                Icon {
                                    name: {
                                        const lower = (modelData.name || "").toLowerCase();
                                        if (lower.includes("bud") || lower.includes("headphone") || lower.includes("ear") || lower.includes("airpod")) {
                                            return "headphones";
                                        } else if (lower.includes("soundbar") || lower.includes("speaker") || lower.includes("audio")) {
                                            return "speaker";
                                        } else if (lower.includes("phone") || lower.includes("pixel") || lower.includes("iphone") || lower.includes("galaxy")) {
                                            return "smartphone";
                                        }
                                        return modelData.connected ? "headphones" : "bluetooth";
                                    }
                                    size: 13
                                    color: modelData.connected ? Theme.accentSky : Theme.textMuted
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.name
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 11
                                    color: modelData.connected ? Theme.accentSky : Theme.textPrimary
                                    elide: Text.ElideRight
                                }

                                Rectangle {
                                    width: 64
                                    height: 22
                                    radius: 11
                                    color: modelData.connected ? Theme.accentRose : Theme.bgHover

                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData.connected ? "Disconnect" : "Connect"
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 9
                                        font.bold: true
                                        color: modelData.connected ? Theme.textOnAccent : Theme.textSecondary
                                    }
                                }
                            }

                            MouseArea {
                                id: devMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    NetworkService.toggleBtDevice(modelData.mac, modelData.connected);
                                }
                            }
                        }
                    }
                }
            }
            } // Close controlsCol

            // --- NOTIFICATIONS CONTENT WRAPPER ---
            ColumnLayout {
                id: notificationsCol
                Layout.fillWidth: true
                spacing: 12
                visible: controlCenterWindow.activeTab === "notifications"

                // Subheader & Actions
                RowLayout {
                    Layout.fillWidth: true

                    // DND Toggle Pill
                    Rectangle {
                        height: 26
                        implicitWidth: dndRow.implicitWidth + 12
                        radius: 13
                        color: NotificationService.dnd ? Theme.accentRose : Theme.bgPill
                        border.color: NotificationService.dnd ? Theme.accentRose : Theme.borderDim
                        border.width: 1

                        RowLayout {
                            id: dndRow
                            anchors.centerIn: parent
                            spacing: 5

                            Icon {
                                name: NotificationService.dnd ? "bell-off" : "bell"
                                size: 11
                                color: NotificationService.dnd ? Theme.textOnAccent : Theme.textMuted
                            }

                            Text {
                                text: NotificationService.dnd ? "Do Not Disturb: ON" : "DND: OFF"
                                font.family: Theme.fontMono
                                font.pixelSize: 9
                                font.bold: true
                                color: NotificationService.dnd ? Theme.textOnAccent : Theme.textMuted
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: NotificationService.toggleDnd()
                        }
                    }

                    Item { Layout.fillWidth: true }

                    // Clear All Button
                    Rectangle {
                        height: 24
                        implicitWidth: clearNotifsRow.implicitWidth + 12
                        radius: 6
                        color: clearNotifsMouse.containsMouse ? Theme.accentRose : Theme.bgPill
                        border.color: Theme.borderDim
                        border.width: 1
                        visible: NotificationService.history.length > 0

                        RowLayout {
                            id: clearNotifsRow
                            anchors.centerIn: parent
                            spacing: 4

                            Icon {
                                name: "trash-2"
                                size: 11
                                color: clearNotifsMouse.containsMouse ? "#FFFFFF" : Theme.accentRose
                            }

                            Text {
                                text: "Clear All"
                                font.family: Theme.fontFamily
                                font.pixelSize: 9
                                color: clearNotifsMouse.containsMouse ? "#FFFFFF" : Theme.textMuted
                            }
                        }

                        MouseArea {
                            id: clearNotifsMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: NotificationService.clearAll()
                        }
                    }
                }

                // Notification History List
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    visible: NotificationService.history.length > 0

                    Repeater {
                        model: NotificationService.history

                        delegate: Rectangle {
                            Layout.fillWidth: true
                            radius: 10
                            color: Theme.bgCard
                            border.color: Theme.borderDim
                            border.width: 1
                            implicitHeight: notifHistCol.implicitHeight + 16

                            ColumnLayout {
                                id: notifHistCol
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 4

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 6

                                    Icon {
                                        name: modelData.urgency === 2 ? "alert-circle" : "bell"
                                        size: 12
                                        color: modelData.urgency === 2 ? Theme.accentRose : Theme.accentSky
                                    }

                                    Text {
                                        text: modelData.appName
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 10
                                        font.bold: true
                                        color: Theme.accentSky
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }

                                    Text {
                                        text: modelData.time
                                        font.family: Theme.fontMono
                                        font.pixelSize: 9
                                        color: Theme.textMuted
                                    }

                                    // Dismiss button
                                    Rectangle {
                                        width: 16
                                        height: 16
                                        radius: 8
                                        color: disMouse.containsMouse ? Theme.bgHover : "transparent"

                                        Icon {
                                            anchors.centerIn: parent
                                            name: "x"
                                            size: 9
                                            color: disMouse.containsMouse ? Theme.accentRose : Theme.textMuted
                                        }

                                        MouseArea {
                                            id: disMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: NotificationService.dismissHistory(modelData.id)
                                        }
                                    }
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.summary
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 11
                                    font.bold: true
                                    color: Theme.textPrimary
                                    wrapMode: Text.Wrap
                                    elide: Text.ElideRight
                                    maximumLineCount: 2
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.body
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 10
                                    color: Theme.textSecondary
                                    wrapMode: Text.Wrap
                                    elide: Text.ElideRight
                                    maximumLineCount: 3
                                    visible: modelData.body && modelData.body.length > 0
                                }
                            }
                        }
                    }
                }

                // Empty State
                Rectangle {
                    Layout.fillWidth: true
                    height: 120
                    radius: 10
                    color: Theme.bgCard
                    border.color: Theme.borderDim
                    border.width: 1
                    visible: NotificationService.history.length === 0

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 8

                        Icon {
                            Layout.alignment: Qt.AlignHCenter
                            name: "bell"
                            size: 26
                            color: Theme.accentViolet
                        }

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "All caught up"
                            font.family: Theme.fontFamily
                            font.pixelSize: 12
                            font.bold: true
                            color: Theme.textPrimary
                        }

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "No new notifications"
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                            color: Theme.textMuted
                        }
                    }
                }
            }
        }
        }
    }
}
