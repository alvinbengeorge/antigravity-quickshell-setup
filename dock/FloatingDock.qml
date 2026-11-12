import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import "../theme"
import "../services"
import "../components"

PanelWindow {
    id: dockWindow

    anchors {
        bottom: true
    }
    margins {
        bottom: 12
    }

    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "quickshell:floatingdock"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    visible: ShellState.dockEnabled && !ShellState.liteMode
    color: "transparent"

    implicitWidth: Math.max(540, dockRow.implicitWidth + 48)
    implicitHeight: 90

    // ── Pinned Apps Definition ──────────────────────────────────────────────
    readonly property var pinnedApps: [
        {
            id: "terminal",
            name: "Terminal",
            icon: "terminal.svg",
            cmd: ["kitty"],
            matchClass: "kitty"
        },
        {
            id: "browser",
            name: "Chrome",
            icon: "globe.svg",
            cmd: ["google-chrome"],
            matchClass: "chromium-browser"
        },
        {
            id: "files",
            name: "Files",
            icon: "folder.svg",
            cmd: ["nautilus"],
            matchClass: "org.gnome.Nautilus"
        },
        {
            id: "whatsapp",
            name: "WhatsApp",
            icon: "whatsapp.svg",
            action: function() { ShellState.toggleWhatsApp(); },
            matchClass: "whatsapp"
        },
        {
            id: "music",
            name: "Media Player",
            icon: "music.svg",
            action: function() { ShellState.toggleMediaCard(); },
            matchClass: "spotify"
        },
        {
            id: "omnibar",
            name: "Spotlight",
            icon: "zap.svg",
            action: function() { ShellState.toggleOmnibar(); }
        },
        {
            id: "cc",
            name: "Control Center",
            icon: "sliders.svg",
            action: function() { ShellState.toggleControlCenter(); }
        }
    ]

    // ── Utility Right Stack ─────────────────────────────────────────────────
    readonly property var utilityApps: [
        {
            id: "wallpaper",
            name: "Wallpaper & Themes",
            icon: "image.svg",
            action: function() { ShellState.toggleWallpaperThemeDialog(); }
        },
        {
            id: "clipboard",
            name: "Clipboard History",
            icon: "copy.svg",
            action: function() { ShellState.toggleClipboard(); }
        },
        {
            id: "launcher",
            name: "Applications",
            icon: "search.svg",
            action: function() { ShellState.toggleLauncher(); }
        }
    ]

    // Helper: Find open windows matching an app
    function getWindowsForApp(matchClass) {
        if (!matchClass || !WindowService.windows) return [];
        return WindowService.windows.filter(w => {
            if (!w.class) return false;
            const c = w.class.toLowerCase();
            return c.includes(matchClass.toLowerCase());
        });
    }

    // Helper: Is any window for this app currently active/focused?
    function isAppActive(matchClass) {
        const wins = getWindowsForApp(matchClass);
        for (let i = 0; i < wins.length; i++) {
            if (wins[i].is_active) return true;
        }
        return false;
    }

    // ── Dynamic Running Windows (Not in pinned apps) ────────────────────────
    readonly property var dynamicRunningWindows: {
        const wins = WindowService.windows || [];
        const pinnedClasses = ["kitty", "chromium-browser", "google-chrome", "org.gnome.nautilus", "whatsapp", "spotify"];
        const extra = [];
        const seenClasses = new Set();

        for (let i = 0; i < wins.length; i++) {
            const w = wins[i];
            if (!w || !w.class) continue;
            const cls = w.class.toLowerCase();
            // Skip pinned apps or scratchpads
            if (pinnedClasses.some(p => cls.includes(p))) continue;
            if (cls.includes("scratchpad")) continue;
            if (seenClasses.has(cls)) continue;
            seenClasses.add(cls);

            extra.push({
                id: "win_" + w.address,
                name: w.title || w.class,
                class: w.class,
                address: w.address,
                glyph: w.glyph || "🪟",
                is_active: w.is_active || false
            });
        }
        return extra;
    }

    // ── Floating Dock Main Capsule ──────────────────────────────────────────
    Rectangle {
        id: dockCard
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        height: 60
        width: dockRow.implicitWidth + 28
        radius: 30

        color: ShellState.glassEnabled ? "transparent" : (Theme.bgSurfaceGlass || Theme.bgSurface)
        border.color: ShellState.glassEnabled ? "transparent" : Qt.rgba(255, 255, 255, 0.12)
        border.width: ShellState.glassEnabled ? 0 : 1

        Behavior on width {
            NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
        }

        // 3D Liquid Glass Surface
        LiquidGlassSurface {
            radius: 30
            visible: ShellState.glassEnabled
            accentColor: Theme.accentCyan
            showShadow: true
            hovered: dockMouseArea.containsMouse
        }

        // Subtle ambient edge highlight
        Rectangle {
            anchors.fill: parent
            radius: 30
            color: "transparent"
            border.color: dockMouseArea.containsMouse
                ? Qt.rgba(Theme.accentCyan.r, Theme.accentCyan.g, Theme.accentCyan.b, 0.28)
                : Qt.rgba(255, 255, 255, 0.08)
            border.width: 1
            Behavior on border.color { ColorAnimation { duration: 180 } }
        }

        // ── Unified Mouse Area for Parabolic Physics ────────────────────────
        MouseArea {
            id: dockMouseArea
            anchors.fill: parent
            hoverEnabled: true

            property real cursorX: -1000
            property real cursorY: -1000
            property string hoveredName: ""

            onPositionChanged: (mouse) => {
                cursorX = mouse.x;
                cursorY = mouse.y;
            }
            onExited: {
                cursorX = -1000;
                cursorY = -1000;
                hoveredName = "";
            }
        }

        // ── Icons Layout Row ────────────────────────────────────────────────
        Row {
            id: dockRow
            anchors.centerIn: parent
            spacing: 8

            // ── Section 1: Pinned Daily Drivers ──
            Repeater {
                model: dockWindow.pinnedApps

                delegate: Item {
                    id: pinnedItem
                    width: 44
                    height: 52

                    // Parabolic distance calculation
                    readonly property real centerInMouseArea: mapToItem(dockMouseArea, width / 2, 0).x
                    readonly property real dist: Math.abs(dockMouseArea.cursorX - centerInMouseArea)
                    readonly property real radiusSpan: 96
                    readonly property real factor: {
                        if (!dockMouseArea.containsMouse || dist >= radiusSpan) return 0.0;
                        const cosVal = Math.cos((dist / radiusSpan) * (Math.PI / 2));
                        return cosVal * cosVal;
                    }

                    scale: 1.0 + 0.42 * factor
                    y: -14.0 * factor

                    Behavior on scale { NumberAnimation { duration: 90; easing.type: Easing.OutQuad } }
                    Behavior on y { NumberAnimation { duration: 90; easing.type: Easing.OutQuad } }

                    onFactorChanged: {
                        if (factor > 0.6) {
                            dockMouseArea.hoveredName = modelData.name;
                        }
                    }

                    // Icon Container
                    Rectangle {
                        id: iconContainer
                        width: 40
                        height: 40
                        radius: 12
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: parent.top
                        anchors.topMargin: 2
                        color: pinnedItem.factor > 0.5 ? Qt.rgba(Theme.accentCyan.r, Theme.accentCyan.g, Theme.accentCyan.b, 0.22) : Theme.bgHover
                        border.color: pinnedItem.factor > 0.5 ? Theme.accentCyan : Theme.borderDim
                        border.width: 1

                        Image {
                            anchors.centerIn: parent
                            width: 22
                            height: 22
                            source: Qt.resolvedUrl("../assets/icons/" + modelData.icon)
                            sourceSize: Qt.size(44, 44)
                            smooth: true
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            hoverEnabled: true
                            onPositionChanged: (mouse) => {
                                const pt = mapToItem(dockMouseArea, mouse.x, mouse.y);
                                dockMouseArea.cursorX = pt.x;
                                dockMouseArea.cursorY = pt.y;
                            }
                            onClicked: {
                                // Bounce effect
                                bounceAnim.restart();

                                const wins = dockWindow.getWindowsForApp(modelData.matchClass);
                                if (wins.length > 0) {
                                    // Focus active or next window
                                    WindowService.focusWindow(wins[0].address);
                                } else if (modelData.action) {
                                    modelData.action();
                                } else if (modelData.cmd) {
                                    Quickshell.execDetached(modelData.cmd);
                                }
                            }
                        }

                        SequentialAnimation on scale {
                            id: bounceAnim
                            running: false
                            NumberAnimation { to: 0.85; duration: 80; easing.type: Easing.OutQuad }
                            NumberAnimation { to: 1.15; duration: 120; easing.type: Easing.OutBack }
                            NumberAnimation { to: 1.0; duration: 100; easing.type: Easing.OutQuad }
                        }
                    }

                    // ── Running LED Indicator Dot ──
                    Rectangle {
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 1
                        anchors.horizontalCenter: parent.horizontalCenter

                        readonly property var openWins: dockWindow.getWindowsForApp(modelData.matchClass)
                        readonly property bool hasWins: openWins.length > 0
                        readonly property bool isActive: dockWindow.isAppActive(modelData.matchClass)

                        visible: hasWins
                        width: isActive ? 14 : 4
                        height: 3.5
                        radius: 2
                        color: isActive ? Theme.accentCyan : Theme.accentAmber

                        Behavior on width { NumberAnimation { duration: 150 } }
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                }
            }

            // ── Section 2: Dynamic Running Windows (if any) ──
            Repeater {
                model: dockWindow.dynamicRunningWindows

                delegate: Item {
                    id: dynItem
                    width: 44
                    height: 52

                    readonly property real centerInMouseArea: mapToItem(dockMouseArea, width / 2, 0).x
                    readonly property real dist: Math.abs(dockMouseArea.cursorX - centerInMouseArea)
                    readonly property real radiusSpan: 96
                    readonly property real factor: {
                        if (!dockMouseArea.containsMouse || dist >= radiusSpan) return 0.0;
                        const cosVal = Math.cos((dist / radiusSpan) * (Math.PI / 2));
                        return cosVal * cosVal;
                    }

                    scale: 1.0 + 0.42 * factor
                    y: -14.0 * factor

                    Behavior on scale { NumberAnimation { duration: 90; easing.type: Easing.OutQuad } }
                    Behavior on y { NumberAnimation { duration: 90; easing.type: Easing.OutQuad } }

                    onFactorChanged: {
                        if (factor > 0.6) {
                            dockMouseArea.hoveredName = modelData.name;
                        }
                    }

                    Rectangle {
                        width: 40
                        height: 40
                        radius: 12
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: parent.top
                        anchors.topMargin: 2
                        color: dynItem.factor > 0.5 ? Qt.rgba(Theme.accentSky.r, Theme.accentSky.g, Theme.accentSky.b, 0.22) : Theme.bgHover
                        border.color: dynItem.factor > 0.5 ? Theme.accentSky : Theme.borderDim
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: modelData.glyph || "🪟"
                            font.pixelSize: 20
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            hoverEnabled: true
                            onPositionChanged: (mouse) => {
                                const pt = mapToItem(dockMouseArea, mouse.x, mouse.y);
                                dockMouseArea.cursorX = pt.x;
                                dockMouseArea.cursorY = pt.y;
                            }
                            onClicked: {
                                WindowService.focusWindow(modelData.address);
                            }
                        }
                    }

                    // Running LED Indicator
                    Rectangle {
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 1
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: modelData.is_active ? 14 : 4
                        height: 3.5
                        radius: 2
                        color: modelData.is_active ? Theme.accentCyan : Theme.accentAmber
                    }
                }
            }

            // ── Frosted Glass Divider ──
            Item {
                width: 9
                height: 52
                Rectangle {
                    anchors.centerIn: parent
                    width: 1
                    height: 28
                    radius: 0.5
                    color: Qt.rgba(255, 255, 255, 0.20)
                }
            }

            // ── Section 3: Utility Stacks ──
            Repeater {
                model: dockWindow.utilityApps

                delegate: Item {
                    id: utilItem
                    width: 44
                    height: 52

                    readonly property real centerInMouseArea: mapToItem(dockMouseArea, width / 2, 0).x
                    readonly property real dist: Math.abs(dockMouseArea.cursorX - centerInMouseArea)
                    readonly property real radiusSpan: 96
                    readonly property real factor: {
                        if (!dockMouseArea.containsMouse || dist >= radiusSpan) return 0.0;
                        const cosVal = Math.cos((dist / radiusSpan) * (Math.PI / 2));
                        return cosVal * cosVal;
                    }

                    scale: 1.0 + 0.42 * factor
                    y: -14.0 * factor

                    Behavior on scale { NumberAnimation { duration: 90; easing.type: Easing.OutQuad } }
                    Behavior on y { NumberAnimation { duration: 90; easing.type: Easing.OutQuad } }

                    onFactorChanged: {
                        if (factor > 0.6) {
                            dockMouseArea.hoveredName = modelData.name;
                        }
                    }

                    Rectangle {
                        width: 40
                        height: 40
                        radius: 12
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: parent.top
                        anchors.topMargin: 2
                        color: utilItem.factor > 0.5 ? Qt.rgba(Theme.accentViolet.r, Theme.accentViolet.g, Theme.accentViolet.b, 0.22) : Theme.bgHover
                        border.color: utilItem.factor > 0.5 ? Theme.accentViolet : Theme.borderDim
                        border.width: 1

                        Image {
                            anchors.centerIn: parent
                            width: 20
                            height: 20
                            source: Qt.resolvedUrl("../assets/icons/" + modelData.icon)
                            sourceSize: Qt.size(40, 40)
                            smooth: true
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            hoverEnabled: true
                            onPositionChanged: (mouse) => {
                                const pt = mapToItem(dockMouseArea, mouse.x, mouse.y);
                                dockMouseArea.cursorX = pt.x;
                                dockMouseArea.cursorY = pt.y;
                            }
                            onClicked: {
                                if (modelData.action) modelData.action();
                            }
                        }
                    }
                }
            }
        }

        // ── Floating Tooltip Pill (Above Active Item) ────────────────────────
        Rectangle {
            id: tooltipPill
            visible: dockMouseArea.containsMouse && dockMouseArea.hoveredName.length > 0
            anchors.bottom: dockCard.top
            anchors.bottomMargin: 10
            anchors.horizontalCenter: parent.horizontalCenter
            height: 24
            implicitWidth: tooltipTxt.implicitWidth + 16
            radius: 6
            color: Theme.bgModal
            border.color: Theme.accentCyan
            border.width: 1

            opacity: visible ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 120 } }

            Text {
                id: tooltipTxt
                anchors.centerIn: parent
                text: dockMouseArea.hoveredName
                font.family: Theme.fontMono
                font.pixelSize: 10
                font.bold: true
                color: Theme.accentCyan
            }
        }
    }
}
