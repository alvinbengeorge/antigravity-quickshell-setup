import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import "../theme"
import "../services"
import "../components"

PanelWindow {
    id: waWindow

    visible: ShellState.whatsappOpen
    color: "transparent"

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "quickshell:whatsapp"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: ShellState.whatsappOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    property string searchFilter: ""
    property string activeTab: "all" // "all", "unread", "groups", "direct"

    onVisibleChanged: {
        if (visible) {
            searchFilter = "";
            activeTab = "all";
            WhatsAppService.refresh();
            Qt.callLater(() => {
                searchInput.forceActiveFocus();
            });
        }
    }

    // Dismiss on Escape
    Item {
        focus: true
        Keys.onEscapePressed: ShellState.whatsappOpen = false
    }

    // Backdrop click dismiss
    MouseArea {
        anchors.fill: parent
        onClicked: ShellState.whatsappOpen = false

        Rectangle {
            anchors.fill: parent
            color: "#000000"
            opacity: 0.55
            Behavior on opacity { NumberAnimation { duration: 200 } }
        }
    }

    // Slide-out Drawer from the Left
    Rectangle {
        id: drawerCard
        width: 440
        anchors {
            top: parent.top
            bottom: parent.bottom
            topMargin: 52
            bottomMargin: 16
        }

        // Slide animation from x: -460 to x: 16
        x: ShellState.whatsappOpen ? 16 : -460
        Behavior on x {
            NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
        }

        radius: 16
        color: ShellState.glassEnabled ? "transparent" : Theme.bgSurfaceGlass
        border.color: ShellState.glassEnabled ? "transparent" : (
            WhatsAppService.status === "ready" ? Qt.alpha("#25D366", 0.35) :
            (WhatsAppService.status === "qr_ready" ? Qt.alpha(Theme.accentCyan, 0.4) :
            (WhatsAppService.status === "disconnected" ? Qt.alpha(Theme.accentAmber, 0.4) : Theme.borderDim))
        )
        border.width: ShellState.glassEnabled ? 0 : 1

        LiquidGlassSurface {
            radius: 16
            visible: ShellState.glassEnabled
            accentColor: "#25D366"
            showShadow: true
        }
        clip: true

        // Inner layout
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 12

            // ── HEADER ────────────────────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                // WhatsApp Brand Badge
                Rectangle {
                    width: 38
                    height: 38
                    radius: 10
                    color: Qt.alpha("#25D366", 0.15)
                    border.color: "#25D366"
                    border.width: 1

                    Icon {
                        anchors.centerIn: parent
                        name: "whatsapp"
                        size: 20
                        color: "#25D366"
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    RowLayout {
                        spacing: 8
                        Text {
                            text: "WhatsApp"
                            font.family: Theme.fontFamily
                            font.pixelSize: 15
                            font.bold: true
                            color: Theme.textPrimary
                        }

                        // Connection Status Pill
                        Rectangle {
                            height: 18
                            implicitWidth: statusText.implicitWidth + 14
                            radius: 9
                            color: {
                                if (WhatsAppService.status === "ready") return Qt.alpha("#25D366", 0.18);
                                if (WhatsAppService.status === "qr_ready") return Qt.alpha(Theme.accentCyan, 0.2);
                                if (WhatsAppService.status === "disconnected") return Qt.alpha(Theme.accentAmber, 0.2);
                                if (WhatsAppService.status === "offline") return Qt.alpha(Theme.accentRose, 0.2);
                                return Qt.alpha(Theme.textMuted, 0.2);
                            }
                            border.color: {
                                if (WhatsAppService.status === "ready") return "#25D366";
                                if (WhatsAppService.status === "qr_ready") return Theme.accentCyan;
                                if (WhatsAppService.status === "disconnected") return Theme.accentAmber;
                                if (WhatsAppService.status === "offline") return Theme.accentRose;
                                return Theme.borderDim;
                            }
                            border.width: 1

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 4

                                Rectangle {
                                    width: 5
                                    height: 5
                                    radius: 2.5
                                    color: {
                                        if (WhatsAppService.status === "ready") return "#25D366";
                                        if (WhatsAppService.status === "qr_ready") return Theme.accentCyan;
                                        if (WhatsAppService.status === "disconnected") return Theme.accentAmber;
                                        return Theme.accentRose;
                                    }
                                }

                                Text {
                                    id: statusText
                                    text: {
                                        if (WhatsAppService.status === "ready") return "ONLINE";
                                        if (WhatsAppService.status === "qr_ready") return "QR SCAN";
                                        if (WhatsAppService.status === "reconnecting") return "CONNECTING";
                                        if (WhatsAppService.status === "disconnecting") return "STOPPING";
                                        if (WhatsAppService.status === "disconnected") return "INACTIVE";
                                        if (WhatsAppService.status === "offline") return "OFFLINE";
                                        return "CHECKING";
                                    }
                                    font.family: Theme.fontMono
                                    font.pixelSize: 9
                                    font.bold: true
                                    color: {
                                        if (WhatsAppService.status === "ready") return "#25D366";
                                        if (WhatsAppService.status === "qr_ready") return Theme.accentCyan;
                                        if (WhatsAppService.status === "disconnected") return Theme.accentAmber;
                                        return Theme.accentRose;
                                    }
                                }
                            }
                        }
                    }

                    Text {
                        text: WhatsAppService.status === "ready" 
                            ? (WhatsAppService.userName + " (" + (WhatsAppService.userPhone || "+91 9448638474") + ")")
                            : "OpenWA Gateway • localhost:2785"
                        font.family: Theme.fontMono
                        font.pixelSize: 10
                        color: Theme.textMuted
                        elide: Text.ElideRight
                    }
                }

                // Header Action Buttons
                Row {
                    spacing: 6

                    // Web App Shortcut Button
                    Rectangle {
                        width: 28
                        height: 28
                        radius: 6
                        color: webMouse.containsMouse ? Theme.bgHover : Theme.bgPill
                        border.color: Theme.borderDim
                        border.width: 1

                        Icon {
                            anchors.centerIn: parent
                            name: "globe"
                            size: 13
                            color: webMouse.containsMouse ? "#25D366" : Theme.textSecondary
                        }

                        MouseArea {
                            id: webMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: WhatsAppService.openWeb()
                        }
                    }

                    // Disconnect Session Button (only when ready)
                    Rectangle {
                        width: 28
                        height: 28
                        radius: 6
                        visible: WhatsAppService.status === "ready" || WhatsAppService.status === "disconnecting"
                        color: dcMouse.containsMouse ? Qt.alpha(Theme.accentAmber, 0.25) : Theme.bgPill
                        border.color: dcMouse.containsMouse ? Theme.accentAmber : Theme.borderDim
                        border.width: 1

                        ToolTip.visible: dcMouse.containsMouse
                        ToolTip.text: "Disconnect WhatsApp Session\n(Can reconnect without QR)"
                        ToolTip.delay: 600

                        Icon {
                            anchors.centerIn: parent
                            name: WhatsAppService.status === "disconnecting" ? "loader" : "power"
                            size: 13
                            color: dcMouse.containsMouse ? Theme.accentAmber : Theme.textSecondary
                        }

                        MouseArea {
                            id: dcMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            enabled: WhatsAppService.status !== "disconnecting"
                            onClicked: WhatsAppService.disconnectSession()
                        }
                    }

                    // Refresh Button
                    Rectangle {
                        width: 28
                        height: 28
                        radius: 6
                        color: refMouse.containsMouse ? Theme.bgHover : Theme.bgPill
                        border.color: Theme.borderDim
                        border.width: 1

                        Icon {
                            anchors.centerIn: parent
                            name: "refresh-cw"
                            size: 13
                            color: refMouse.containsMouse ? Theme.textPrimary : Theme.textSecondary
                        }

                        MouseArea {
                            id: refMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: WhatsAppService.refresh()
                        }
                    }

                    // Close Button
                    Rectangle {
                        width: 28
                        height: 28
                        radius: 6
                        color: closeMouse.containsMouse ? Theme.accentRose : Theme.bgPill
                        border.color: Theme.borderDim
                        border.width: 1

                        Icon {
                            anchors.centerIn: parent
                            name: "x"
                            size: 13
                            color: closeMouse.containsMouse ? "#FFFFFF" : Theme.textSecondary
                        }

                        MouseArea {
                            id: closeMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: ShellState.whatsappOpen = false
                        }
                    }
                }
            }

            // Divider
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Theme.borderDim
            }

            // ── BODY: CONDITIONAL ON STATUS ───────────────────────────────────

            // CASE 1: ONLINE / READY WITH LIVE CHATS
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 8
                visible: WhatsAppService.status === "ready"

                // Search Bar
                Rectangle {
                    Layout.fillWidth: true
                    height: 32
                    radius: 8
                    color: Theme.bgPill
                    border.color: searchInput.activeFocus ? "#25D366" : Theme.borderDim
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        spacing: 6

                        Icon {
                            name: "search"
                            size: 13
                            color: searchInput.activeFocus ? "#25D366" : Theme.textMuted
                        }

                        TextInput {
                            id: searchInput
                            Layout.fillWidth: true
                            verticalAlignment: TextInput.AlignVCenter
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                            color: Theme.textPrimary
                            text: waWindow.searchFilter
                            onTextChanged: waWindow.searchFilter = text

                            Text {
                                visible: !searchInput.text && !searchInput.activeFocus
                                text: "Search chats or contacts..."
                                font.family: Theme.fontFamily
                                font.pixelSize: 11
                                color: Theme.textMuted
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        Icon {
                            visible: searchInput.text.length > 0
                            name: "x"
                            size: 12
                            color: Theme.textMuted
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: searchInput.text = ""
                            }
                        }
                    }
                }

                // Filter Tabs (All, Unread, Groups, Direct)
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Repeater {
                        model: [
                            { id: "all", label: "All Chats" },
                            { id: "unread", label: "Unread" + (WhatsAppService.unreadCount > 0 ? " (" + WhatsAppService.unreadCount + ")" : "") },
                            { id: "direct", label: "Direct" },
                            { id: "groups", label: "Groups" }
                        ]

                        Rectangle {
                            Layout.fillWidth: true
                            height: 24
                            radius: 6
                            readonly property bool isCur: waWindow.activeTab === modelData.id
                            color: isCur ? Qt.alpha("#25D366", 0.22) : (tabM.containsMouse ? Theme.bgHover : Theme.bgPill)
                            border.color: isCur ? "#25D366" : Theme.borderDim
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: modelData.label
                                font.family: Theme.fontFamily
                                font.pixelSize: 10
                                font.bold: isCur
                                color: isCur ? "#25D366" : Theme.textSecondary
                            }

                            MouseArea {
                                id: tabM
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: waWindow.activeTab = modelData.id
                            }
                        }
                    }
                }

                // Chats List View
                ListView {
                    id: chatListView
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    spacing: 6
                    boundsBehavior: Flickable.StopAtBounds

                    ScrollBar.vertical: ScrollBar {
                        active: chatListView.moving || chatListView.flicking
                        policy: ScrollBar.AsNeeded
                    }

                    model: {
                        let list = WhatsAppService.chats || [];
                        const q = waWindow.searchFilter.toLowerCase().trim();
                        if (q.length > 0) {
                            list = list.filter(c => (c.name || "").toLowerCase().includes(q) || (c.lastMessage || "").toLowerCase().includes(q));
                        }
                        if (waWindow.activeTab === "unread") {
                            list = list.filter(c => (c.unreadCount || 0) > 0);
                        } else if (waWindow.activeTab === "groups") {
                            list = list.filter(c => Boolean(c.isGroup));
                        } else if (waWindow.activeTab === "direct") {
                            list = list.filter(c => !Boolean(c.isGroup));
                        }
                        return list;
                    }

                    delegate: Rectangle {
                        width: chatListView.width
                        height: 54
                        radius: 10
                        color: chatMouse.containsMouse ? Theme.bgHover : Theme.bgPill
                        border.color: modelData.unreadCount > 0 ? Qt.alpha("#25D366", 0.35) : (chatMouse.containsMouse ? Theme.borderDim : "transparent")
                        border.width: 1

                        Behavior on color { ColorAnimation { duration: 120 } }

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 10

                            // Avatar Circle
                            Rectangle {
                                width: 36
                                height: 36
                                radius: 18
                                color: modelData.isGroup ? Qt.alpha(Theme.accentSky, 0.18) : Qt.alpha("#25D366", 0.18)
                                border.color: modelData.isGroup ? Theme.accentSky : "#25D366"
                                border.width: 1

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.isGroup ? "👥" : (modelData.name ? modelData.name.charAt(0).toUpperCase() : "👤")
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 13
                                    font.bold: true
                                    color: modelData.isGroup ? Theme.accentSky : "#25D366"
                                }
                            }

                            // Chat details
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 4

                                    Text {
                                        Layout.fillWidth: true
                                        text: modelData.name || "Unknown"
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 12
                                        font.bold: modelData.unreadCount > 0
                                        color: modelData.unreadCount > 0 ? Theme.textPrimary : Theme.textPrimary
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        text: modelData.timeStr || ""
                                        font.family: Theme.fontMono
                                        font.pixelSize: 9
                                        color: modelData.unreadCount > 0 ? "#25D366" : Theme.textMuted
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 4

                                    Text {
                                        Layout.fillWidth: true
                                        text: modelData.lastMessage || "Tap to chat"
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 10
                                        font.italic: !modelData.lastMessage
                                        color: modelData.unreadCount > 0 ? Theme.textSecondary : Theme.textMuted
                                        elide: Text.ElideRight
                                    }

                                    // Unread badge
                                    Rectangle {
                                        visible: (modelData.unreadCount || 0) > 0
                                        height: 16
                                        implicitWidth: Math.max(16, unreadTxt.implicitWidth + 8)
                                        radius: 8
                                        color: "#25D366"

                                        Text {
                                            id: unreadTxt
                                            anchors.centerIn: parent
                                            text: modelData.unreadCount
                                            font.family: Theme.fontMono
                                            font.pixelSize: 9
                                            font.bold: true
                                            color: "#080B11"
                                        }
                                    }
                                }
                            }
                        }

                        MouseArea {
                            id: chatMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                WhatsAppService.openWeb();
                            }
                        }
                    }

                    // Empty search placeholder
                    Item {
                        anchors.centerIn: parent
                        visible: chatListView.count === 0
                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 6

                            Icon {
                                Layout.alignment: Qt.AlignHCenter
                                name: "message-square"
                                size: 28
                                color: Theme.textMuted
                            }

                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: waWindow.searchFilter ? "No conversations found" : "No recent chats"
                                font.family: Theme.fontFamily
                                font.pixelSize: 12
                                color: Theme.textMuted
                            }
                        }
                    }
                }
            }

            // ── FALLBACK 1: SESSION DISCONNECTED / STOPPED ────────────────────
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 14
                visible: WhatsAppService.status === "disconnected" || WhatsAppService.status === "stopped" || WhatsAppService.status === "reconnecting"

                Item { Layout.fillHeight: true }

                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    width: 56
                    height: 56
                    radius: 28
                    color: Qt.alpha(Theme.accentAmber, 0.15)
                    border.color: Theme.accentAmber
                    border.width: 1.5

                    Icon {
                        anchors.centerIn: parent
                        name: "alert-triangle"
                        size: 26
                        color: Theme.accentAmber
                    }
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: WhatsAppService.status === "reconnecting" ? "Reconnecting Session..." : "WhatsApp Session Inactive"
                    font.family: Theme.fontFamily
                    font.pixelSize: 15
                    font.bold: true
                    color: Theme.textPrimary
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: 320
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                    text: WhatsAppService.status === "reconnecting"
                        ? "Initializing whatsapp-web.js engine and restoring session credentials..."
                        : "Session 'default' is currently disconnected or closed. Click below to reconnect instantly."
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    color: Theme.textSecondary
                }

                // 1-Click Reconnect Action Button
                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: 220
                    height: 38
                    radius: 10
                    color: recMouse.containsMouse ? Qt.lighter("#25D366", 1.1) : "#25D366"
                    border.color: "#25D366"
                    border.width: 1

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 8

                        Icon {
                            name: "zap"
                            size: 15
                            color: "#080B11"
                        }

                        Text {
                            text: WhatsAppService.status === "reconnecting" ? "Reconnecting..." : "Reconnect Session"
                            font.family: Theme.fontFamily
                            font.pixelSize: 12
                            font.bold: true
                            color: "#080B11"
                        }
                    }

                    MouseArea {
                        id: recMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        enabled: WhatsAppService.status !== "reconnecting"
                        onClicked: WhatsAppService.reconnectSession()
                    }
                }

                // Secondary Dashboard link
                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: 220
                    height: 32
                    radius: 8
                    color: dashMouse.containsMouse ? Theme.bgHover : Theme.bgPill
                    border.color: Theme.borderDim
                    border.width: 1

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 6

                        Icon {
                            name: "globe"
                            size: 12
                            color: Theme.textSecondary
                        }

                        Text {
                            text: "Open Dashboard (2785)"
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                            color: Theme.textSecondary
                        }
                    }

                    MouseArea {
                        id: dashMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: WhatsAppService.openDashboard()
                    }
                }

                Item { Layout.fillHeight: true }
            }

            // ── FALLBACK 2: QR CODE REQUIRED ──────────────────────────────────
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 12
                visible: WhatsAppService.status === "qr_ready"

                Item { Layout.fillHeight: true }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Scan QR to Authenticate"
                    font.family: Theme.fontFamily
                    font.pixelSize: 15
                    font.bold: true
                    color: Theme.textPrimary
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: 320
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                    text: "Open WhatsApp on your phone → Settings → Linked Devices → Link a Device, then scan:"
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    color: Theme.textSecondary
                }

                // QR Image Frame
                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    width: 220
                    height: 220
                    radius: 12
                    color: "#FFFFFF"
                    border.color: Theme.accentCyan
                    border.width: 2
                    clip: true

                    Image {
                        anchors.fill: parent
                        anchors.margins: 10
                        fillMode: Image.PreserveAspectFit
                        source: "file://" + WhatsAppService.qrPath
                        cache: false
                    }
                }

                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: 160
                    height: 32
                    radius: 8
                    color: qrRefMouse.containsMouse ? Theme.bgHover : Theme.bgPill
                    border.color: Theme.accentCyan
                    border.width: 1

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 6

                        Icon {
                            name: "refresh-cw"
                            size: 12
                            color: Theme.accentCyan
                        }

                        Text {
                            text: "Refresh QR"
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                            font.bold: true
                            color: Theme.accentCyan
                        }
                    }

                    MouseArea {
                        id: qrRefMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: WhatsAppService.refresh()
                    }
                }

                Item { Layout.fillHeight: true }
            }

            // ── FALLBACK 3: GATEWAY OFFLINE (CONTAINER STOPPED) ────────────────
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 14
                visible: WhatsAppService.status === "offline" || WhatsAppService.status === "error"

                Item { Layout.fillHeight: true }

                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    width: 56
                    height: 56
                    radius: 28
                    color: Qt.alpha(Theme.accentRose, 0.15)
                    border.color: Theme.accentRose
                    border.width: 1.5

                    Icon {
                        anchors.centerIn: parent
                        name: "alert-circle"
                        size: 26
                        color: Theme.accentRose
                    }
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "OpenWA Gateway Offline"
                    font.family: Theme.fontFamily
                    font.pixelSize: 15
                    font.bold: true
                    color: Theme.textPrimary
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: 320
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                    text: "The OpenWA Docker API service is not running on localhost:2785. Click below to start the container."
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    color: Theme.textSecondary
                }

                // 1-Click Launch Container Action
                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: 220
                    height: 38
                    radius: 10
                    color: launchMouse.containsMouse ? Qt.lighter(Theme.accentSky, 1.1) : Theme.accentSky
                    border.color: Theme.accentSky
                    border.width: 1

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 8

                        Icon {
                            name: "play"
                            size: 14
                            color: "#080B11"
                        }

                        Text {
                            text: WhatsAppService.loading ? "Starting Container..." : "Start OpenWA Container"
                            font.family: Theme.fontFamily
                            font.pixelSize: 12
                            font.bold: true
                            color: "#080B11"
                        }
                    }

                    MouseArea {
                        id: launchMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        enabled: !WhatsAppService.loading
                        onClicked: WhatsAppService.startGateway()
                    }
                }

                Item { Layout.fillHeight: true }
            }

            // ── FOOTER ────────────────────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                Icon {
                    name: "clock"
                    size: 10
                    color: Theme.textMuted
                }

                Text {
                    text: WhatsAppService.lastUpdated ? ("Updated " + WhatsAppService.lastUpdated) : "Live syncing"
                    font.family: Theme.fontMono
                    font.pixelSize: 9
                    color: Theme.textMuted
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: WhatsAppService.status === "ready" 
                        ? (WhatsAppService.chats.length + " active chats")
                        : "OpenWA 2785"
                    font.family: Theme.fontMono
                    font.pixelSize: 9
                    color: Theme.textMuted
                }
            }
        }
    }
}
