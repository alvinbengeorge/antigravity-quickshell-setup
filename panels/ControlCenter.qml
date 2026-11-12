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
    onVisibleChanged: {
        if (visible) {
            mainFlickable.contentY = 0;
        }
    }

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
        color: ShellState.glassEnabled ? "transparent" : Theme.bgModal
        border.color: ShellState.glassEnabled ? "transparent" : Theme.borderGlow
        border.width: ShellState.glassEnabled ? 0 : 1

        LiquidGlassSurface {
            radius: Theme.cardRadius
            visible: ShellState.glassEnabled
            accentColor: Theme.accentCyan
            showShadow: true
        }

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

            Connections {
                target: ShellState
                function onControlCenterOpenChanged() {
                    if (ShellState.controlCenterOpen) {
                        mainFlickable.contentY = 0;
                    }
                }
            }

            Connections {
                target: NetworkService
                function onWifiDrawerOpenChanged() {
                    mainFlickable.contentY = 0;
                }
                function onBtDrawerOpenChanged() {
                    mainFlickable.contentY = 0;
                }
            }

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

                // Quick Toggle Tiles (Wi-Fi & Bluetooth Split Tiles)
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    // Wi-Fi Split Master Tile
                    Rectangle {
                        Layout.fillWidth: true
                        height: 58
                        radius: 12
                        color: ShellState.glassEnabled ? "transparent" : (NetworkService.wifiEnabled ? Theme.bgCard : Theme.bgPill)
                        border.color: ShellState.glassEnabled ? "transparent" : (NetworkService.wifiEnabled ? Theme.accentCyan : Theme.borderDim)
                        border.width: ShellState.glassEnabled ? 0 : 1

                        LiquidGlassSurface {
                            radius: 12
                            visible: ShellState.glassEnabled
                            accentColor: NetworkService.wifiEnabled ? Theme.accentCyan : Theme.textMuted
                            hovered: wifiCardMouse.containsMouse || wifiRadioMouse.containsMouse
                            showShadow: true
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            anchors.topMargin: 8
                            anchors.bottomMargin: 8
                            spacing: 8

                            // Left Button: Dedicated Wi-Fi Radio Toggle
                            Rectangle {
                                width: 34
                                height: 34
                                radius: 9
                                color: NetworkService.wifiEnabled
                                    ? Qt.rgba(Theme.accentCyan.r, Theme.accentCyan.g, Theme.accentCyan.b, 0.22)
                                    : (wifiRadioMouse.containsMouse ? Theme.bgHover : Theme.bgBase)
                                border.color: NetworkService.wifiEnabled ? Theme.accentCyan : Theme.borderDim
                                border.width: 1

                                Icon {
                                    anchors.centerIn: parent
                                    name: NetworkService.wifiEnabled ? "wifi" : "wifi-off"
                                    size: 16
                                    color: NetworkService.wifiEnabled ? Theme.accentCyan : Theme.textMuted
                                }

                                MouseArea {
                                    id: wifiRadioMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: NetworkService.toggleWifi()
                                }
                            }

                            // Middle Info: SSID & Status
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                RowLayout {
                                    spacing: 4
                                    Text {
                                        text: "Wi-Fi"
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 11
                                        font.bold: true
                                        color: Theme.textPrimary
                                    }
                                    Rectangle {
                                        visible: NetworkService.wifiEnabled && NetworkService.activeWifi.freq.length > 0
                                        height: 14
                                        width: freqTxt.implicitWidth + 6
                                        radius: 4
                                        color: Qt.rgba(Theme.accentCyan.r, Theme.accentCyan.g, Theme.accentCyan.b, 0.18)
                                        Text {
                                            id: freqTxt
                                            anchors.centerIn: parent
                                            text: NetworkService.activeWifi.freq.includes("5") ? "5G" : "2.4G"
                                            font.family: Theme.fontMono
                                            font.pixelSize: 8
                                            font.bold: true
                                            color: Theme.accentCyan
                                        }
                                    }
                                }

                                Text {
                                    text: NetworkService.wifiEnabled
                                        ? (NetworkService.activeSsid ? NetworkService.activeSsid : "Available")
                                        : "Disabled"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 10
                                    color: NetworkService.wifiEnabled && NetworkService.activeSsid ? Theme.accentCyan : Theme.textMuted
                                    elide: Text.ElideRight
                                    Layout.maximumWidth: 70
                                }
                            }

                            // Right Button: Expand / Collapse Chevron
                            Rectangle {
                                width: 22
                                height: 22
                                radius: 6
                                color: wifiCardMouse.containsMouse ? Theme.bgHover : "transparent"

                                Icon {
                                    anchors.centerIn: parent
                                    name: NetworkService.wifiDrawerOpen ? "chevron-up" : "chevron-down"
                                    size: 12
                                    color: NetworkService.wifiDrawerOpen ? Theme.accentCyan : Theme.textMuted
                                }
                            }
                        }

                        // Clicking card body expands the Wi-Fi drawer
                        MouseArea {
                            id: wifiCardMouse
                            anchors.fill: parent
                            anchors.leftMargin: 46 // Don't intercept the radio toggle button on the left
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                NetworkService.wifiDrawerOpen = !NetworkService.wifiDrawerOpen;
                                if (NetworkService.wifiDrawerOpen) {
                                    NetworkService.btDrawerOpen = false;
                                }
                            }
                        }
                    }

                    // Bluetooth Split Master Tile
                    Rectangle {
                        Layout.fillWidth: true
                        height: 58
                        radius: 12
                        color: ShellState.glassEnabled ? "transparent" : (NetworkService.btPowered ? Theme.bgCard : Theme.bgPill)
                        border.color: ShellState.glassEnabled ? "transparent" : (NetworkService.btPowered ? Theme.accentSky : Theme.borderDim)
                        border.width: ShellState.glassEnabled ? 0 : 1

                        LiquidGlassSurface {
                            radius: 12
                            visible: ShellState.glassEnabled
                            accentColor: NetworkService.btPowered ? Theme.accentSky : Theme.textMuted
                            hovered: btCardMouse.containsMouse || btRadioMouse.containsMouse
                            showShadow: true
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            anchors.topMargin: 8
                            anchors.bottomMargin: 8
                            spacing: 8

                            // Left Button: Dedicated Bluetooth Radio Toggle
                            Rectangle {
                                width: 34
                                height: 34
                                radius: 9
                                color: NetworkService.btPowered
                                    ? Qt.rgba(Theme.accentSky.r, Theme.accentSky.g, Theme.accentSky.b, 0.22)
                                    : (btRadioMouse.containsMouse ? Theme.bgHover : Theme.bgBase)
                                border.color: NetworkService.btPowered ? Theme.accentSky : Theme.borderDim
                                border.width: 1

                                Icon {
                                    anchors.centerIn: parent
                                    name: NetworkService.btPowered ? "bluetooth" : "bluetooth-off"
                                    size: 16
                                    color: NetworkService.btPowered ? Theme.accentSky : Theme.textMuted
                                }

                                MouseArea {
                                    id: btRadioMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: NetworkService.toggleBluetooth()
                                }
                            }

                            // Middle Info: Device count & Name
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                RowLayout {
                                    spacing: 4
                                    Text {
                                        text: "Bluetooth"
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 11
                                        font.bold: true
                                        color: Theme.textPrimary
                                    }
                                    Rectangle {
                                        visible: NetworkService.btPowered && NetworkService.connectedBtCount > 0
                                        height: 14
                                        width: btCountTxt.implicitWidth + 6
                                        radius: 4
                                        color: Qt.rgba(Theme.accentEmerald.r, Theme.accentEmerald.g, Theme.accentEmerald.b, 0.22)
                                        Text {
                                            id: btCountTxt
                                            anchors.centerIn: parent
                                            text: NetworkService.connectedBtCount.toString()
                                            font.family: Theme.fontMono
                                            font.pixelSize: 8
                                            font.bold: true
                                            color: Theme.accentEmerald
                                        }
                                    }
                                }

                                Text {
                                    text: NetworkService.btPowered
                                        ? (NetworkService.primaryConnectedBt
                                            ? NetworkService.primaryConnectedBt.name
                                            : (NetworkService.btDevices.length > 0 ? (NetworkService.btDevices.length + " Paired") : "Ready"))
                                        : "Disabled"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 10
                                    color: NetworkService.btPowered && NetworkService.connectedBtCount > 0 ? Theme.accentEmerald : Theme.textMuted
                                    elide: Text.ElideRight
                                    Layout.maximumWidth: 70
                                }
                            }

                            // Right Button: Expand / Collapse Chevron
                            Rectangle {
                                width: 22
                                height: 22
                                radius: 6
                                color: btCardMouse.containsMouse ? Theme.bgHover : "transparent"

                                Icon {
                                    anchors.centerIn: parent
                                    name: NetworkService.btDrawerOpen ? "chevron-up" : "chevron-down"
                                    size: 12
                                    color: NetworkService.btDrawerOpen ? Theme.accentSky : Theme.textMuted
                                }
                            }
                        }

                        // Clicking card body expands the Bluetooth drawer
                        MouseArea {
                            id: btCardMouse
                            anchors.fill: parent
                            anchors.leftMargin: 46 // Don't intercept the radio toggle button on the left
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                NetworkService.btDrawerOpen = !NetworkService.btDrawerOpen;
                                if (NetworkService.btDrawerOpen) {
                                    NetworkService.wifiDrawerOpen = false;
                                }
                            }
                        }
                    }
                }

                // Collapsible Wi-Fi Glass Drawer
                Rectangle {
                    id: wifiDrawer
                    Layout.fillWidth: true
                    visible: NetworkService.wifiDrawerOpen
                    implicitHeight: wifiDrawerCol.implicitHeight + 20
                    radius: 12
                    color: ShellState.glassEnabled ? "transparent" : Theme.bgCard
                    border.color: ShellState.glassEnabled ? "transparent" : Qt.rgba(Theme.accentCyan.r, Theme.accentCyan.g, Theme.accentCyan.b, 0.35)
                    border.width: 1
                    clip: true

                    LiquidGlassSurface {
                        radius: 12
                        visible: ShellState.glassEnabled
                        accentColor: Theme.accentCyan
                        showShadow: true
                    }

                    ColumnLayout {
                        id: wifiDrawerCol
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 10

                        // Active Network Master Card
                        Rectangle {
                            Layout.fillWidth: true
                            visible: NetworkService.activeSsid.length > 0
                            height: 64
                            radius: 8
                            color: Theme.bgBase
                            border.color: Qt.rgba(Theme.accentCyan.r, Theme.accentCyan.g, Theme.accentCyan.b, 0.4)
                            border.width: 1

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 8
                                spacing: 4

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 6

                                    Rectangle {
                                        width: 8
                                        height: 8
                                        radius: 4
                                        color: Theme.accentEmerald
                                    }

                                    Text {
                                        text: NetworkService.activeWifi.ssid
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 11
                                        font.bold: true
                                        color: Theme.textPrimary
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }

                                    // 5G / 2.4G Pill
                                    Rectangle {
                                        height: 16
                                        implicitWidth: fTxt.implicitWidth + 8
                                        radius: 4
                                        color: Qt.rgba(Theme.accentCyan.r, Theme.accentCyan.g, Theme.accentCyan.b, 0.2)
                                        Text {
                                            id: fTxt
                                            anchors.centerIn: parent
                                            text: NetworkService.activeWifi.freq
                                            font.family: Theme.fontMono
                                            font.pixelSize: 9
                                            font.bold: true
                                            color: Theme.accentCyan
                                        }
                                    }

                                    // Signal badge
                                    Text {
                                        text: NetworkService.activeWifi.signal + "%"
                                        font.family: Theme.fontMono
                                        font.pixelSize: 9
                                        color: Theme.accentEmerald
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 8

                                    Text {
                                        text: NetworkService.activeWifi.ip ? ("IP: " + NetworkService.activeWifi.ip) : "Connected"
                                        font.family: Theme.fontMono
                                        font.pixelSize: 9
                                        color: Theme.textMuted
                                    }

                                    Text {
                                        text: NetworkService.activeWifi.rate ? ("• " + NetworkService.activeWifi.rate) : ""
                                        font.family: Theme.fontMono
                                        font.pixelSize: 9
                                        color: Theme.textMuted
                                        visible: NetworkService.activeWifi.rate.length > 0
                                    }

                                    Item { Layout.fillWidth: true }

                                    // Disconnect Pill
                                    Rectangle {
                                        height: 20
                                        implicitWidth: disTxt.implicitWidth + 10
                                        radius: 5
                                        color: disM.containsMouse ? Qt.rgba(Theme.accentRose.r, Theme.accentRose.g, Theme.accentRose.b, 0.25) : Theme.bgPill
                                        border.color: disM.containsMouse ? Theme.accentRose : Theme.borderDim
                                        border.width: 1

                                        Text {
                                            id: disTxt
                                            anchors.centerIn: parent
                                            text: "Disconnect"
                                            font.family: Theme.fontMono
                                            font.pixelSize: 8
                                            font.bold: true
                                            color: disM.containsMouse ? Theme.accentRose : Theme.textSecondary
                                        }

                                        MouseArea {
                                            id: disM
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: NetworkService.disconnectWifi()
                                        }
                                    }
                                }
                            }
                        }

                        // Available Networks Header Row
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 6

                            Text {
                                text: "AVAILABLE NETWORKS"
                                font.family: Theme.fontMono
                                font.pixelSize: 9
                                font.bold: true
                                color: Theme.textSecondary
                                Layout.fillWidth: true
                            }

                            // Rescan Button
                            Rectangle {
                                height: 22
                                implicitWidth: scanRow.implicitWidth + 10
                                radius: 5
                                color: rescanM.containsMouse ? Theme.bgHover : Theme.bgPill
                                border.color: Theme.borderDim
                                border.width: 1

                                RowLayout {
                                    id: scanRow
                                    anchors.centerIn: parent
                                    spacing: 4

                                    Icon {
                                        name: "refresh-cw"
                                        size: 10
                                        color: NetworkService.refreshing ? Theme.accentCyan : Theme.textMuted
                                        rotation: NetworkService.refreshing ? 180 : 0
                                        Behavior on rotation { NumberAnimation { duration: 500 } }
                                    }

                                    Text {
                                        text: NetworkService.refreshing ? "Scanning..." : "Rescan"
                                        font.family: Theme.fontMono
                                        font.pixelSize: 8
                                        color: Theme.accentCyan
                                    }
                                }

                                MouseArea {
                                    id: rescanM
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: NetworkService.rescanWifi()
                                }
                            }
                        }

                        // Networks Repeater (Max 5 items displayed for clean compactness)
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 4

                            Repeater {
                                model: NetworkService.networks.slice(0, 5)

                                delegate: Rectangle {
                                    Layout.fillWidth: true
                                    height: 32
                                    radius: 6
                                    color: netM.containsMouse ? Theme.bgHover : (modelData.inUse ? Qt.rgba(Theme.accentCyan.r, Theme.accentCyan.g, Theme.accentCyan.b, 0.12) : "transparent")
                                    border.color: modelData.inUse ? Qt.rgba(Theme.accentCyan.r, Theme.accentCyan.g, Theme.accentCyan.b, 0.3) : "transparent"
                                    border.width: 1

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 8
                                        anchors.rightMargin: 8
                                        spacing: 8

                                        Icon {
                                            name: "wifi"
                                            size: 13
                                            color: modelData.inUse ? Theme.accentCyan : (modelData.signal > 60 ? Theme.textPrimary : Theme.textMuted)
                                        }

                                        Text {
                                            text: modelData.ssid
                                            font.family: Theme.fontFamily
                                            font.pixelSize: 10
                                            font.bold: modelData.inUse
                                            color: modelData.inUse ? Theme.accentCyan : Theme.textPrimary
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                        }

                                        // Lock Icon if secured
                                        Icon {
                                            name: modelData.security === "Open" ? "unlock" : "lock"
                                            size: 10
                                            color: Theme.textMuted
                                        }

                                        // Signal %
                                        Text {
                                            text: modelData.signal + "%"
                                            font.family: Theme.fontMono
                                            font.pixelSize: 8
                                            color: Theme.textMuted
                                        }

                                        // Connect / Connected Badge
                                        Rectangle {
                                            height: 18
                                            implicitWidth: connBadgeTxt.implicitWidth + 8
                                            radius: 4
                                            color: modelData.inUse
                                                ? Qt.rgba(Theme.accentEmerald.r, Theme.accentEmerald.g, Theme.accentEmerald.b, 0.2)
                                                : (netM.containsMouse ? Theme.accentCyan : Theme.bgBase)

                                            Text {
                                                id: connBadgeTxt
                                                anchors.centerIn: parent
                                                text: modelData.inUse ? "Active" : "Connect"
                                                font.family: Theme.fontMono
                                                font.pixelSize: 8
                                                font.bold: true
                                                color: modelData.inUse ? Theme.accentEmerald : (netM.containsMouse ? Theme.textOnAccent : Theme.textSecondary)
                                            }
                                        }
                                    }

                                    MouseArea {
                                        id: netM
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (!modelData.inUse) {
                                                NetworkService.connectWifi(modelData.ssid, "");
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // Collapsible Bluetooth & Peripherals Master Deck Drawer
                Rectangle {
                    id: btDrawer
                    Layout.fillWidth: true
                    visible: NetworkService.btDrawerOpen
                    implicitHeight: btDrawerCol.implicitHeight + 20
                    radius: 12
                    color: ShellState.glassEnabled ? "transparent" : Theme.bgCard
                    border.color: ShellState.glassEnabled ? "transparent" : Qt.rgba(Theme.accentSky.r, Theme.accentSky.g, Theme.accentSky.b, 0.35)
                    border.width: 1
                    clip: true

                    LiquidGlassSurface {
                        radius: 12
                        visible: ShellState.glassEnabled
                        accentColor: Theme.accentSky
                        showShadow: true
                    }

                    ColumnLayout {
                        id: btDrawerCol
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 10

                        // Header Row
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 6

                            Icon {
                                name: "bluetooth"
                                size: 12
                                color: Theme.accentSky
                            }

                            Text {
                                text: "PERIPHERALS MASTER DECK"
                                font.family: Theme.fontMono
                                font.pixelSize: 9
                                font.bold: true
                                color: Theme.accentSky
                                Layout.fillWidth: true
                            }

                            // Device count badge
                            Text {
                                text: NetworkService.connectedBtCount + " Connected / " + NetworkService.btDevices.length + " Paired"
                                font.family: Theme.fontMono
                                font.pixelSize: 8
                                color: Theme.textMuted
                            }
                        }

                        // Section 1: Active Connected Peripherals with Battery Badges
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 4
                            visible: NetworkService.connectedBtCount > 0

                            Text {
                                text: "CONNECTED DEVICES"
                                font.family: Theme.fontMono
                                font.pixelSize: 8
                                font.bold: true
                                color: Theme.accentEmerald
                            }

                            Repeater {
                                model: NetworkService.btDevices.filter(function(d) { return d.connected; })

                                delegate: Rectangle {
                                    Layout.fillWidth: true
                                    height: 38
                                    radius: 7
                                    color: Theme.bgBase
                                    border.color: Qt.rgba(Theme.accentEmerald.r, Theme.accentEmerald.g, Theme.accentEmerald.b, 0.35)
                                    border.width: 1

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 8
                                        anchors.rightMargin: 8
                                        spacing: 8

                                        Icon {
                                            name: modelData.icon || "bluetooth"
                                            size: 15
                                            color: Theme.accentEmerald
                                        }

                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: 1

                                            Text {
                                                text: modelData.name
                                                font.family: Theme.fontFamily
                                                font.pixelSize: 10
                                                font.bold: true
                                                color: Theme.textPrimary
                                                elide: Text.ElideRight
                                                Layout.fillWidth: true
                                            }

                                            Text {
                                                text: modelData.mac
                                                font.family: Theme.fontMono
                                                font.pixelSize: 8
                                                color: Theme.textMuted
                                            }
                                        }

                                        // Battery Badge (if available, e.g. 85%)
                                        Rectangle {
                                            visible: modelData.battery >= 0
                                            height: 18
                                            implicitWidth: batTxt.implicitWidth + 10
                                            radius: 5
                                            color: modelData.battery > 30
                                                ? Qt.rgba(Theme.accentEmerald.r, Theme.accentEmerald.g, Theme.accentEmerald.b, 0.2)
                                                : Qt.rgba(Theme.accentAmber.r, Theme.accentAmber.g, Theme.accentAmber.b, 0.25)
                                            border.color: modelData.battery > 30 ? Theme.accentEmerald : Theme.accentAmber
                                            border.width: 1

                                            RowLayout {
                                                anchors.centerIn: parent
                                                spacing: 3
                                                Icon {
                                                    name: modelData.battery > 20 ? "battery" : "battery-warning"
                                                    size: 9
                                                    color: modelData.battery > 30 ? Theme.accentEmerald : Theme.accentAmber
                                                }
                                                Text {
                                                    id: batTxt
                                                    text: modelData.battery + "%"
                                                    font.family: Theme.fontMono
                                                    font.pixelSize: 8
                                                    font.bold: true
                                                    color: modelData.battery > 30 ? Theme.accentEmerald : Theme.accentAmber
                                                }
                                            }
                                        }

                                        // Disconnect Button
                                        Rectangle {
                                            height: 20
                                            implicitWidth: btDisTxt.implicitWidth + 8
                                            radius: 4
                                            color: btDisM.containsMouse ? Qt.rgba(Theme.accentRose.r, Theme.accentRose.g, Theme.accentRose.b, 0.25) : Theme.bgPill
                                            border.color: btDisM.containsMouse ? Theme.accentRose : Theme.borderDim
                                            border.width: 1

                                            Text {
                                                id: btDisTxt
                                                anchors.centerIn: parent
                                                text: "Disconnect"
                                                font.family: Theme.fontMono
                                                font.pixelSize: 8
                                                font.bold: true
                                                color: btDisM.containsMouse ? Theme.accentRose : Theme.textSecondary
                                            }

                                            MouseArea {
                                                id: btDisM
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: NetworkService.toggleBtDevice(modelData.mac, true)
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // Section 2: Paired / Disconnected Devices
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 4

                            Text {
                                text: "PAIRED PERIPHERALS"
                                font.family: Theme.fontMono
                                font.pixelSize: 8
                                font.bold: true
                                color: Theme.textMuted
                            }

                            Repeater {
                                model: NetworkService.btDevices.filter(function(d) { return !d.connected; })

                                delegate: Rectangle {
                                    Layout.fillWidth: true
                                    height: 32
                                    radius: 6
                                    color: btItemM.containsMouse ? Theme.bgHover : Theme.bgBase
                                    border.color: Theme.borderDim
                                    border.width: 1

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 8
                                        anchors.rightMargin: 8
                                        spacing: 8

                                        Icon {
                                            name: modelData.icon || "bluetooth"
                                            size: 13
                                            color: Theme.textMuted
                                        }

                                        Text {
                                            text: modelData.name
                                            font.family: Theme.fontFamily
                                            font.pixelSize: 10
                                            color: Theme.textPrimary
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                        }

                                        // Connect Button
                                        Rectangle {
                                            height: 18
                                            implicitWidth: btConnTxt.implicitWidth + 8
                                            radius: 4
                                            color: btItemM.containsMouse ? Theme.accentSky : Theme.bgPill

                                            Text {
                                                id: btConnTxt
                                                anchors.centerIn: parent
                                                text: "Connect"
                                                font.family: Theme.fontMono
                                                font.pixelSize: 8
                                                font.bold: true
                                                color: btItemM.containsMouse ? Theme.textOnAccent : Theme.accentSky
                                            }
                                        }
                                    }

                                    MouseArea {
                                        id: btItemM
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: NetworkService.toggleBtDevice(modelData.mac, false)
                                    }
                                }
                            }
                        }

                        // Empty State if no Bluetooth devices
                        Text {
                            visible: NetworkService.btDevices.length === 0
                            text: "No paired Bluetooth devices found."
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                            font.italic: true
                            color: Theme.textMuted
                        }
                    }
                }

            // System Styling & Performance Toggles (Liquid Glass & Lite Mode)
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                // Liquid Glass Tile
                Rectangle {
                    Layout.fillWidth: true
                    height: 54
                    radius: 12
                    color: ShellState.glassEnabled ? "transparent" : (glassMouse.containsMouse ? Theme.bgHover : Theme.bgPill)
                    border.color: ShellState.glassEnabled ? "transparent" : (ShellState.glassButtons ? Theme.accentCyan : Theme.borderDim)
                    border.width: ShellState.glassEnabled ? 0 : 1

                    LiquidGlassSurface {
                        radius: 12
                        visible: ShellState.glassEnabled
                        accentColor: Theme.accentCyan
                        hovered: glassMouse.containsMouse
                        showShadow: true
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 10

                        Icon {
                            name: "sparkles"
                            size: 18
                            color: ShellState.plasticMode ? Theme.accentCyan : Theme.textPrimary
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1
                            Text {
                                text: "Apple Plastic"
                                font.family: Theme.fontFamily
                                font.pixelSize: 12
                                font.bold: true
                                color: ShellState.plasticMode ? Theme.accentCyan : Theme.textPrimary
                            }
                            Text {
                                text: ShellState.plasticMode ? "Glossy Plastic Mode" : "Flat Interface"
                                font.family: Theme.fontFamily
                                font.pixelSize: 10
                                color: Theme.textMuted
                            }
                        }
                    }

                    MouseArea {
                        id: glassMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: ShellState.togglePlasticMode()
                    }
                }

                // Lite Mode Tile
                Rectangle {
                    Layout.fillWidth: true
                    height: 54
                    radius: 12
                    color: ShellState.glassEnabled ? "transparent" : (ShellState.liteMode ? Qt.rgba(Theme.accentAmber.r, Theme.accentAmber.g, Theme.accentAmber.b, 0.22) : (liteMouse.containsMouse ? Theme.bgHover : Theme.bgPill))
                    border.color: ShellState.glassEnabled ? "transparent" : (ShellState.liteMode ? Theme.accentAmber : Theme.borderDim)
                    border.width: ShellState.glassEnabled ? 0 : 1

                    LiquidGlassSurface {
                        radius: 12
                        visible: ShellState.glassEnabled
                        accentColor: ShellState.liteMode ? Theme.accentAmber : Theme.textMuted
                        hovered: liteMouse.containsMouse
                        showShadow: true
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 10

                        Icon {
                            name: ShellState.liteMode ? "zap" : "sparkles"
                            size: 18
                            color: ShellState.liteMode ? Theme.accentAmber : Theme.textPrimary
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1
                            Text {
                                text: "Lite Mode"
                                font.family: Theme.fontFamily
                                font.pixelSize: 12
                                font.bold: true
                                color: ShellState.liteMode ? Theme.accentAmber : Theme.textPrimary
                            }
                            Text {
                                text: ShellState.liteMode ? "Max GPU FPS" : "Standard Visuals"
                                font.family: Theme.fontFamily
                                font.pixelSize: 10
                                color: Theme.textMuted
                            }
                        }
                    }

                    MouseArea {
                        id: liteMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: ShellState.toggleLiteMode()
                    }
                }
            }

            // ── Mobile Remote (PWA) Card ─────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                radius: 12
                color: ShellState.glassEnabled ? "transparent" : Theme.bgCard
                border.color: ShellState.glassEnabled ? "transparent" : (RemoteService.isOnline ? Qt.rgba(Theme.accentCyan.r, Theme.accentCyan.g, Theme.accentCyan.b, 0.4) : Theme.borderDim)
                border.width: ShellState.glassEnabled ? 0 : 1
                implicitHeight: remoteCol.implicitHeight + 20

                LiquidGlassSurface {
                    radius: 12
                    visible: ShellState.glassEnabled
                    accentColor: RemoteService.isOnline ? Theme.accentCyan : Theme.textMuted
                    showShadow: true
                }

                ColumnLayout {
                    id: remoteCol
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 8

                    // Header Row: Icon, Title, Status Pill, Refresh
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Icon {
                            name: "smartphone"
                            size: 14
                            color: RemoteService.isOnline ? Theme.accentCyan : Theme.textMuted
                        }

                        Text {
                            text: "ANTIGRAVITY REMOTE"
                            font.family: Theme.fontMono
                            font.pixelSize: 10
                            font.bold: true
                            color: Theme.textMuted
                        }

                        Item { Layout.fillWidth: true }

                        // Online / Offline Status Badge
                        Rectangle {
                            height: 20
                            implicitWidth: rBadgeRow.implicitWidth + 12
                            radius: 10
                            color: RemoteService.isOnline ? Qt.rgba(0.06, 0.72, 0.51, 0.15) : Qt.rgba(0.94, 0.27, 0.27, 0.15)
                            border.color: RemoteService.isOnline ? "#10B981" : "#EF4444"
                            border.width: 1

                            RowLayout {
                                id: rBadgeRow
                                anchors.centerIn: parent
                                spacing: 4

                                Rectangle {
                                    width: 6
                                    height: 6
                                    radius: 3
                                    color: RemoteService.isOnline ? "#10B981" : "#EF4444"
                                }

                                Text {
                                    text: RemoteService.isOnline ? "ONLINE" : "OFFLINE"
                                    font.family: Theme.fontMono
                                    font.pixelSize: 9
                                    font.bold: true
                                    color: RemoteService.isOnline ? "#10B981" : "#EF4444"
                                }
                            }
                        }

                        // Restart Button
                        Rectangle {
                            width: 22
                            height: 22
                            radius: 11
                            color: rRstMouse.containsMouse ? Theme.bgHover : "transparent"
                            border.color: Theme.borderDim
                            border.width: 1

                            Icon {
                                anchors.centerIn: parent
                                name: "refresh-cw"
                                size: 11
                                color: rRstMouse.containsMouse ? Theme.accentCyan : Theme.textMuted
                            }

                            MouseArea {
                                id: rRstMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: RemoteService.restartDaemon()
                            }
                        }
                    }

                    // Content Row: QR Code thumbnail + Connection info
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12

                        // QR Code Image (Click to open full view)
                        Rectangle {
                            width: 62
                            height: 62
                            radius: 8
                            color: "#FFFFFF"
                            clip: true
                            border.color: Theme.borderDim
                            border.width: 1

                            Image {
                                anchors.fill: parent
                                anchors.margins: 2
                                source: "file://" + RemoteService.qrPath
                                fillMode: Image.PreserveAspectFit
                                cache: false
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    Quickshell.execDetached(["xdg-open", RemoteService.qrPath]);
                                }
                            }
                        }

                        // Info Column: URL + IP + Copy button
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 3

                            Text {
                                text: RemoteService.remoteUrl || "Starting daemon..."
                                font.family: Theme.fontMono
                                font.pixelSize: 11
                                font.bold: true
                                color: Theme.accentCyan
                                elide: Text.ElideRight
                                Layout.maximumWidth: 240
                            }

                            Text {
                                text: "LAN: " + RemoteService.ip + ":" + RemoteService.port + " • SSL Universal"
                                font.family: Theme.fontFamily
                                font.pixelSize: 9
                                color: Theme.textMuted
                            }

                            RowLayout {
                                spacing: 6
                                Layout.topMargin: 2

                                // Copy Link Button
                                Rectangle {
                                    height: 22
                                    implicitWidth: copyRow.implicitWidth + 12
                                    radius: 6
                                    color: copyMouse.containsMouse ? Theme.bgHover : Theme.bgPill
                                    border.color: Theme.borderDim
                                    border.width: 1

                                    RowLayout {
                                        id: copyRow
                                        anchors.centerIn: parent
                                        spacing: 4
                                        Icon {
                                            name: "copy"
                                            size: 10
                                            color: Theme.textPrimary
                                        }
                                        Text {
                                            text: copyFeedback.running ? "Copied!" : "Copy URL"
                                            font.family: Theme.fontFamily
                                            font.pixelSize: 9
                                            color: copyFeedback.running ? Theme.accentCyan : Theme.textPrimary
                                        }
                                    }

                                    Timer {
                                        id: copyFeedback
                                        interval: 1500
                                        repeat: false
                                    }

                                    MouseArea {
                                        id: copyMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            Quickshell.execDetached(["wl-copy", RemoteService.remoteUrl]);
                                            copyFeedback.start();
                                        }
                                    }
                                }

                                // Toggle Service Button
                                Rectangle {
                                    height: 22
                                    implicitWidth: tglRow.implicitWidth + 12
                                    radius: 6
                                    color: tglMouse.containsMouse ? Theme.bgHover : Theme.bgPill
                                    border.color: Theme.borderDim
                                    border.width: 1

                                    RowLayout {
                                        id: tglRow
                                        anchors.centerIn: parent
                                        spacing: 4
                                        Icon {
                                            name: RemoteService.isOnline ? "power" : "play"
                                            size: 10
                                            color: RemoteService.isOnline ? Theme.accentRose : Theme.accentEmerald
                                        }
                                        Text {
                                            text: RemoteService.isOnline ? "Stop" : "Start"
                                            font.family: Theme.fontFamily
                                            font.pixelSize: 9
                                            color: RemoteService.isOnline ? Theme.accentRose : Theme.accentEmerald
                                        }
                                    }

                                    MouseArea {
                                        id: tglMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: RemoteService.toggleDaemon()
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Quick Sliders (Volume & Brightness)
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 10

                // Volume Slider Tile
                Rectangle {
                    Layout.fillWidth: true
                    height: 52
                    radius: 12
                    color: ShellState.glassEnabled ? "transparent" : Theme.bgCard
                    border.color: ShellState.glassEnabled ? "transparent" : Theme.borderDim
                    border.width: ShellState.glassEnabled ? 0 : 1

                    LiquidGlassSurface {
                        radius: 12
                        visible: ShellState.glassEnabled
                        accentColor: AudioService.muted ? Theme.accentRose : Theme.accentCyan
                        showShadow: true
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 12

                        // Mute/Unmute Icon Gem
                        Item {
                            width: 32
                            height: 32

                            LiquidGlassSurface {
                                radius: 16
                                visible: ShellState.glassEnabled
                                accentColor: AudioService.muted ? Theme.accentRose : Theme.accentCyan
                                hovered: ccVolIcoMouse.containsMouse
                                showShadow: false
                            }

                            Rectangle {
                                anchors.fill: parent
                                radius: 16
                                visible: !ShellState.glassEnabled
                                color: ccVolIcoMouse.containsMouse ? Theme.bgHover : "transparent"
                                border.color: Theme.borderDim
                                border.width: 1
                            }

                            Icon {
                                anchors.centerIn: parent
                                name: AudioService.muted ? "volume-x" : (AudioService.volume > 0.5 ? "volume-2" : "volume-1")
                                size: 16
                                color: AudioService.muted ? Theme.accentRose : Theme.accentCyan
                            }

                            MouseArea {
                                id: ccVolIcoMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: AudioService.toggleMute()
                            }
                        }

                        // Slider Track & Label Stack
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 4

                            RowLayout {
                                Layout.fillWidth: true
                                Text {
                                    text: "Volume"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 11
                                    font.bold: true
                                    color: Theme.textPrimary
                                }
                                Item { Layout.fillWidth: true }
                                Text {
                                    text: AudioService.muted ? "MUTED" : Math.round(AudioService.volume * 100) + "%"
                                    font.family: Theme.fontMono
                                    font.pixelSize: 11
                                    font.bold: true
                                    color: AudioService.muted ? Theme.accentRose : Theme.accentCyan
                                }
                            }

                            // Slider Bar
                            Rectangle {
                                id: ccVolTrack
                                Layout.fillWidth: true
                                height: 8
                                radius: 4
                                color: ShellState.plasticMode ? Qt.rgba(0.04, 0.07, 0.12, 0.75) : Theme.bgPill
                                border.color: ShellState.plasticMode ? Qt.rgba(1, 1, 1, 0.12) : "transparent"
                                border.width: ShellState.plasticMode ? 1 : 0
                                clip: true

                                Rectangle {
                                    anchors.left: parent.left
                                    anchors.top: parent.top
                                    anchors.bottom: parent.bottom
                                    width: AudioService.muted ? 0 : Math.max(height, Math.round(parent.width * Math.min(1.0, AudioService.volume)))
                                    radius: 4
                                    color: AudioService.muted ? Theme.accentRose : Theme.accentCyan

                                    gradient: Gradient {
                                        orientation: Gradient.Vertical
                                        GradientStop { position: 0.0; color: Qt.lighter(AudioService.muted ? Theme.accentRose : Theme.accentCyan, 1.35) }
                                        GradientStop { position: 0.45; color: AudioService.muted ? Theme.accentRose : Theme.accentCyan }
                                        GradientStop { position: 1.0; color: Qt.darker(AudioService.muted ? Theme.accentRose : Theme.accentCyan, 1.25) }
                                    }

                                    Rectangle {
                                        anchors.top: parent.top
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.margins: 1
                                        height: 2
                                        radius: 1
                                        color: Qt.rgba(1, 1, 1, 0.65)
                                        visible: ShellState.plasticMode
                                    }

                                    Behavior on width {
                                        NumberAnimation { duration: 100; easing.type: Easing.OutQuad }
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    function setFromPos(mouseX) {
                                        const p = Math.max(0.0, Math.min(1.0, mouseX / ccVolTrack.width));
                                        AudioService.setVolume(p);
                                    }
                                    onClicked: mouse => setFromPos(mouse.x)
                                    onPositionChanged: mouse => { if (pressed) setFromPos(mouse.x); }
                                    onWheel: wheel => {
                                        if (wheel.angleDelta.y > 0) AudioService.changeVolume(0.05);
                                        else AudioService.changeVolume(-0.05);
                                    }
                                }
                            }
                        }
                    }
                }

                // Brightness Slider Tile
                Rectangle {
                    Layout.fillWidth: true
                    height: 52
                    radius: 12
                    color: ShellState.glassEnabled ? "transparent" : Theme.bgCard
                    border.color: ShellState.glassEnabled ? "transparent" : Theme.borderDim
                    border.width: ShellState.glassEnabled ? 0 : 1

                    LiquidGlassSurface {
                        radius: 12
                        visible: ShellState.glassEnabled
                        accentColor: Theme.accentAmber
                        showShadow: true
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 12

                        // Sun Icon Gem
                        Item {
                            width: 32
                            height: 32

                            LiquidGlassSurface {
                                radius: 16
                                visible: ShellState.glassEnabled
                                accentColor: Theme.accentAmber
                                hovered: ccBriIcoMouse.containsMouse
                                showShadow: false
                            }

                            Rectangle {
                                anchors.fill: parent
                                radius: 16
                                visible: !ShellState.glassEnabled
                                color: ccBriIcoMouse.containsMouse ? Theme.bgHover : "transparent"
                                border.color: Theme.borderDim
                                border.width: 1
                            }

                            Icon {
                                anchors.centerIn: parent
                                name: "sun"
                                size: 16
                                color: Theme.accentAmber
                            }

                            MouseArea {
                                id: ccBriIcoMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: BrightnessService.refresh(true)
                            }
                        }

                        // Slider Track & Label Stack
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 4

                            RowLayout {
                                Layout.fillWidth: true
                                Text {
                                    text: "Display Brightness"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 11
                                    font.bold: true
                                    color: Theme.textPrimary
                                }
                                Item { Layout.fillWidth: true }
                                Text {
                                    text: BrightnessService.percent + "%"
                                    font.family: Theme.fontMono
                                    font.pixelSize: 11
                                    font.bold: true
                                    color: Theme.accentAmber
                                }
                            }

                            // Slider Bar
                            Rectangle {
                                id: ccBriTrack
                                Layout.fillWidth: true
                                height: 8
                                radius: 4
                                color: ShellState.plasticMode ? Qt.rgba(0.04, 0.07, 0.12, 0.75) : Theme.bgPill
                                border.color: ShellState.plasticMode ? Qt.rgba(1, 1, 1, 0.12) : "transparent"
                                border.width: ShellState.plasticMode ? 1 : 0
                                clip: true

                                Rectangle {
                                    anchors.left: parent.left
                                    anchors.top: parent.top
                                    anchors.bottom: parent.bottom
                                    width: Math.max(height, Math.round(parent.width * (BrightnessService.percent / 100.0)))
                                    radius: 4
                                    color: Theme.accentAmber

                                    gradient: Gradient {
                                        orientation: Gradient.Vertical
                                        GradientStop { position: 0.0; color: Qt.lighter(Theme.accentAmber, 1.35) }
                                        GradientStop { position: 0.45; color: Theme.accentAmber }
                                        GradientStop { position: 1.0; color: Qt.darker(Theme.accentAmber, 1.25) }
                                    }

                                    Rectangle {
                                        anchors.top: parent.top
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.margins: 1
                                        height: 2
                                        radius: 1
                                        color: Qt.rgba(1, 1, 1, 0.65)
                                        visible: ShellState.plasticMode
                                    }

                                    Behavior on width {
                                        NumberAnimation { duration: 100; easing.type: Easing.OutQuad }
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    function setFromPos(mouseX) {
                                        const p = Math.max(0.01, Math.min(1.0, mouseX / ccBriTrack.width));
                                        BrightnessService.setPercent(Math.round(p * 100));
                                    }
                                    onClicked: mouse => setFromPos(mouse.x)
                                    onPositionChanged: mouse => { if (pressed) setFromPos(mouse.x); }
                                    onWheel: wheel => {
                                        if (wheel.angleDelta.y > 0) BrightnessService.increase();
                                        else BrightnessService.decrease();
                                    }
                                }
                            }
                        }
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

            // Battery & Power Statistics Card
            Rectangle {
                Layout.fillWidth: true
                radius: 12
                color: Theme.bgCard
                border.color: Theme.borderDim
                border.width: 1
                visible: BatteryService.available
                implicitHeight: batCol.implicitHeight + 20

                ColumnLayout {
                    id: batCol
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 8

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Icon {
                            name: BatteryService.isCharging ? "battery-charging" : (BatteryService.percentage <= 20 ? "battery-warning" : "battery")
                            size: 14
                            color: BatteryService.isCharging ? Theme.accentEmerald : (BatteryService.percentage <= 20 ? Theme.accentRose : Theme.accentAmber)
                        }

                        Text {
                            text: "BATTERY & POWER"
                            font.family: Theme.fontMono
                            font.pixelSize: 10
                            font.bold: true
                            color: Theme.textMuted
                        }

                        Item { Layout.fillWidth: true }

                        Text {
                            text: BatteryService.percentage + "% (" + BatteryService.status + ")"
                            font.family: Theme.fontMono
                            font.pixelSize: 11
                            font.bold: true
                            color: BatteryService.isCharging ? Theme.accentEmerald : Theme.textPrimary
                        }
                    }

                    // Progress bar
                    Rectangle {
                        Layout.fillWidth: true
                        height: 5
                        radius: 2.5
                        color: Theme.bgSurface
                        clip: true

                        Rectangle {
                            width: parent.width * Math.max(0.02, Math.min(1.0, BatteryService.percentage / 100))
                            height: parent.height
                            color: BatteryService.isCharging ? Theme.accentEmerald : (BatteryService.percentage <= 20 ? Theme.accentRose : Theme.accentAmber)
                        }
                    }

                    // Action Button: Open Power Statistics
                    Rectangle {
                        Layout.fillWidth: true
                        height: 30
                        radius: 6
                        color: openStatsBtnMouse.containsMouse ? Theme.bgHover : Theme.bgPill
                        border.color: openStatsBtnMouse.containsMouse ? Theme.accentSky : Theme.borderDim
                        border.width: 1

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 6

                            Icon {
                                name: "activity"
                                size: 12
                                color: openStatsBtnMouse.containsMouse ? Theme.accentSky : Theme.textSecondary
                            }

                            Text {
                                text: "Open Power Statistics (Graphs & History)"
                                font.family: Theme.fontFamily
                                font.pixelSize: 10
                                font.bold: true
                                color: openStatsBtnMouse.containsMouse ? Theme.textPrimary : Theme.textSecondary
                            }
                        }

                        MouseArea {
                            id: openStatsBtnMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                ShellState.controlCenterOpen = false;
                                BatteryService.openPowerStatistics();
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

                // Theme Chips Scrollable Container
                Rectangle {
                    id: themeScrollContainer
                    Layout.fillWidth: true
                    height: Math.min(themeGrid.implicitHeight + 8, 148)
                    radius: 8
                    color: ShellState.glassEnabled ? Qt.rgba(0, 0, 0, 0.15) : Qt.rgba(0, 0, 0, 0.20)
                    border.color: Theme.borderDim
                    border.width: 1
                    clip: true

                    MouseArea {
                        anchors.fill: parent
                        z: -1
                        onWheel: wheel => {
                            const step = (wheel.angleDelta.y / 120.0) * 38.0;
                            themeFlick.contentY = Math.max(0, Math.min(themeFlick.contentHeight - themeFlick.height, themeFlick.contentY - step));
                        }
                    }

                    Flickable {
                        id: themeFlick
                        anchors.fill: parent
                        anchors.topMargin: 4
                        anchors.bottomMargin: 4
                        anchors.leftMargin: 4
                        anchors.rightMargin: 8
                        contentWidth: width
                        contentHeight: themeGrid.implicitHeight
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds

                        ScrollBar.vertical: ScrollBar {
                            id: themeScrollBar
                            active: true
                            policy: themeFlick.contentHeight > themeFlick.height ? ScrollBar.AsNeeded : ScrollBar.AlwaysOff
                        }

                        GridLayout {
                            id: themeGrid
                            width: themeFlick.width
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
                                    readonly property var pal: (Theme.palettes && Theme.palettes[modelData]) || ({ "name": modelData, "accentViolet": "#A78BFA", "accentSky": "#38BDF8" })

                                    color: isSelected ? Theme.bgCard : (chipMouse.containsMouse ? Theme.bgHover : Theme.bgPill)
                                    border.color: isSelected ? (pal.accentViolet || Theme.accentViolet) : Theme.borderDim
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
                                                color: pal.accentViolet || Theme.accentViolet
                                            }
                                            Rectangle {
                                                width: 8
                                                height: 8
                                                radius: 4
                                                color: pal.accentSky || Theme.accentSky
                                            }
                                        }

                                        Text {
                                            Layout.fillWidth: true
                                            text: pal.name || modelData
                                            font.family: Theme.fontFamily
                                            font.pixelSize: 10
                                            font.bold: isSelected
                                            color: isSelected ? (pal.accentViolet || Theme.accentViolet) : Theme.textPrimary
                                            elide: Text.ElideRight
                                        }

                                        Icon {
                                            visible: isSelected
                                            name: "check"
                                            size: 11
                                            color: pal.accentViolet || Theme.accentViolet
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
                                        onWheel: wheel => {
                                            const step = (wheel.angleDelta.y / 120.0) * 38.0;
                                            themeFlick.contentY = Math.max(0, Math.min(themeFlick.contentHeight - themeFlick.height, themeFlick.contentY - step));
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Typography Preset Switcher
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 6

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Icon {
                        name: "type"
                        size: 12
                        color: Theme.textMuted
                    }

                    Text {
                        text: "TYPOGRAPHY & FONTS"
                        font.family: Theme.fontMono
                        font.pixelSize: 10
                        font.bold: true
                        color: Theme.textMuted
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        text: ShellState.fontPreset === "cupertino" ? "Cupertino Glass" : (ShellState.fontPreset === "nordic" ? "Cyber Nordic" : "Google Material")
                        font.family: Theme.fontMono
                        font.pixelSize: 9
                        font.bold: true
                        color: Theme.accentViolet
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Repeater {
                        model: [
                            { id: "cupertino", name: "Cupertino", font: "SF Pro Display", sub: "SF Pro + JetBrains" },
                            { id: "nordic", name: "Cyber Nordic", font: "Plus Jakarta Sans", sub: "Jakarta + Fira" },
                            { id: "google", name: "Material", font: "Google Sans", sub: "Google + Adwaita" }
                        ]

                        Rectangle {
                            Layout.fillWidth: true
                            height: 32
                            radius: 8
                            readonly property bool isSelected: ShellState.fontPreset === modelData.id
                            color: isSelected ? Theme.bgCard : (ccfMouse.containsMouse ? Theme.bgHover : Theme.bgPill)
                            border.color: isSelected ? Theme.accentViolet : Theme.borderDim
                            border.width: isSelected ? 1.5 : 1

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                anchors.rightMargin: 8
                                spacing: 6

                                Text {
                                    text: "Aa"
                                    font.family: modelData.font
                                    font.pixelSize: 11
                                    font.bold: true
                                    color: isSelected ? Theme.accentViolet : Theme.textMuted
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.name
                                    font.family: modelData.font
                                    font.pixelSize: 10
                                    font.bold: isSelected
                                    color: isSelected ? Theme.accentViolet : Theme.textPrimary
                                    elide: Text.ElideRight
                                }

                                Icon {
                                    visible: isSelected
                                    name: "check"
                                    size: 10
                                    color: Theme.accentViolet
                                }
                            }

                            MouseArea {
                                id: ccfMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    ShellState.fontPreset = modelData.id;
                                    Theme.fontPreset = modelData.id;
                                    Quickshell.execDetached(["notify-send", "-a", "Antigravity", "Font Changed", "Switched typography to " + modelData.name]);
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
