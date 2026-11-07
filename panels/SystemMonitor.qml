import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import "../theme"
import "../services"
import "../components"

PanelWindow {
    id: monitorWindow

    visible: ShellState.systemMonitorOpen
    color: "transparent"

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "quickshell:systemmonitor"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: ShellState.systemMonitorOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    property string activeTab: "ram" // "ram", "groups", "cpu", "swap"
    property string confirmKillPid: ""

    onVisibleChanged: {
        if (visible) {
            confirmKillPid = "";
            searchInput.text = "";
            activeTab = ShellState.systemMonitorInitialTab || "ram";
            SystemMonitorService.refresh();
            Qt.callLater(() => {
                searchInput.forceActiveFocus();
            });
        }
    }

    Connections {
        target: ShellState
        function onSystemMonitorInitialTabChanged() {
            if (ShellState.systemMonitorInitialTab) {
                monitorWindow.activeTab = ShellState.systemMonitorInitialTab;
            }
        }
    }

    // Dismiss on backdrop click
    MouseArea {
        anchors.fill: parent
        onClicked: {
            if (monitorWindow.confirmKillPid !== "") {
                monitorWindow.confirmKillPid = "";
            } else {
                ShellState.systemMonitorOpen = false;
            }
        }

        Rectangle {
            anchors.fill: parent
            color: "#000000"
            opacity: 0.45
            Behavior on opacity { NumberAnimation { duration: 180 } }
        }
    }

    // Main Modal Card anchored beneath top bar right island
    Rectangle {
        id: menuCard
        width: 620
        height: Math.min(740, monitorWindow.height - 70)
        anchors.top: parent.top
        anchors.topMargin: 54
        anchors.right: parent.right
        anchors.rightMargin: 16
        radius: Theme.cardRadius
        clip: true
        color: ShellState.glassEnabled ? "transparent" : Theme.bgModal
        border.color: ShellState.glassEnabled ? "transparent" : Theme.borderGlow
        border.width: ShellState.glassEnabled ? 0 : 1

        LiquidGlassSurface {
            radius: Theme.cardRadius
            visible: ShellState.glassEnabled
            accentColor: Theme.accentEmerald
            showShadow: true
        }

        // Consume internal clicks
        MouseArea {
            anchors.fill: parent
            onClicked: {
                if (monitorWindow.confirmKillPid !== "") {
                    monitorWindow.confirmKillPid = "";
                }
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 18
            spacing: 12

            // ── Header Row ───────────────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Rectangle {
                    width: 34
                    height: 34
                    radius: 8
                    color: Theme.bgCard
                    border.color: Theme.borderDim
                    border.width: 1

                    Icon {
                        anchors.centerIn: parent
                        name: "activity"
                        size: 18
                        color: Theme.accentSky
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    RowLayout {
                        spacing: 8
                        Text {
                            text: "System Resource Monitor"
                            font.family: Theme.fontFamily
                            font.pixelSize: 15
                            font.bold: true
                            color: Theme.textPrimary
                        }

                        Rectangle {
                            height: 18
                            radius: 9
                            implicitWidth: timeTxt.implicitWidth + 12
                            color: Theme.bgCard
                            border.color: Theme.borderDim
                            border.width: 1

                            Text {
                                id: timeTxt
                                anchors.centerIn: parent
                                text: SystemMonitorService.lastUpdated
                                font.family: Theme.fontMono
                                font.pixelSize: 10
                                color: Theme.textMuted
                            }
                        }
                    }

                    Text {
                        text: `${SystemMonitorService.cpu.cores} CPU Cores • ${(SystemMonitorService.ram.total_mb / 1024).toFixed(1)} GB Physical RAM`
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        color: Theme.textMuted
                    }
                }

                // Refresh Button
                Rectangle {
                    width: 30
                    height: 30
                    radius: 6
                    color: refreshMouse.containsMouse ? Theme.bgHover : Theme.bgCard
                    border.color: Theme.borderDim
                    border.width: 1

                    Icon {
                        anchors.centerIn: parent
                        name: "refresh-cw"
                        size: 14
                        color: SystemMonitorService.loading ? Theme.accentAmber : Theme.textSecondary
                        rotation: SystemMonitorService.loading ? 360 : 0
                        Behavior on rotation {
                            NumberAnimation { duration: 600 }
                        }
                    }

                    MouseArea {
                        id: refreshMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: SystemMonitorService.refresh()
                    }
                }

                // Close Button
                Rectangle {
                    width: 30
                    height: 30
                    radius: 6
                    color: closeMouse.containsMouse ? Theme.bgHover : Theme.bgCard
                    border.color: Theme.borderDim
                    border.width: 1

                    Icon {
                        anchors.centerIn: parent
                        name: "x"
                        size: 14
                        color: closeMouse.containsMouse ? Theme.accentRose : Theme.textMuted
                    }

                    MouseArea {
                        id: closeMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: ShellState.systemMonitorOpen = false
                    }
                }
            }

            // ── Telemetry Summary Cards ──────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                // RAM Card
                Rectangle {
                    Layout.fillWidth: true
                    height: 84
                    radius: 10
                    color: Theme.bgCard
                    border.color: monitorWindow.activeTab === "ram" ? Theme.accentSky : Theme.borderDim
                    border.width: monitorWindow.activeTab === "ram" ? 1.5 : 1

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 5

                        RowLayout {
                            Layout.fillWidth: true
                            Text {
                                text: "MEMORY (RAM)"
                                font.family: Theme.fontMono
                                font.pixelSize: 10
                                font.bold: true
                                color: Theme.textMuted
                            }
                            Item { Layout.fillWidth: true }
                            Text {
                                text: `${SystemMonitorService.ram.used_percent}%`
                                font.family: Theme.fontMono
                                font.pixelSize: 12
                                font.bold: true
                                color: SystemMonitorService.ram.used_percent > 85 ? Theme.accentRose : (SystemMonitorService.ram.used_percent > 70 ? Theme.accentAmber : Theme.accentSky)
                            }
                        }

                        // Multi-segment RAM Bar
                        Rectangle {
                            Layout.fillWidth: true
                            height: 6
                            radius: 3
                            color: Theme.bgSurface
                            clip: true

                            Row {
                                anchors.fill: parent
                                Rectangle {
                                    width: parent.width * Math.max(0, Math.min(1, (SystemMonitorService.ram.used_mb || 0) / (SystemMonitorService.ram.total_mb || 1)))
                                    height: parent.height
                                    color: SystemMonitorService.ram.used_percent > 85 ? Theme.accentRose : Theme.accentSky
                                }
                                Rectangle {
                                    width: parent.width * Math.max(0, Math.min(1, (SystemMonitorService.ram.cached_mb || 0) / (SystemMonitorService.ram.total_mb || 1)))
                                    height: parent.height
                                    color: Theme.accentAmber
                                    opacity: 0.7
                                }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Text {
                                text: `Used: ${(SystemMonitorService.ram.used_mb / 1024).toFixed(1)} GB`
                                font.family: Theme.fontMono
                                font.pixelSize: 10
                                color: Theme.textPrimary
                            }
                            Item { Layout.fillWidth: true }
                            Text {
                                text: `Avail: ${(SystemMonitorService.ram.avail_mb / 1024).toFixed(1)} GB`
                                font.family: Theme.fontMono
                                font.pixelSize: 10
                                color: Theme.accentEmerald
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: monitorWindow.activeTab = "ram"
                    }
                }

                // CPU Card
                Rectangle {
                    Layout.fillWidth: true
                    height: 84
                    radius: 10
                    color: Theme.bgCard
                    border.color: monitorWindow.activeTab === "cpu" ? Theme.accentSky : Theme.borderDim
                    border.width: monitorWindow.activeTab === "cpu" ? 1.5 : 1

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 5

                        RowLayout {
                            Layout.fillWidth: true
                            Text {
                                text: "CPU USAGE"
                                font.family: Theme.fontMono
                                font.pixelSize: 10
                                font.bold: true
                                color: Theme.textMuted
                            }
                            Item { Layout.fillWidth: true }
                            Text {
                                text: `${SystemMonitorService.cpu.percent}%`
                                font.family: Theme.fontMono
                                font.pixelSize: 12
                                font.bold: true
                                color: SystemMonitorService.cpu.percent > 80 ? Theme.accentRose : (SystemMonitorService.cpu.percent > 50 ? Theme.accentAmber : Theme.accentEmerald)
                            }
                        }

                        // CPU Bar
                        Rectangle {
                            Layout.fillWidth: true
                            height: 6
                            radius: 3
                            color: Theme.bgSurface
                            clip: true

                            Rectangle {
                                width: parent.width * Math.max(0, Math.min(1, (SystemMonitorService.cpu.percent || 0) / 100))
                                height: parent.height
                                color: SystemMonitorService.cpu.percent > 80 ? Theme.accentRose : (SystemMonitorService.cpu.percent > 50 ? Theme.accentAmber : Theme.accentEmerald)
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Text {
                                text: `Load: ${SystemMonitorService.cpu.load_1}`
                                font.family: Theme.fontMono
                                font.pixelSize: 10
                                color: Theme.textPrimary
                            }
                            Item { Layout.fillWidth: true }
                            Text {
                                text: `5m: ${SystemMonitorService.cpu.load_5}`
                                font.family: Theme.fontMono
                                font.pixelSize: 10
                                color: Theme.textMuted
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: monitorWindow.activeTab = "cpu"
                    }
                }

                // SWAP Card
                Rectangle {
                    Layout.fillWidth: true
                    height: 84
                    radius: 10
                    color: Theme.bgCard
                    border.color: monitorWindow.activeTab === "swap" ? Theme.accentSky : Theme.borderDim
                    border.width: monitorWindow.activeTab === "swap" ? 1.5 : 1

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 5

                        RowLayout {
                            Layout.fillWidth: true
                            Text {
                                text: "SWAP DISK"
                                font.family: Theme.fontMono
                                font.pixelSize: 10
                                font.bold: true
                                color: Theme.textMuted
                            }
                            Item { Layout.fillWidth: true }
                            Text {
                                text: `${SystemMonitorService.swap.used_percent}%`
                                font.family: Theme.fontMono
                                font.pixelSize: 12
                                font.bold: true
                                color: SystemMonitorService.swap.used_percent > 60 ? Theme.accentRose : (SystemMonitorService.swap.used_percent > 25 ? Theme.accentAmber : Theme.textSecondary)
                            }
                        }

                        // Swap Bar
                        Rectangle {
                            Layout.fillWidth: true
                            height: 6
                            radius: 3
                            color: Theme.bgSurface
                            clip: true

                            Rectangle {
                                width: parent.width * Math.max(0, Math.min(1, (SystemMonitorService.swap.used_mb || 0) / (SystemMonitorService.swap.total_mb || 1)))
                                height: parent.height
                                color: SystemMonitorService.swap.used_percent > 60 ? Theme.accentRose : Theme.accentAmber
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Text {
                                text: `Used: ${(SystemMonitorService.swap.used_mb / 1024).toFixed(1)} GB`
                                font.family: Theme.fontMono
                                font.pixelSize: 10
                                color: Theme.textPrimary
                            }
                            Item { Layout.fillWidth: true }
                            Text {
                                text: `Free: ${(SystemMonitorService.swap.free_mb / 1024).toFixed(1)} GB`
                                font.family: Theme.fontMono
                                font.pixelSize: 10
                                color: Theme.textMuted
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: monitorWindow.activeTab = "swap"
                    }
                }
            }

            // ── Navigation Tabs & Search Row ─────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                // Tab Pills Container
                Rectangle {
                    height: 32
                    radius: 8
                    color: Theme.bgCard
                    border.color: Theme.borderDim
                    border.width: 1
                    implicitWidth: tabsRow.implicitWidth + 8

                    RowLayout {
                        id: tabsRow
                        anchors.centerIn: parent
                        spacing: 4

                        // RAM Tab
                        Rectangle {
                            height: 24
                            radius: 6
                            implicitWidth: ramTabTxt.implicitWidth + 14
                            color: monitorWindow.activeTab === "ram" ? Theme.bgActive : "transparent"

                            Text {
                                id: ramTabTxt
                                anchors.centerIn: parent
                                text: "RAM"
                                font.family: Theme.fontFamily
                                font.pixelSize: 11
                                font.bold: monitorWindow.activeTab === "ram"
                                color: monitorWindow.activeTab === "ram" ? Theme.accentSky : Theme.textMuted
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: monitorWindow.activeTab = "ram"
                            }
                        }

                        // App Groups Tab
                        Rectangle {
                            height: 24
                            radius: 6
                            implicitWidth: grpTabTxt.implicitWidth + 14
                            color: monitorWindow.activeTab === "groups" ? Theme.bgActive : "transparent"

                            Text {
                                id: grpTabTxt
                                anchors.centerIn: parent
                                text: "App Groups"
                                font.family: Theme.fontFamily
                                font.pixelSize: 11
                                font.bold: monitorWindow.activeTab === "groups"
                                color: monitorWindow.activeTab === "groups" ? Theme.accentSky : Theme.textMuted
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: monitorWindow.activeTab = "groups"
                            }
                        }

                        // CPU Tab
                        Rectangle {
                            height: 24
                            radius: 6
                            implicitWidth: cpuTabTxt.implicitWidth + 14
                            color: monitorWindow.activeTab === "cpu" ? Theme.bgActive : "transparent"

                            Text {
                                id: cpuTabTxt
                                anchors.centerIn: parent
                                text: "CPU"
                                font.family: Theme.fontFamily
                                font.pixelSize: 11
                                font.bold: monitorWindow.activeTab === "cpu"
                                color: monitorWindow.activeTab === "cpu" ? Theme.accentSky : Theme.textMuted
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: monitorWindow.activeTab = "cpu"
                            }
                        }

                        // Swap Tab
                        Rectangle {
                            height: 24
                            radius: 6
                            implicitWidth: swpTabTxt.implicitWidth + 14
                            color: monitorWindow.activeTab === "swap" ? Theme.bgActive : "transparent"

                            Text {
                                id: swpTabTxt
                                anchors.centerIn: parent
                                text: "Swap"
                                font.family: Theme.fontFamily
                                font.pixelSize: 11
                                font.bold: monitorWindow.activeTab === "swap"
                                color: monitorWindow.activeTab === "swap" ? Theme.accentSky : Theme.textMuted
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: monitorWindow.activeTab = "swap"
                            }
                        }
                    }
                }

                // Search Box
                Rectangle {
                    Layout.fillWidth: true
                    height: 32
                    radius: 8
                    color: Theme.bgCard
                    border.color: searchInput.activeFocus ? Theme.borderActive : Theme.borderDim
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        spacing: 6

                        Icon {
                            name: "search"
                            size: 13
                            color: Theme.textMuted
                        }

                        TextInput {
                            id: searchInput
                            Layout.fillWidth: true
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                            color: Theme.textPrimary
                            clip: true
                            selectByMouse: true

                            Text {
                                text: "Filter processes or PIDs..."
                                font.family: Theme.fontFamily
                                font.pixelSize: 11
                                color: Theme.textMuted
                                opacity: 0.65
                                visible: searchInput.text.length === 0
                            }
                        }

                        Icon {
                            name: "x"
                            size: 12
                            color: Theme.textMuted
                            visible: searchInput.text.length > 0

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: searchInput.text = ""
                            }
                        }
                    }
                }
            }

            // ── Table Header (Fixed Anchored Columns) ────────────────────────
            Rectangle {
                Layout.fillWidth: true
                height: 28
                radius: 6
                color: Theme.bgSurface
                border.color: Theme.borderDim
                border.width: 1

                Item {
                    anchors.fill: parent

                    // Process / App Title
                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 46
                        anchors.right: cpuHdr.left
                        anchors.rightMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        text: monitorWindow.activeTab === "groups" ? "APPLICATION / CATEGORY" : "PROCESS & PID"
                        font.family: Theme.fontMono
                        font.pixelSize: 10
                        font.bold: true
                        color: Theme.textMuted
                        elide: Text.ElideRight
                    }

                    // CPU / Procs Header
                    Text {
                        id: cpuHdr
                        width: 55
                        anchors.right: ramHdr.left
                        anchors.rightMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        horizontalAlignment: Text.AlignRight
                        text: monitorWindow.activeTab === "groups" ? "PROCS" : "CPU"
                        font.family: Theme.fontMono
                        font.pixelSize: 10
                        font.bold: true
                        color: Theme.textMuted
                    }

                    // RAM Header
                    Text {
                        id: ramHdr
                        width: 80
                        anchors.right: swapHdr.left
                        anchors.rightMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        horizontalAlignment: Text.AlignRight
                        text: "RAM (RSS)"
                        font.family: Theme.fontMono
                        font.pixelSize: 10
                        font.bold: true
                        color: Theme.textMuted
                    }

                    // Swap Header
                    Text {
                        id: swapHdr
                        width: 70
                        anchors.right: actionHdrSpacer.left
                        anchors.rightMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        horizontalAlignment: Text.AlignRight
                        text: "SWAP"
                        font.family: Theme.fontMono
                        font.pixelSize: 10
                        font.bold: true
                        color: Theme.textMuted
                    }

                    // Action column spacer to perfectly match row kill button
                    Item {
                        id: actionHdrSpacer
                        width: 26
                        anchors.right: parent.right
                        anchors.rightMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }

            // ── List View Container (Fixed Anchored Row Delegate) ────────────
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 8
                color: Theme.bgCard
                border.color: Theme.borderDim
                border.width: 1
                clip: true

                ListView {
                    id: listView
                    anchors.fill: parent
                    anchors.margins: 4
                    spacing: 2
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    ScrollBar.vertical: ScrollBar {
                        active: listView.moving || listView.flicking
                        policy: ScrollBar.AsNeeded
                    }

                    model: {
                        const q = searchInput.text.toLowerCase().trim();
                        let rawList = [];

                        if (monitorWindow.activeTab === "groups") {
                            rawList = SystemMonitorService.groups || [];
                        } else if (monitorWindow.activeTab === "cpu") {
                            rawList = SystemMonitorService.topByCpu || [];
                        } else if (monitorWindow.activeTab === "swap") {
                            rawList = SystemMonitorService.topBySwap || [];
                        } else {
                            rawList = SystemMonitorService.topByMem || [];
                        }

                        if (!q) return rawList;

                        return rawList.filter(item => {
                            const name = (item.name || "").toLowerCase();
                            const cat = (item.category || "").toLowerCase();
                            const cmd = (item.command || "").toLowerCase();
                            const pidStr = String(item.pid || "");
                            return name.includes(q) || cat.includes(q) || cmd.includes(q) || pidStr.includes(q);
                        });
                    }

                    delegate: Rectangle {
                        id: rowDelegate
                        width: listView.width
                        height: 42
                        radius: 6
                        color: rowMouse.containsMouse ? Theme.bgHover : "transparent"
                        border.color: rowMouse.containsMouse ? Theme.borderDim : "transparent"
                        border.width: 1

                        readonly property bool isGroup: monitorWindow.activeTab === "groups"
                        readonly property bool isConfirmingKill: monitorWindow.confirmKillPid === String(modelData.pid)

                        Item {
                            anchors.fill: parent

                            // 1. Icon Container
                            Rectangle {
                                id: rowIconBox
                                width: 26
                                height: 26
                                radius: 6
                                anchors.left: parent.left
                                anchors.leftMargin: 10
                                anchors.verticalCenter: parent.verticalCenter
                                color: Theme.bgSurface
                                border.color: Theme.borderDim
                                border.width: 1

                                Icon {
                                    anchors.centerIn: parent
                                    name: modelData.icon || "activity"
                                    size: 14
                                    color: Theme.accentSky
                                }
                            }

                            // 2. Name & PID / Subtitle (fills between Icon and CPU column)
                            Item {
                                id: nameBox
                                anchors.left: rowIconBox.right
                                anchors.leftMargin: 10
                                anchors.right: cpuVal.left
                                anchors.rightMargin: 12
                                anchors.verticalCenter: parent.verticalCenter
                                height: 32

                                Column {
                                    anchors.fill: parent
                                    spacing: 2

                                    // Line 1: Title + PID
                                    Row {
                                        spacing: 6
                                        width: parent.width

                                        Text {
                                            text: modelData.name || "Unknown"
                                            font.family: Theme.fontFamily
                                            font.pixelSize: 12
                                            font.bold: true
                                            color: Theme.textPrimary
                                            elide: Text.ElideRight
                                            width: Math.min(implicitWidth, rowDelegate.isGroup ? parent.width : parent.width - 65)
                                        }

                                        Text {
                                            text: rowDelegate.isGroup ? "" : `PID ${modelData.pid}`
                                            font.family: Theme.fontMono
                                            font.pixelSize: 10
                                            color: Theme.textMuted
                                            visible: !rowDelegate.isGroup
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                    }

                                    // Line 2: Subtitle / Command path / Percent of RAM
                                    Text {
                                        width: parent.width
                                        text: rowDelegate.isGroup ? `${modelData.percent_ram}% of Total RAM` : (modelData.command || modelData.category || "")
                                        font.family: Theme.fontMono
                                        font.pixelSize: 10
                                        color: Theme.textMuted
                                        elide: Text.ElideRight
                                    }
                                }
                            }

                            // 3. CPU / Procs Value (Fixed width 55, right-aligned)
                            Text {
                                id: cpuVal
                                width: 55
                                anchors.right: ramVal.left
                                anchors.rightMargin: 12
                                anchors.verticalCenter: parent.verticalCenter
                                horizontalAlignment: Text.AlignRight
                                text: rowDelegate.isGroup ? `${modelData.count}` : `${(modelData.cpu || 0).toFixed(1)}%`
                                font.family: Theme.fontMono
                                font.pixelSize: 11
                                font.bold: !rowDelegate.isGroup && modelData.cpu > 20
                                color: rowDelegate.isGroup ? Theme.textSecondary : (modelData.cpu > 50 ? Theme.accentRose : (modelData.cpu > 20 ? Theme.accentAmber : Theme.textSecondary))
                            }

                            // 4. RAM Value (Fixed width 80, right-aligned)
                            Text {
                                id: ramVal
                                width: 80
                                anchors.right: swapVal.left
                                anchors.rightMargin: 12
                                anchors.verticalCenter: parent.verticalCenter
                                horizontalAlignment: Text.AlignRight
                                text: `${(modelData.rss_mb || 0).toFixed(1)} MB`
                                font.family: Theme.fontMono
                                font.pixelSize: 11
                                font.bold: modelData.rss_mb > 500
                                color: modelData.rss_mb > 1000 ? Theme.accentRose : (modelData.rss_mb > 400 ? Theme.accentAmber : Theme.textPrimary)
                            }

                            // 5. Swap Value (Fixed width 70, right-aligned)
                            Text {
                                id: swapVal
                                width: 70
                                anchors.right: actionBox.left
                                anchors.rightMargin: 12
                                anchors.verticalCenter: parent.verticalCenter
                                horizontalAlignment: Text.AlignRight
                                text: `${(modelData.swap_mb || 0).toFixed(1)} MB`
                                font.family: Theme.fontMono
                                font.pixelSize: 11
                                font.bold: modelData.swap_mb > 100
                                color: modelData.swap_mb > 100 ? Theme.accentRose : (modelData.swap_mb > 0 ? Theme.accentAmber : Theme.textMuted)
                            }

                            // 6. Action Box (Kill button, fixed width 26, right margin 10)
                            Item {
                                id: actionBox
                                width: 26
                                height: 26
                                anchors.right: parent.right
                                anchors.rightMargin: 10
                                anchors.verticalCenter: parent.verticalCenter

                                Rectangle {
                                    anchors.fill: parent
                                    radius: 4
                                    visible: !rowDelegate.isGroup
                                    color: rowDelegate.isConfirmingKill ? Theme.accentRose : (killMouse.containsMouse ? Theme.bgSurface : "transparent")
                                    border.color: rowDelegate.isConfirmingKill ? Theme.accentRose : (killMouse.containsMouse ? Theme.borderDim : "transparent")
                                    border.width: 1

                                    Icon {
                                        anchors.centerIn: parent
                                        name: rowDelegate.isConfirmingKill ? "alert-triangle" : "x"
                                        size: 12
                                        color: rowDelegate.isConfirmingKill ? "#FFFFFF" : (killMouse.containsMouse ? Theme.accentRose : Theme.textMuted)
                                    }

                                    MouseArea {
                                        id: killMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (rowDelegate.isConfirmingKill) {
                                                SystemMonitorService.killProcess(modelData.pid, true);
                                                monitorWindow.confirmKillPid = "";
                                            } else {
                                                monitorWindow.confirmKillPid = String(modelData.pid);
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        MouseArea {
                            id: rowMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            acceptedButtons: Qt.NoButton
                        }
                    }
                }
            }

            // ── Footer Action Bar ────────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                // Drop Page Cache Button
                Rectangle {
                    height: 28
                    radius: 6
                    implicitWidth: dropCacheRow.implicitWidth + 14
                    color: cacheMouse.containsMouse ? Theme.bgHover : Theme.bgCard
                    border.color: Theme.borderDim
                    border.width: 1

                    RowLayout {
                        id: dropCacheRow
                        anchors.centerIn: parent
                        spacing: 6

                        Icon {
                            name: "trash-2"
                            size: 12
                            color: Theme.accentAmber
                        }

                        Text {
                            text: "Drop Caches"
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                            color: Theme.textSecondary
                        }
                    }

                    MouseArea {
                        id: cacheMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: SystemMonitorService.dropCaches()
                    }
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: monitorWindow.confirmKillPid !== "" ? `Click again on PID ${monitorWindow.confirmKillPid} to terminate` : "Click process '✕' to terminate"
                    font.family: Theme.fontMono
                    font.pixelSize: 10
                    color: monitorWindow.confirmKillPid !== "" ? Theme.accentRose : Theme.textMuted
                }
            }
        }
    }
}
