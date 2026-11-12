import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import "../theme"
import "../services"
import "../components"

PanelWindow {
    id: root

    visible: ShellState.wallpaperThemeDialogOpen
    color: "transparent"

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "quickshell:wallpapertheme"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: ShellState.wallpaperThemeDialogOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    property string activeTab: ShellState.wallpaperThemeTab || "wallpapers"
    onActiveTabChanged: {
        if (ShellState.wallpaperThemeTab !== activeTab) {
            ShellState.wallpaperThemeTab = activeTab;
        }
    }
    property bool showThemeCreator: false
    property string customThemeName: ""
    property string selectedPrimaryAccent: "#38BDF8"
    property string selectedSecondaryAccent: "#A78BFA"
    property string selectedBaseTone: "#090D14"

    // Backdrop click
    MouseArea {
        anchors.fill: parent
        onClicked: ShellState.wallpaperThemeDialogOpen = false

        Rectangle {
            anchors.fill: parent
            color: "#000000"
            opacity: 0.65
        }
    }

    // Modal Card
    Rectangle {
        id: card
        width: 800
        height: 580
        anchors.centerIn: parent
        radius: Theme.cardRadius
        color: ShellState.glassEnabled ? "transparent" : Theme.bgModal
        border.color: ShellState.glassEnabled ? "transparent" : Theme.borderGlow
        border.width: ShellState.glassEnabled ? 0 : 1

        LiquidGlassSurface {
            radius: Theme.cardRadius
            visible: ShellState.glassEnabled
            accentColor: Theme.accentAmber
            showShadow: true
        }
        clip: true

        Keys.onEscapePressed: {
            ShellState.wallpaperThemeDialogOpen = false;
        }

        MouseArea {
            anchors.fill: parent
            onClicked: {}
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 18
            spacing: 12

            // Header Bar
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Rectangle {
                    width: 36
                    height: 36
                    radius: 10
                    color: ShellState.plasticEnabled ? "transparent" : Qt.rgba(Theme.accentViolet.r, Theme.accentViolet.g, Theme.accentViolet.b, 0.15)
                    border.color: ShellState.plasticEnabled ? "transparent" : Theme.accentViolet
                    border.width: ShellState.plasticEnabled ? 0 : 1

                    LiquidGlassSurface {
                        radius: 10
                        visible: ShellState.plasticEnabled
                        accentColor: Theme.accentViolet
                        showShadow: false
                    }

                    Icon {
                        anchors.centerIn: parent
                        name: "image"
                        size: 18
                        color: Theme.accentViolet
                    }
                }

                ColumnLayout {
                    spacing: 2
                    Text {
                        text: "WALLPAPERS & THEMES"
                        font.family: Theme.fontFamily
                        font.pixelSize: 14
                        font.bold: true
                        color: Theme.textPrimary
                    }
                    Text {
                        text: "Customize desktop backdrop and live dynamic accent palettes"
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                        color: Theme.textMuted
                    }
                }

                Item { Layout.fillWidth: true }

                // GRADIENT MODE TOGGLE BUTTON
                Rectangle {
                    height: 28
                    implicitWidth: gradToggleRow.implicitWidth + 14
                    radius: 8
                    readonly property bool isGradient: WallpaperService.mode === "gradient"
                    color: ShellState.plasticEnabled
                        ? "transparent"
                        : (isGradient ? Theme.accentViolet : (gradMouse.containsMouse ? Theme.bgHover : Theme.bgPill))
                    border.color: ShellState.plasticEnabled
                        ? "transparent"
                        : (isGradient ? Theme.accentViolet : Theme.borderDim)
                    border.width: ShellState.plasticEnabled ? 0 : 1

                    LiquidGlassSurface {
                        radius: 8
                        visible: ShellState.plasticEnabled && (parent.isGradient || gradMouse.containsMouse)
                        accentColor: Theme.accentViolet
                        hovered: gradMouse.containsMouse
                        pressed: gradMouse.pressed
                        showShadow: false
                    }

                    RowLayout {
                        id: gradToggleRow
                        anchors.centerIn: parent
                        spacing: 6

                        Icon {
                            name: "layers"
                            size: 12
                            color: parent.parent.isGradient ? Theme.textOnAccent : Theme.accentViolet
                        }

                        Text {
                            text: parent.parent.isGradient ? "Gradient: ON" : "Gradient: OFF"
                            font.family: Theme.fontMono
                            font.pixelSize: 10
                            font.bold: true
                            color: parent.parent.isGradient ? Theme.textOnAccent : Theme.textPrimary
                        }
                    }

                    MouseArea {
                        id: gradMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: WallpaperService.toggleGradient()
                    }
                }

                // FROM WP TOGGLE BUTTON
                Rectangle {
                    height: 28
                    implicitWidth: wpToggleRow.implicitWidth + 14
                    radius: 8
                    color: Theme.fromWallpaperActive ? Theme.accentCyan : Theme.bgPill
                    border.color: Theme.fromWallpaperActive ? Theme.accentCyan : Theme.borderDim
                    border.width: 1

                    RowLayout {
                        id: wpToggleRow
                        anchors.centerIn: parent
                        spacing: 6

                        Icon {
                            name: "sparkles"
                            size: 12
                            color: Theme.fromWallpaperActive ? Theme.textOnAccent : Theme.accentSky
                        }

                        Text {
                            text: Theme.isExtractingWallpaper ? "Extracting..." : (Theme.fromWallpaperActive ? "From WP: ON (Live)" : "From WP: OFF")
                            font.family: Theme.fontMono
                            font.pixelSize: 10
                            font.bold: true
                            color: Theme.fromWallpaperActive ? Theme.textOnAccent : Theme.textPrimary
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        enabled: !Theme.isExtractingWallpaper
                        onClicked: {
                            Theme.toggleFromWallpaper(WallpaperService.currentWallpaper);
                        }
                    }
                }

                // Close Button
                Rectangle {
                    width: 28
                    height: 28
                    radius: 7
                    color: closeMouse.containsMouse ? Theme.bgHover : Theme.bgPill
                    border.color: Theme.borderDim
                    border.width: 1

                    Icon {
                        anchors.centerIn: parent
                        name: "x"
                        size: 12
                        color: Theme.textMuted
                    }

                    MouseArea {
                        id: closeMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: ShellState.wallpaperThemeDialogOpen = false
                    }
                }
            }

            // Tabs Switcher
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Rectangle {
                    height: 30
                    implicitWidth: wpTabRow.implicitWidth + 16
                    radius: 8
                    readonly property bool active: root.activeTab === "wallpapers"
                    color: active ? Theme.accentViolet : (wpTabM.containsMouse ? Theme.bgHover : Theme.bgPill)
                    border.color: active ? Theme.accentViolet : Theme.borderDim
                    border.width: 1

                    RowLayout {
                        id: wpTabRow
                        anchors.centerIn: parent
                        spacing: 6
                        Icon {
                            name: "image"
                            size: 11
                            color: parent.parent.active ? Theme.textOnAccent : Theme.textMuted
                        }
                        Text {
                            text: "Wallpapers (" + WallpaperService.wallpapers.length + ")"
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                            font.bold: parent.parent.active
                            color: parent.parent.active ? Theme.textOnAccent : Theme.textPrimary
                        }
                    }

                    MouseArea {
                        id: wpTabM
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.activeTab = "wallpapers"
                    }
                }

                Rectangle {
                    height: 30
                    implicitWidth: themeTabRow.implicitWidth + 16
                    radius: 8
                    readonly property bool active: root.activeTab === "themes"
                    color: active ? Theme.accentViolet : (themeTabM.containsMouse ? Theme.bgHover : Theme.bgPill)
                    border.color: active ? Theme.accentViolet : Theme.borderDim
                    border.width: 1

                    RowLayout {
                        id: themeTabRow
                        anchors.centerIn: parent
                        spacing: 6
                        Icon {
                            name: "palette"
                            size: 11
                            color: parent.parent.active ? Theme.textOnAccent : Theme.textMuted
                        }
                        Text {
                            text: "Theme Palettes (" + Theme.themeKeys.length + ")"
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                            font.bold: parent.parent.active
                            color: parent.parent.active ? Theme.textOnAccent : Theme.textPrimary
                        }
                    }

                    MouseArea {
                        id: themeTabM
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.activeTab = "themes"
                    }
                }

                Item { Layout.fillWidth: true }

                // Quick Mode or Action chips
                RowLayout {
                    spacing: 6
                    visible: root.activeTab === "wallpapers"

                    Rectangle {
                        height: 26
                        implicitWidth: prevRow.implicitWidth + 10
                        radius: 6
                        color: prevM.containsMouse ? Theme.bgHover : Theme.bgPill
                        border.color: Theme.borderDim
                        border.width: 1
                        RowLayout {
                            id: prevRow
                            anchors.centerIn: parent
                            spacing: 4
                            Icon { name: "chevron-left"; size: 10; color: Theme.accentViolet }
                            Text { text: "Prev"; font.family: Theme.fontMono; font.pixelSize: 9; color: Theme.textSecondary }
                        }
                        MouseArea {
                            id: prevM
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: WallpaperService.prevWallpaper()
                        }
                    }

                    Rectangle {
                        height: 26
                        implicitWidth: nextRow.implicitWidth + 10
                        radius: 6
                        color: nextM.containsMouse ? Theme.bgHover : Theme.bgPill
                        border.color: Theme.borderDim
                        border.width: 1
                        RowLayout {
                            id: nextRow
                            anchors.centerIn: parent
                            spacing: 4
                            Text { text: "Next"; font.family: Theme.fontMono; font.pixelSize: 9; color: Theme.textSecondary }
                            Icon { name: "chevron-right"; size: 10; color: Theme.accentViolet }
                        }
                        MouseArea {
                            id: nextM
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: WallpaperService.nextWallpaper()
                        }
                    }
                }

                // Themes Tab action: Create theme button
                Rectangle {
                    visible: root.activeTab === "themes"
                    height: 26
                    implicitWidth: createRow.implicitWidth + 12
                    radius: 6
                    color: root.showThemeCreator ? Theme.accentViolet : (createM.containsMouse ? Theme.bgHover : Theme.bgPill)
                    border.color: root.showThemeCreator ? Theme.accentViolet : Theme.borderDim
                    border.width: 1

                    RowLayout {
                        id: createRow
                        anchors.centerIn: parent
                        spacing: 4
                        Icon { name: root.showThemeCreator ? "x" : "plus"; size: 10; color: root.showThemeCreator ? Theme.textOnAccent : Theme.accentViolet }
                        Text {
                            text: root.showThemeCreator ? "Close Form" : "+ Create Custom Theme"
                            font.family: Theme.fontMono
                            font.pixelSize: 9
                            font.bold: true
                            color: root.showThemeCreator ? Theme.textOnAccent : Theme.textPrimary
                        }
                    }

                    MouseArea {
                        id: createM
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.showThemeCreator = !root.showThemeCreator
                    }
                }
            }

            // Divider
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Theme.borderDim
            }

            // ==========================================
            // VIEW 1: WALLPAPERS GALLERY
            // ==========================================
            Item {
                visible: root.activeTab === "wallpapers"
                Layout.fillWidth: true
                Layout.fillHeight: true

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 8

                    // Active Gradient Mode Banner
                    Rectangle {
                        visible: WallpaperService.mode === "gradient"
                        Layout.fillWidth: true
                        height: 34
                        radius: 8
                        color: Qt.rgba(Theme.accentViolet.r, Theme.accentViolet.g, Theme.accentViolet.b, 0.14)
                        border.color: Theme.accentViolet
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 8

                            Icon { name: "layers"; size: 14; color: Theme.accentViolet }

                            Text {
                                Layout.fillWidth: true
                                text: "Procedural Ambient Gradient is active (Images hidden). Select any wallpaper below to exit gradient mode."
                                font.family: Theme.fontFamily
                                font.pixelSize: 10
                                font.bold: true
                                color: Theme.textPrimary
                            }

                            Rectangle {
                                height: 22
                                implicitWidth: exitGradRow.implicitWidth + 10
                                radius: 5
                                color: Theme.accentViolet

                                RowLayout {
                                    id: exitGradRow
                                    anchors.centerIn: parent
                                    Text { text: "Exit Gradient Mode"; font.family: Theme.fontFamily; font.pixelSize: 9; font.bold: true; color: Theme.textOnAccent }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: WallpaperService.toggleGradient()
                                }
                            }
                        }
                    }

                    GridView {
                        id: wpGrid
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        cellWidth: width / 3
                        cellHeight: 140
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds
                        model: WallpaperService.wallpapers

                        ScrollBar.vertical: ScrollBar {
                            active: wpGrid.moving || wpGrid.flicking
                            policy: ScrollBar.AsNeeded
                        }

                    delegate: Item {
                        width: wpGrid.cellWidth
                        height: wpGrid.cellHeight

                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: 5
                            radius: 10
                            readonly property string fullPath: WallpaperService.wallpaperDir + "/" + modelData
                            readonly property bool isCurrent: WallpaperService.currentWallpaper === fullPath
                            color: Theme.bgCard
                            border.color: isCurrent ? Theme.accentCyan : (itemMouse.containsMouse ? Theme.borderActive : Theme.borderDim)
                            border.width: isCurrent ? 2 : 1
                            clip: true

                            // Image Thumbnail
                            Image {
                                anchors.fill: parent
                                source: "file://" + parent.fullPath
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                cache: true
                                opacity: parent.isCurrent ? 1.0 : (itemMouse.containsMouse ? 0.95 : 0.85)

                                Behavior on opacity { NumberAnimation { duration: 150 } }
                            }

                            // Dark gradient overlay for title legibility
                            Rectangle {
                                anchors.bottom: parent.bottom
                                anchors.left: parent.left
                                anchors.right: parent.right
                                height: 32
                                gradient: Gradient {
                                    GradientStop { position: 0.0; color: "transparent" }
                                    GradientStop { position: 1.0; color: "#D0000000" }
                                }
                            }

                            // Title Label
                            Text {
                                anchors.bottom: parent.bottom
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.margins: 6
                                text: {
                                    const base = modelData.replace(/\.[^/.]+$/, "");
                                    return base.replace(/[_\-]+/g, " ");
                                }
                                font.family: Theme.fontFamily
                                font.pixelSize: 9
                                font.bold: true
                                color: "#FFFFFF"
                                elide: Text.ElideRight
                            }

                            // Active Check Badge
                            Rectangle {
                                visible: parent.isCurrent
                                anchors.top: parent.top
                                anchors.right: parent.right
                                anchors.margins: 6
                                width: 20
                                height: 20
                                radius: 10
                                color: Theme.accentCyan

                                Icon {
                                    anchors.centerIn: parent
                                    name: "check"
                                    size: 11
                                    color: Theme.bgBase
                                }
                            }

                            MouseArea {
                                id: itemMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    WallpaperService.setWallpaper(parent.fullPath);
                                    if (Theme.fromWallpaperActive) {
                                        Theme.extractTemporaryWallpaperTheme(parent.fullPath);
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

            // ==========================================
            // VIEW 2: THEMES GALLERY & CREATOR
            // ==========================================
            Item {
                visible: root.activeTab === "themes"
                Layout.fillWidth: true
                Layout.fillHeight: true

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 10

                    // Dynamic Live Theme Banner (when From WP is ON)
                    Rectangle {
                        visible: Theme.fromWallpaperActive
                        Layout.fillWidth: true
                        height: 38
                        radius: 8
                        color: Qt.rgba(Theme.accentCyan.r, Theme.accentCyan.g, Theme.accentCyan.b, 0.12)
                        border.color: Theme.accentCyan
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 8

                            Icon { name: "sparkles"; size: 14; color: Theme.accentCyan }

                            Text {
                                Layout.fillWidth: true
                                text: "From WP Mode Active: Colors are dynamically matching the wallpaper without saving."
                                font.family: Theme.fontFamily
                                font.pixelSize: 10
                                font.bold: true
                                color: Theme.textPrimary
                            }

                            // Save as custom theme button
                            Rectangle {
                                height: 24
                                implicitWidth: freezeRow.implicitWidth + 12
                                radius: 5
                                color: Theme.accentCyan

                                RowLayout {
                                    id: freezeRow
                                    anchors.centerIn: parent
                                    spacing: 4
                                    Text { text: "Save as Permanent Theme"; font.family: Theme.fontFamily; font.pixelSize: 9; font.bold: true; color: Theme.textOnAccent }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (Theme.tempWallpaperPalette) {
                                            const copy = Object.assign({}, Theme.tempWallpaperPalette);
                                            copy.id = "wp_" + Date.now();
                                            copy.isTemporary = false;
                                            Theme.addCustomTheme(copy);
                                            Theme.setTheme(copy.id);
                                            Quickshell.execDetached(["notify-send", "-a", "Antigravity", "Theme Saved", "Saved live wallpaper theme permanently!"]);
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Collapsible Theme Creator Form
                    Rectangle {
                        visible: root.showThemeCreator
                        Layout.fillWidth: true
                        implicitHeight: creatorCol.implicitHeight + 16
                        radius: 10
                        color: Theme.bgCard
                        border.color: Theme.accentViolet
                        border.width: 1

                        ColumnLayout {
                            id: creatorCol
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 8

                            RowLayout {
                                Layout.fillWidth: true
                                Text {
                                    text: "CREATE NEW CUSTOM PALETTE"
                                    font.family: Theme.fontMono
                                    font.pixelSize: 9
                                    font.bold: true
                                    color: Theme.accentViolet
                                }
                                Item { Layout.fillWidth: true }
                                Icon {
                                    name: "x"
                                    size: 10
                                    color: Theme.textMuted
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.showThemeCreator = false
                                    }
                                }
                            }

                            // Name input
                            Rectangle {
                                Layout.fillWidth: true
                                height: 28
                                radius: 6
                                color: Theme.bgPill
                                border.color: nameInput.activeFocus ? Theme.accentViolet : Theme.borderDim
                                border.width: 1

                                TextInput {
                                    id: nameInput
                                    anchors.fill: parent
                                    anchors.leftMargin: 8
                                    anchors.rightMargin: 8
                                    verticalAlignment: TextInput.AlignVCenter
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 10
                                    color: Theme.textPrimary
                                    text: root.customThemeName
                                    onTextChanged: root.customThemeName = text

                                    Text {
                                        visible: !nameInput.text && !nameInput.activeFocus
                                        text: "Enter theme name (e.g. Neon Horizon)..."
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 10
                                        color: Theme.textMuted
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                }
                            }

                            // Primary Accent Picker
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 4
                                Text { text: "Primary:"; font.family: Theme.fontMono; font.pixelSize: 9; color: Theme.textMuted; Layout.preferredWidth: 50 }
                                Row {
                                    spacing: 5
                                    Repeater {
                                        model: ["#38BDF8", "#A78BFA", "#22D3EE", "#34D399", "#FB7185", "#FBBF24", "#FB923C", "#FF007F"]
                                        Rectangle {
                                            width: 18; height: 18; radius: 9; color: modelData
                                            border.color: root.selectedPrimaryAccent === modelData ? "#FFFFFF" : "transparent"
                                            border.width: root.selectedPrimaryAccent === modelData ? 2 : 0
                                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.selectedPrimaryAccent = modelData }
                                        }
                                    }
                                }
                            }

                            // Secondary Accent Picker
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 4
                                Text { text: "Accent 2:"; font.family: Theme.fontMono; font.pixelSize: 9; color: Theme.textMuted; Layout.preferredWidth: 50 }
                                Row {
                                    spacing: 5
                                    Repeater {
                                        model: ["#A78BFA", "#38BDF8", "#22D3EE", "#FBBF24", "#34D399", "#FB7185", "#F472B6", "#CBD5E1"]
                                        Rectangle {
                                            width: 18; height: 18; radius: 9; color: modelData
                                            border.color: root.selectedSecondaryAccent === modelData ? "#FFFFFF" : "transparent"
                                            border.width: root.selectedSecondaryAccent === modelData ? 2 : 0
                                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.selectedSecondaryAccent = modelData }
                                        }
                                    }
                                }
                            }

                            // Base Dark Tone Selector
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 4
                                Text { text: "Base:"; font.family: Theme.fontMono; font.pixelSize: 9; color: Theme.textMuted; Layout.preferredWidth: 50 }
                                Row {
                                    spacing: 6
                                    Repeater {
                                        model: [
                                            { name: "Obsidian", color: "#090D14" },
                                            { name: "Slate", color: "#0F172A" },
                                            { name: "Charcoal", color: "#16161E" },
                                            { name: "Mocha", color: "#1E1E2E" },
                                            { name: "Gruvbox", color: "#1D2021" }
                                        ]
                                        Rectangle {
                                            width: 24; height: 18; radius: 4; color: modelData.color
                                            border.color: root.selectedBaseTone === modelData.color ? Theme.accentViolet : Theme.borderDim
                                            border.width: root.selectedBaseTone === modelData.color ? 2 : 1
                                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.selectedBaseTone = modelData.color }
                                        }
                                    }
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                height: 26
                                radius: 6
                                color: Theme.accentViolet
                                RowLayout {
                                    anchors.centerIn: parent
                                    spacing: 4
                                    Icon { name: "check"; size: 10; color: Theme.textOnAccent }
                                    Text { text: "Save & Activate Theme"; font.family: Theme.fontFamily; font.pixelSize: 10; font.bold: true; color: Theme.textOnAccent }
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        const tName = root.customThemeName.trim() || ("Custom " + (Theme.customThemeKeys.length + 1));
                                        Theme.createCustomTheme(tName, root.selectedPrimaryAccent, root.selectedSecondaryAccent, root.selectedBaseTone);
                                        root.customThemeName = "";
                                        root.showThemeCreator = false;
                                    }
                                }
                            }
                        }
                    }

                    // Theme Cards Grid
                    GridView {
                        id: themeGrid
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        cellWidth: width / 2
                        cellHeight: 52
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds
                        model: Theme.themeKeys

                        ScrollBar.vertical: ScrollBar {
                            active: themeGrid.moving || themeGrid.flicking
                            policy: ScrollBar.AsNeeded
                        }

                        delegate: Item {
                            width: themeGrid.cellWidth
                            height: themeGrid.cellHeight

                            Rectangle {
                                id: themeCard
                                anchors.fill: parent
                                anchors.margins: 4
                                radius: 8
                                readonly property bool isSelected: !Theme.fromWallpaperActive && Theme.currentThemeKey === modelData
                                readonly property var pal: (Theme.palettes && Theme.palettes[modelData]) || Theme.palettes["deepspace"] || ({ "name": modelData, "accentViolet": "#A78BFA", "accentSky": "#38BDF8" })
                                readonly property bool isCustom: Theme.isCustomTheme(modelData)

                                color: themeCard.isSelected ? Theme.bgCard : (tMouse.containsMouse ? Theme.bgHover : Theme.bgPill)
                                border.color: themeCard.isSelected ? (themeCard.pal.accentViolet || Theme.accentViolet) : Theme.borderDim
                                border.width: themeCard.isSelected ? 1.5 : 1

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 10
                                    spacing: 8

                                    // Palette preview dots
                                    Row {
                                        spacing: 3
                                        Rectangle { width: 10; height: 10; radius: 5; color: themeCard.pal.accentViolet || Theme.accentViolet }
                                        Rectangle { width: 10; height: 10; radius: 5; color: themeCard.pal.accentSky || Theme.accentSky }
                                        Rectangle { width: 10; height: 10; radius: 5; color: themeCard.pal.accentCyan || Theme.accentCyan }
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: themeCard.pal.name || modelData
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 11
                                        font.bold: themeCard.isSelected
                                        color: themeCard.isSelected ? (themeCard.pal.accentViolet || Theme.textPrimary) : Theme.textPrimary
                                        elide: Text.ElideRight
                                    }

                                    Icon {
                                        visible: themeCard.isSelected
                                        name: "check"
                                        size: 13
                                        color: themeCard.pal.accentViolet || Theme.accentViolet
                                    }

                                    // Delete button for custom themes
                                    Rectangle {
                                        visible: themeCard.isCustom
                                        width: 18
                                        height: 18
                                        radius: 9
                                        color: delM.containsMouse ? Theme.accentRose : "transparent"

                                        Icon {
                                            anchors.centerIn: parent
                                            name: "x"
                                            size: 10
                                            color: delM.containsMouse ? "#FFFFFF" : Theme.textMuted
                                        }

                                        MouseArea {
                                            id: delM
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: Theme.deleteCustomTheme(modelData)
                                        }
                                    }
                                }

                                MouseArea {
                                    id: tMouse
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

                    // ==========================================
                    // TYPOGRAPHY & FONT PRESETS
                    // ==========================================
                    Rectangle {
                        Layout.fillWidth: true
                        height: 74
                        radius: 8
                        color: ShellState.glassEnabled ? Qt.rgba(0, 0, 0, 0.20) : Theme.bgCard
                        border.color: Theme.borderDim
                        border.width: 1

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 6

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 6

                                Icon {
                                    name: "type"
                                    size: 11
                                    color: Theme.accentSky
                                }

                                Text {
                                    text: "TYPOGRAPHY & SYSTEM FONTS"
                                    font.family: Theme.fontMono
                                    font.pixelSize: 9
                                    font.bold: true
                                    color: Theme.textMuted
                                }

                                Item { Layout.fillWidth: true }

                                Text {
                                    text: "Active: " + (ShellState.fontPreset === "cupertino" ? "Cupertino Glass" : (ShellState.fontPreset === "nordic" ? "Cyber Nordic" : "Google Material"))
                                    font.family: Theme.fontMono
                                    font.pixelSize: 9
                                    font.bold: true
                                    color: Theme.accentSky
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                Repeater {
                                    model: [
                                        {
                                            id: "cupertino",
                                            name: "Cupertino Glass",
                                            fontDisplay: "SF Pro Display",
                                            fontMono: "JetBrains Mono",
                                            accent: Theme.accentSky,
                                            sub: "SF Pro + JetBrains"
                                        },
                                        {
                                            id: "nordic",
                                            name: "Cyber Nordic",
                                            fontDisplay: "Plus Jakarta Sans",
                                            fontMono: "Fira Code",
                                            accent: Theme.accentViolet,
                                            sub: "Plus Jakarta + Fira"
                                        },
                                        {
                                            id: "google",
                                            name: "Google Material",
                                            fontDisplay: "Google Sans",
                                            fontMono: "Adwaita Mono",
                                            accent: Theme.accentEmerald,
                                            sub: "Google Sans + Adwaita"
                                        }
                                    ]

                                    Rectangle {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 36
                                        radius: 6
                                        readonly property bool isSelected: ShellState.fontPreset === modelData.id
                                        color: isSelected ? Qt.rgba(Theme.accentViolet.r, Theme.accentViolet.g, Theme.accentViolet.b, 0.15) : (fMouse.containsMouse ? Theme.bgHover : Theme.bgPill)
                                        border.color: isSelected ? (modelData.accent || Theme.accentViolet) : Theme.borderDim
                                        border.width: isSelected ? 1.5 : 1

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.leftMargin: 8
                                            anchors.rightMargin: 8
                                            spacing: 6

                                            Rectangle {
                                                width: 22
                                                height: 22
                                                radius: 4
                                                color: isSelected ? Qt.rgba(modelData.accent.r, modelData.accent.g, modelData.accent.b, 0.25) : Theme.bgCard
                                                border.color: isSelected ? modelData.accent : Theme.borderDim
                                                border.width: 1

                                                Text {
                                                    anchors.centerIn: parent
                                                    text: "Aa"
                                                    font.family: modelData.fontDisplay
                                                    font.pixelSize: 11
                                                    font.bold: true
                                                    color: isSelected ? modelData.accent : Theme.textPrimary
                                                }
                                            }

                                            ColumnLayout {
                                                Layout.fillWidth: true
                                                spacing: 0

                                                Text {
                                                    text: modelData.name
                                                    font.family: modelData.fontDisplay
                                                    font.pixelSize: 10
                                                    font.bold: true
                                                    color: isSelected ? Theme.textPrimary : Theme.textSecondary
                                                }

                                                Text {
                                                    text: modelData.sub
                                                    font.family: Theme.fontMono
                                                    font.pixelSize: 8
                                                    color: Theme.textMuted
                                                    elide: Text.ElideRight
                                                    Layout.fillWidth: true
                                                }
                                            }

                                            Icon {
                                                visible: isSelected
                                                name: "check"
                                                size: 11
                                                color: modelData.accent || Theme.accentViolet
                                            }
                                        }

                                        MouseArea {
                                            id: fMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                ShellState.fontPreset = modelData.id;
                                                Theme.fontPreset = modelData.id;
                                                Quickshell.execDetached(["notify-send", "-a", "Antigravity", "Typography Preset", "Switched to " + modelData.name]);
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
