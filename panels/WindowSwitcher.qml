import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import "../theme"
import "../services"
import "../components"

PanelWindow {
    id: switcherWindow

    visible: ShellState.windowSwitcherOpen
    color: "transparent"

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "quickshell:windowswitcher"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: ShellState.windowSwitcherOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    property string activeWorkspaceFilter: "all"
    property int selectedIndex: 0

    onVisibleChanged: {
        if (visible) {
            searchInput.text = "";
            activeWorkspaceFilter = "all";
            selectedIndex = 0;
            WindowService.refresh();
            Qt.callLater(() => searchInput.forceActiveFocus());
        }
    }

    function getWorkspaces() {
        const list = WindowService.windows || [];
        const wss = ["all"];
        for (let i = 0; i < list.length; i++) {
            const ws = String(list[i].workspace_id || "1");
            if (!wss.includes(ws)) wss.push(ws);
        }
        return wss;
    }

    function getFilteredWindows() {
        const list = WindowService.windows || [];
        const q = searchInput.text.toLowerCase().trim();
        return list.filter(w => {
            if (activeWorkspaceFilter !== "all" && String(w.workspace_id) !== activeWorkspaceFilter) {
                return false;
            }
            if (q.length > 0) {
                const title = (w.title || "").toLowerCase();
                const cls = (w.class || "").toLowerCase();
                const ws = String(w.workspace_id || "");
                return title.includes(q) || cls.includes(q) || ws.includes(q);
            }
            return true;
        });
    }

    readonly property var filteredWindows: {
        const _dummy = WindowService.windows;
        const _q = searchInput.text;
        const _ws = activeWorkspaceFilter;
        return switcherWindow.getFilteredWindows();
    }

    function jumpToSelected() {
        const list = switcherWindow.filteredWindows;
        if (list && list.length > 0) {
            const idx = Math.max(0, Math.min(selectedIndex, list.length - 1));
            const target = list[idx];
            if (target && target.address) {
                ShellState.windowSwitcherOpen = false;
                WindowService.focusWindow(target.address);
            }
        }
    }

    function closeSelected() {
        const list = switcherWindow.filteredWindows;
        if (list && list.length > 0) {
            const idx = Math.max(0, Math.min(selectedIndex, list.length - 1));
            const target = list[idx];
            if (target && target.address) {
                WindowService.closeWindow(target.address);
            }
        }
    }

    // ── Backdrop Dimmer ─────────────────────────────────────────────────────
    MouseArea {
        anchors.fill: parent
        onClicked: ShellState.windowSwitcherOpen = false

        Rectangle {
            anchors.fill: parent
            color: "#000000"
            opacity: 0.72
        }
    }

    // ── Main Glassmorphic Modal Card ────────────────────────────────────────
    Rectangle {
        id: card
        width: 960
        height: 620
        anchors.centerIn: parent
        radius: 20
        color: ShellState.glassEnabled ? "transparent" : Theme.bgModal
        border.color: ShellState.glassEnabled ? "transparent" : Theme.borderGlow
        border.width: ShellState.glassEnabled ? 0 : 1

        LiquidGlassSurface {
            radius: 20
            visible: ShellState.glassEnabled
            accentColor: Theme.accentCyan
            showShadow: true
        }
        clip: true

        focus: true

        Keys.onEscapePressed: ShellState.windowSwitcherOpen = false
        Keys.onReturnPressed: jumpToSelected()
        Keys.onTabPressed: event => {
            event.accepted = true;
            if (filteredWindows.length > 0) {
                selectedIndex = (selectedIndex + 1) % filteredWindows.length;
            }
        }
        Keys.onBacktabPressed: event => {
            event.accepted = true;
            if (filteredWindows.length > 0) {
                selectedIndex = (selectedIndex - 1 + filteredWindows.length) % filteredWindows.length;
            }
        }
        Keys.onRightPressed: {
            if (filteredWindows.length > 0) {
                selectedIndex = (selectedIndex + 1) % filteredWindows.length;
            }
        }
        Keys.onLeftPressed: {
            if (filteredWindows.length > 0) {
                selectedIndex = (selectedIndex - 1 + filteredWindows.length) % filteredWindows.length;
            }
        }
        Keys.onDownPressed: {
            if (filteredWindows.length > 0) {
                selectedIndex = Math.min(filteredWindows.length - 1, selectedIndex + 3);
            }
        }
        Keys.onUpPressed: {
            if (filteredWindows.length > 0) {
                selectedIndex = Math.max(0, selectedIndex - 3);
            }
        }
        Keys.onDeletePressed: closeSelected()

        MouseArea {
            anchors.fill: parent
            onClicked: {}
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 18
            spacing: 12

            // ── Header Bar ──────────────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                // Icon Box
                Rectangle {
                    width: 40
                    height: 40
                    radius: 12
                    color: ShellState.plasticEnabled ? "transparent" : Qt.rgba(Theme.accentSky.r, Theme.accentSky.g, Theme.accentSky.b, 0.15)
                    border.color: ShellState.plasticEnabled ? "transparent" : Theme.accentSky
                    border.width: ShellState.plasticEnabled ? 0 : 1

                    LiquidGlassSurface {
                        radius: 12
                        visible: ShellState.plasticEnabled
                        accentColor: Theme.accentSky
                        showShadow: false
                    }

                    Icon {
                        anchors.centerIn: parent
                        name: "layers"
                        size: 20
                        color: Theme.accentSky
                    }
                }

                // Title & Subtitle
                ColumnLayout {
                    spacing: 2
                    Layout.fillWidth: true

                    RowLayout {
                        spacing: 8

                        Text {
                            text: "MISSION CONTROL & WINDOW SWITCHER"
                            font.family: Theme.fontFamily
                            font.pixelSize: 14
                            font.bold: true
                            color: Theme.textPrimary
                        }

                        Rectangle {
                            height: 18
                            implicitWidth: winBadgeText.implicitWidth + 10
                            radius: 9
                            color: ShellState.plasticEnabled ? "transparent" : Qt.rgba(Theme.accentSky.r, Theme.accentSky.g, Theme.accentSky.b, 0.15)
                            border.color: ShellState.plasticEnabled ? "transparent" : Theme.accentSky
                            border.width: ShellState.plasticEnabled ? 0 : 1

                            LiquidGlassSurface {
                                radius: 9
                                visible: ShellState.plasticEnabled
                                accentColor: Theme.accentSky
                                showShadow: false
                            }

                            Text {
                                id: winBadgeText
                                anchors.centerIn: parent
                                text: "SUPER + TAB"
                                font.family: Theme.fontMono
                                font.pixelSize: 8
                                font.bold: true
                                color: Theme.accentSky
                            }
                        }
                    }

                    Text {
                        text: (WindowService.windows.length || 0) + " open application windows across your monitors"
                        font.family: Theme.fontMono
                        font.pixelSize: 9
                        color: Theme.textMuted
                    }
                }

                // Keyboard shortcuts hint pill
                Rectangle {
                    height: 26
                    implicitWidth: hintRow.implicitWidth + 16
                    radius: 13
                    color: ShellState.plasticEnabled ? "transparent" : Theme.bgPill
                    border.color: ShellState.plasticEnabled ? "transparent" : Theme.borderDim
                    border.width: ShellState.plasticEnabled ? 0 : 1

                    LiquidGlassSurface {
                        radius: 13
                        visible: ShellState.plasticEnabled
                        accentColor: Theme.borderDim
                        showShadow: false
                    }

                    RowLayout {
                        id: hintRow
                        anchors.centerIn: parent
                        spacing: 6

                        Text {
                            text: "⌨ Tab / ↑↓ to cycle  •  Enter to focus  •  Del to close"
                            font.family: Theme.fontMono
                            font.pixelSize: 8
                            color: Theme.textSecondary
                        }
                    }
                }

                // Refresh Button
                Rectangle {
                    width: 28
                    height: 28
                    radius: 8
                    color: ShellState.plasticEnabled ? "transparent" : (refreshWinMouse.containsMouse ? Theme.bgHover : Theme.bgPill)
                    border.color: ShellState.plasticEnabled ? "transparent" : Theme.borderDim
                    border.width: ShellState.plasticEnabled ? 0 : 1

                    LiquidGlassSurface {
                        radius: 8
                        visible: ShellState.plasticEnabled && refreshWinMouse.containsMouse
                        accentColor: Theme.accentSky
                        hovered: refreshWinMouse.containsMouse
                        pressed: refreshWinMouse.pressed
                        showShadow: false
                    }

                    Icon {
                        anchors.centerIn: parent
                        name: "refresh-cw"
                        size: 13
                        color: refreshWinMouse.containsMouse ? Theme.accentSky : Theme.textMuted
                    }

                    MouseArea {
                        id: refreshWinMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: WindowService.refresh()
                    }
                }

                // Close Button
                Rectangle {
                    width: 28
                    height: 28
                    radius: 8
                    color: ShellState.plasticEnabled ? "transparent" : (closeWinMouse.containsMouse ? Qt.rgba(Theme.accentRose.r, Theme.accentRose.g, Theme.accentRose.b, 0.2) : Theme.bgPill)
                    border.color: ShellState.plasticEnabled ? "transparent" : (closeWinMouse.containsMouse ? Theme.accentRose : Theme.borderDim)
                    border.width: ShellState.plasticEnabled ? 0 : 1

                    LiquidGlassSurface {
                        radius: 8
                        visible: ShellState.plasticEnabled && closeWinMouse.containsMouse
                        accentColor: Theme.accentRose
                        hovered: closeWinMouse.containsMouse
                        pressed: closeWinMouse.pressed
                        showShadow: false
                    }

                    Icon {
                        anchors.centerIn: parent
                        name: "x"
                        size: 13
                        color: closeWinMouse.containsMouse ? Theme.accentRose : Theme.textMuted
                    }

                    MouseArea {
                        id: closeWinMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: ShellState.windowSwitcherOpen = false
                    }
                }
            }

            // Divider
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Theme.borderDim
            }

            // ── Workspaces & Search Row ─────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                // Workspace filter chips
                RowLayout {
                    spacing: 5

                    Repeater {
                        model: switcherWindow.getWorkspaces()

                        delegate: Rectangle {
                            id: wsChipItem
                            required property string modelData
                            height: 26
                            implicitWidth: wsChipText.implicitWidth + 14
                            radius: 13
                            readonly property bool isActive: activeWorkspaceFilter === modelData
                            color: ShellState.plasticEnabled
                                ? "transparent"
                                : (isActive ? Qt.rgba(Theme.accentSky.r, Theme.accentSky.g, Theme.accentSky.b, 0.25) : (wsChipMouse.containsMouse ? Theme.bgHover : Theme.bgPill))
                            border.color: ShellState.plasticEnabled
                                ? "transparent"
                                : (isActive ? Theme.accentSky : Theme.borderDim)
                            border.width: ShellState.plasticEnabled ? 0 : 1

                            LiquidGlassSurface {
                                radius: 13
                                visible: ShellState.plasticEnabled && (wsChipItem.isActive || wsChipMouse.containsMouse)
                                accentColor: Theme.accentSky
                                hovered: wsChipMouse.containsMouse
                                pressed: wsChipMouse.pressed
                                showShadow: false
                            }

                            Rectangle {
                                anchors.fill: parent
                                radius: 13
                                visible: ShellState.plasticEnabled && !wsChipItem.isActive && !wsChipMouse.containsMouse
                                color: Qt.rgba(0.20, 0.28, 0.40, 0.22)
                                border.color: Qt.rgba(1.0, 1.0, 1.0, 0.12)
                                border.width: 1
                            }

                            Text {
                                id: wsChipText
                                anchors.centerIn: parent
                                text: modelData === "all" ? "All Displays" : ("Workspace " + modelData)
                                font.family: Theme.fontFamily
                                font.pixelSize: 10
                                font.bold: wsChipItem.isActive
                                color: wsChipItem.isActive ? Theme.accentSky : Theme.textMuted
                            }

                            MouseArea {
                                id: wsChipMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    activeWorkspaceFilter = modelData;
                                    selectedIndex = 0;
                                }
                            }
                        }
                    }
                }

                Item { Layout.fillWidth: true }

                // Search field
                Rectangle {
                    height: 32
                    implicitWidth: 250
                    radius: 16
                    color: ShellState.plasticEnabled ? "transparent" : Theme.bgPill
                    border.color: ShellState.plasticEnabled ? "transparent" : (searchInput.activeFocus ? Theme.accentSky : Theme.borderDim)
                    border.width: ShellState.plasticEnabled ? 0 : 1

                    LiquidGlassSurface {
                        radius: 16
                        visible: ShellState.plasticEnabled
                        accentColor: searchInput.activeFocus ? Theme.accentSky : Theme.borderDim
                        showShadow: false
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
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
                            selectByMouse: true
                            clip: true

                            onTextChanged: selectedIndex = 0

                            Text {
                                anchors.fill: parent
                                text: "Type to filter windows..."
                                font.family: Theme.fontFamily
                                font.pixelSize: 11
                                color: Theme.textMuted
                                opacity: 0.6
                                visible: !searchInput.text && !searchInput.activeFocus
                            }
                        }

                        Icon {
                            name: "x"
                            size: 11
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

            // ── Window Grid View ────────────────────────────────────────────
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                GridView {
                    id: winGrid
                    anchors.fill: parent
                    cellWidth: 300
                    cellHeight: 145
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    model: switcherWindow.filteredWindows

                    ScrollBar.vertical: ScrollBar {
                        policy: winGrid.contentHeight > winGrid.height ? ScrollBar.AlwaysOn : ScrollBar.AsNeeded
                    }

                    // Empty placeholder
                    Item {
                        anchors.fill: parent
                        visible: winGrid.count === 0 && !WindowService.loading

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 8

                            Icon {
                                name: "layers"
                                size: 36
                                color: Theme.accentSky
                                Layout.alignment: Qt.AlignHCenter
                            }

                            Text {
                                text: searchInput.text ? "No windows matching '" + searchInput.text + "'" : "No active windows"
                                font.family: Theme.fontFamily
                                font.pixelSize: 13
                                font.bold: true
                                color: Theme.textMuted
                                Layout.alignment: Qt.AlignHCenter
                            }
                        }
                    }

                    delegate: Item {
                        required property var modelData
                        required property int index

                        width: winGrid.cellWidth
                        height: winGrid.cellHeight

                        Rectangle {
                            id: wCard
                            anchors.fill: parent
                            anchors.margins: 5
                            radius: 14
                            readonly property bool isSelected: index === selectedIndex
                            readonly property bool isHovered: wMouse.containsMouse

                            color: ShellState.plasticEnabled
                                ? "transparent"
                                : ((isSelected || isHovered) ? Theme.bgHover : Theme.bgCard)
                            border.color: ShellState.plasticEnabled
                                ? "transparent"
                                : (isSelected ? Theme.accentSky : (isHovered ? Qt.rgba(Theme.accentSky.r, Theme.accentSky.g, Theme.accentSky.b, 0.4) : Theme.borderDim))
                            border.width: ShellState.plasticEnabled ? 0 : (isSelected ? 1.5 : 1)

                            // 3D Optical Plastic Surface for selected or hovered window card
                            LiquidGlassSurface {
                                radius: 14
                                visible: ShellState.plasticEnabled && (wCard.isSelected || wCard.isHovered)
                                accentColor: wCard.isSelected ? Theme.accentSky : (modelData.accent_color || Theme.accentSky)
                                hovered: wCard.isHovered
                                pressed: wMouse.pressed
                                showShadow: false
                            }

                            // Subtle translucent acrylic body for unselected idle cards in plastic mode
                            Rectangle {
                                anchors.fill: parent
                                radius: 14
                                visible: ShellState.plasticEnabled && !wCard.isSelected && !wCard.isHovered
                                color: Qt.rgba(0.12, 0.17, 0.26, 0.32)
                                border.color: Qt.rgba(1.0, 1.0, 1.0, 0.10)
                                border.width: 1
                            }

                            Behavior on color { ColorAnimation { duration: 120 } }
                            Behavior on border.color { ColorAnimation { duration: 120 } }

                            // Left status strip
                            Rectangle {
                                width: 4
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                anchors.left: parent.left
                                anchors.topMargin: 8
                                anchors.bottomMargin: 8
                                radius: 2
                                color: modelData.accent_color || Theme.accentSky
                            }

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 14
                                anchors.rightMargin: 12
                                anchors.topMargin: 10
                                anchors.bottomMargin: 10
                                spacing: 6

                                // Header row: App Glyph, Category Badge, Workspace, Close
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 6

                                    Text {
                                        text: modelData.glyph || "🪟"
                                        font.pixelSize: 14
                                    }

                                    Rectangle {
                                        height: 16
                                        implicitWidth: catBadgeText.implicitWidth + 8
                                        radius: 4
                                        color: Qt.rgba(
                                            (modelData.accent_color ? Qt.color(modelData.accent_color).r : Theme.accentSky.r),
                                            (modelData.accent_color ? Qt.color(modelData.accent_color).g : Theme.accentSky.g),
                                            (modelData.accent_color ? Qt.color(modelData.accent_color).b : Theme.accentSky.b),
                                            0.18
                                        )

                                        Text {
                                            id: catBadgeText
                                            anchors.centerIn: parent
                                            text: modelData.category_label || "APP"
                                            font.family: Theme.fontMono
                                            font.pixelSize: 8
                                            font.bold: true
                                            color: modelData.accent_color || Theme.accentSky
                                        }
                                    }

                                    Rectangle {
                                        height: 16
                                        implicitWidth: wsText.implicitWidth + 8
                                        radius: 4
                                        color: Theme.bgPill

                                        Text {
                                            id: wsText
                                            anchors.centerIn: parent
                                            text: "WS " + (modelData.workspace_id || "1")
                                            font.family: Theme.fontMono
                                            font.pixelSize: 8
                                            color: Theme.textMuted
                                        }
                                    }

                                    Item { Layout.fillWidth: true }

                                    // Active window indicator dot
                                    Rectangle {
                                        visible: !!modelData.is_active
                                        height: 16
                                        implicitWidth: focusedDotText.implicitWidth + 8
                                        radius: 8
                                        color: Qt.rgba(Theme.accentEmerald.r, Theme.accentEmerald.g, Theme.accentEmerald.b, 0.15)
                                        border.color: Theme.accentEmerald
                                        border.width: 0.5

                                        Text {
                                            id: focusedDotText
                                            anchors.centerIn: parent
                                            text: "● FOCUSED"
                                            font.family: Theme.fontMono
                                            font.pixelSize: 7
                                            font.bold: true
                                            color: Theme.accentEmerald
                                        }
                                    }

                                    // Close window button (Plastic Gem)
                                    Item {
                                        width: 18
                                        height: 18

                                        LiquidGlassSurface {
                                            radius: 9
                                            visible: ShellState.plasticEnabled && wCloseMouse.containsMouse
                                            accentColor: Theme.accentRose
                                            hovered: wCloseMouse.containsMouse
                                            pressed: wCloseMouse.pressed
                                            showShadow: false
                                        }

                                        Rectangle {
                                            anchors.fill: parent
                                            radius: 9
                                            visible: !ShellState.plasticEnabled
                                            color: wCloseMouse.containsMouse ? Theme.accentRose : Theme.bgPill
                                        }

                                        Icon {
                                            anchors.centerIn: parent
                                            name: "x"
                                            size: 9
                                            color: wCloseMouse.containsMouse ? "#FFFFFF" : Theme.textMuted
                                        }

                                        MouseArea {
                                            id: wCloseMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: WindowService.closeWindow(modelData.address)
                                        }
                                    }
                                }

                                // Middle: Window Title
                                Text {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    text: modelData.title || "Window"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 11
                                    font.bold: true
                                    color: (index === selectedIndex || wMouse.containsMouse) ? Theme.textPrimary : Theme.textSecondary
                                    wrapMode: Text.Wrap
                                    maximumLineCount: 2
                                    elide: Text.ElideRight
                                }

                                // Footer row: Process Class & Geometry
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 8

                                    Text {
                                        text: modelData.class || ""
                                        font.family: Theme.fontMono
                                        font.pixelSize: 8
                                        color: Theme.textMuted
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }

                                    Text {
                                        text: (modelData.size ? (modelData.size[0] + "×" + modelData.size[1]) : "")
                                        font.family: Theme.fontMono
                                        font.pixelSize: 8
                                        color: Theme.textMuted
                                    }
                                }
                            }

                            MouseArea {
                                id: wMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    selectedIndex = index;
                                    ShellState.windowSwitcherOpen = false;
                                    WindowService.focusWindow(modelData.address);
                                }
                            }
                        }
                    }
                }
            }

            // ── Footer Bar ──────────────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: "Press Tab to cycle next  •  Shift+Tab for previous  •  Enter to jump"
                    font.family: Theme.fontMono
                    font.pixelSize: 8
                    color: Theme.textMuted
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: "SUPER + TAB to toggle  •  ESC to cancel"
                    font.family: Theme.fontMono
                    font.pixelSize: 8
                    color: Theme.textMuted
                }
            }
        }
    }
}
