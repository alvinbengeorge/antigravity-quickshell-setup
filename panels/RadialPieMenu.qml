import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import "../theme"
import "../services"
import "../components"

PanelWindow {
    id: pieWindow

    visible: ShellState.pieMenuOpen
    color: "transparent"

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "quickshell:piemenu"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: ShellState.pieMenuOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    property int activeSlice: -1
    property real cursorDist: 0
    property real cursorAngle: 0
    property bool isFiring: false
    property bool hasPositioned: false

    onActiveSliceChanged: pieCanvas.requestPaint()
    onCursorAngleChanged: if (activeSlice >= 0) pieCanvas.requestPaint()

    onVisibleChanged: {
        if (visible) {
            hasPositioned = false;
            pieContainer.x = (pieWindow.width - pieContainer.width) / 2;
            pieContainer.y = (pieWindow.height - pieContainer.height) / 2;
            activeSlice = (ShellState.pieInitialSlice >= 0) ? ShellState.pieInitialSlice : -1;
            ShellState.pieInitialSlice = -1;
            cursorDist = (activeSlice >= 0) ? 140 : 0;
            cursorAngle = (activeSlice >= 0) ? ((-90 + activeSlice * 45 + 360) % 360) : 0;
            isFiring = false;
            pieCanvas.requestPaint();
            Qt.callLater(() => {
                keyHandler.forceActiveFocus();
            });
        }
    }

    // ── 8 Radial Slices Definition ──────────────────────────────────────────
    readonly property var slices: [
        {
            id: "throw_mon",
            num: "1",
            char: "🖥️",
            label: "THROW TO OTHER DISPLAY",
            shortLabel: "THROW MON",
            desc: "Move window to next screen",
            color: Theme.accentCyan,
            action: function() {
                Quickshell.execDetached(["hyprctl", "dispatch", "hl.dsp.window.move({ monitor = '+1' })"]);
            }
        },
        {
            id: "tile_right",
            num: "2",
            char: "🪟",
            label: "SPLIT TILE RIGHT",
            shortLabel: "TILE RIGHT",
            desc: "Swap window layout to right",
            color: Theme.accentSky,
            action: function() {
                Quickshell.execDetached(["hyprctl", "dispatch", "hl.dsp.window.move({ direction = 'right' })"]);
            }
        },
        {
            id: "clipboard",
            num: "3",
            char: "📋",
            label: "CLIPBOARD MANAGER",
            shortLabel: "CLIPBOARD",
            desc: "Recent snips, pins & history",
            color: Theme.accentEmerald,
            action: function() {
                ShellState.toggleClipboard();
            }
        },
        {
            id: "theme",
            num: "4",
            char: "🎨",
            label: "CYCLE THEME PALETTE",
            shortLabel: "THEME",
            desc: "Rotate desktop accents & vibes",
            color: Theme.accentViolet,
            action: function() {
                Theme.nextTheme();
            }
        },
        {
            id: "screenshot",
            num: "5",
            char: "📸",
            label: "SNIP AREA SCREENSHOT",
            shortLabel: "SNIP AREA",
            desc: "Interactive area to clipboard",
            color: Theme.accentAmber,
            action: function() {
                Quickshell.execDetached(["bash", "-c", "sleep 0.15 && grim -g \"$(slurp)\" - | wl-copy && notify-send -a Antigravity 'Screenshot Copied' 'Area copied to clipboard'"]);
            }
        },
        {
            id: "lock",
            num: "6",
            char: "🔒",
            label: "LOCK WORKSTATION",
            shortLabel: "LOCK SCREEN",
            desc: "Secure with Hyprlock",
            color: Theme.accentRose,
            action: function() {
                Quickshell.execDetached(["hyprlock"]);
            }
        },
        {
            id: "tile_left",
            num: "7",
            char: "🪟",
            label: "SPLIT TILE LEFT",
            shortLabel: "TILE LEFT",
            desc: "Swap window layout to left",
            color: Theme.accentSky,
            action: function() {
                Quickshell.execDetached(["hyprctl", "dispatch", "hl.dsp.window.move({ direction = 'left' })"]);
            }
        },
        {
            id: "omnibar",
            num: "8",
            char: "⚡",
            label: "SPOTLIGHT OMNIBAR",
            shortLabel: "OMNIBAR",
            desc: "Universal math & conversions",
            color: Theme.accentCyan,
            action: function() {
                ShellState.toggleOmnibar();
            }
        }
    ]

    function executeSlice(idx) {
        if (idx < 0 || idx >= slices.length || isFiring) return;
        isFiring = true;
        const item = slices[idx];

        // Trigger action
        if (item && item.action) {
            item.action();
        }

        // Close pie menu smoothly
        dismissTimer.restart();
    }

    Timer {
        id: dismissTimer
        interval: 100
        repeat: false
        onTriggered: {
            ShellState.pieMenuOpen = false;
            pieWindow.isFiring = false;
        }
    }

    // ── Mouse & Coordinate Math ─────────────────────────────────────────────
    function updateCoords(mx, my) {
        if (!hasPositioned && ShellState.pieInitialSlice < 0) {
            const clampX = Math.max(20, Math.min(pieWindow.width - pieContainer.width - 20, mx - pieContainer.width / 2));
            const clampY = Math.max(20, Math.min(pieWindow.height - pieContainer.height - 20, my - pieContainer.height / 2));
            pieContainer.x = clampX;
            pieContainer.y = clampY;
            hasPositioned = true;
            activeSlice = -1;
            cursorDist = 0;
            pieCanvas.requestPaint();
            return;
        }

        const pt = pieContainer.mapFromItem(backdrop, mx, my);
        const cx = pieContainer.width / 2;
        const cy = pieContainer.height / 2;
        const dx = pt.x - cx;
        const dy = pt.y - cy;
        const dist = Math.sqrt(dx * dx + dy * dy);
        pieWindow.cursorDist = dist;

        let deg = Math.atan2(dy, dx) * 180 / Math.PI;
        if (deg < 0) deg += 360;
        pieWindow.cursorAngle = deg;

        if (dist < 52) {
            pieWindow.activeSlice = -1; // Center deadzone
        } else if (dist > 260) {
            pieWindow.activeSlice = -1; // Outside wheel bounds
        } else {
            // Formula: Math.floor(((deg + 112.5) % 360) / 45)
            const sliceIdx = Math.floor(((deg + 112.5) % 360) / 45);
            pieWindow.activeSlice = Math.min(7, Math.max(0, sliceIdx));
        }
        pieCanvas.requestPaint();
    }

    // ── Dark Ambient Glass Dimmer Backdrop ──────────────────────────────────
    Rectangle {
        id: backdrop
        anchors.fill: parent
        color: "#000000"
        opacity: ShellState.pieMenuOpen ? 0.65 : 0.0

        Behavior on opacity {
            NumberAnimation { duration: 150; easing.type: Easing.OutQuad }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor

            onPositionChanged: (mouse) => pieWindow.updateCoords(mouse.x, mouse.y)

            onClicked: (mouse) => {
                if (pieWindow.activeSlice >= 0) {
                    pieWindow.executeSlice(pieWindow.activeSlice);
                } else {
                    ShellState.pieMenuOpen = false;
                }
            }
        }
    }

    // ── Keyboard Focus Catcher ──────────────────────────────────────────────
    Item {
        id: keyHandler
        anchors.fill: parent
        focus: true

        Keys.onEscapePressed: ShellState.pieMenuOpen = false
        Keys.onReturnPressed: if (pieWindow.activeSlice >= 0) pieWindow.executeSlice(pieWindow.activeSlice)
        Keys.onEnterPressed: if (pieWindow.activeSlice >= 0) pieWindow.executeSlice(pieWindow.activeSlice)
        Keys.onSpacePressed: if (pieWindow.activeSlice >= 0) pieWindow.executeSlice(pieWindow.activeSlice)

        Keys.onDigit1Pressed: pieWindow.executeSlice(0)
        Keys.onDigit2Pressed: pieWindow.executeSlice(1)
        Keys.onDigit3Pressed: pieWindow.executeSlice(2)
        Keys.onDigit4Pressed: pieWindow.executeSlice(3)
        Keys.onDigit5Pressed: pieWindow.executeSlice(4)
        Keys.onDigit6Pressed: pieWindow.executeSlice(5)
        Keys.onDigit7Pressed: pieWindow.executeSlice(6)
        Keys.onDigit8Pressed: pieWindow.executeSlice(7)

        Keys.onUpPressed: { pieWindow.activeSlice = 0; pieCanvas.requestPaint(); }
        Keys.onRightPressed: { pieWindow.activeSlice = 2; pieCanvas.requestPaint(); }
        Keys.onDownPressed: { pieWindow.activeSlice = 4; pieCanvas.requestPaint(); }
        Keys.onLeftPressed: { pieWindow.activeSlice = 6; pieCanvas.requestPaint(); }
    }

    // ── Radial Pie Container ────────────────────────────────────────────────
    Item {
        id: pieContainer
        width: 520
        height: 520
        anchors.centerIn: parent

        scale: ShellState.pieMenuOpen ? 1.0 : 0.85
        opacity: ShellState.pieMenuOpen ? 1.0 : 0.0

        Behavior on scale {
            NumberAnimation { duration: 200; easing.type: Easing.OutBack }
        }
        Behavior on opacity {
            NumberAnimation { duration: 150; easing.type: Easing.OutQuad }
        }

        // ── Canvas: Sci-Fi Segmented Wheel & HUD Lines ──────────────────────
        Canvas {
            id: pieCanvas
            anchors.fill: parent

            onPaint: {
                const ctx = getContext("2d");
                ctx.reset();

                const cx = width / 2;
                const cy = height / 2;
                const R = 210;
                const r = 74;
                const halfSpan = (20.5 * Math.PI) / 180;

                // 1. Draw 8 annular segments
                for (let i = 0; i < 8; i++) {
                    const centerAngle = ((-90 + i * 45) * Math.PI) / 180;
                    const startAngle = centerAngle - halfSpan;
                    const endAngle = centerAngle + halfSpan;
                    const isActive = (i === pieWindow.activeSlice);

                    const curOuter = isActive ? (R + 10) : R;
                    const curInner = isActive ? (r - 2) : r;

                    ctx.beginPath();
                    ctx.arc(cx, cy, curOuter, startAngle, endAngle, false);
                    ctx.arc(cx, cy, curInner, endAngle, startAngle, true);
                    ctx.closePath();

                    if (isActive) {
                        const col = pieWindow.slices[i].color;
                        ctx.fillStyle = Qt.rgba(col.r, col.g, col.b, 0.32);
                        ctx.fill();

                        ctx.lineWidth = 2.5;
                        ctx.strokeStyle = col;
                        ctx.stroke();
                    } else {
                        ctx.fillStyle = Qt.rgba(14/255, 18/255, 27/255, 0.82);
                        ctx.fill();

                        ctx.lineWidth = 1.0;
                        ctx.strokeStyle = Qt.rgba(255, 255, 255, 0.12);
                        ctx.stroke();
                    }
                }

                // 2. Outer Orbit Tech Ring
                ctx.beginPath();
                ctx.arc(cx, cy, R + 22, 0, 2 * Math.PI);
                ctx.lineWidth = 1.0;
                ctx.strokeStyle = Qt.rgba(255, 255, 255, 0.08);
                ctx.stroke();

                // 3. Orbit Tick marks at 45 degree intervals
                for (let j = 0; j < 8; j++) {
                    const angle = ((-90 + j * 45) * Math.PI) / 180;
                    const t1x = cx + (R + 18) * Math.cos(angle);
                    const t1y = cy + (R + 18) * Math.sin(angle);
                    const t2x = cx + (R + 26) * Math.cos(angle);
                    const t2y = cy + (R + 26) * Math.sin(angle);

                    ctx.beginPath();
                    ctx.moveTo(t1x, t1y);
                    ctx.lineTo(t2x, t2y);
                    ctx.lineWidth = 2.0;
                    ctx.strokeStyle = (j === pieWindow.activeSlice) ? pieWindow.slices[j].color : Qt.rgba(255, 255, 255, 0.25);
                    ctx.stroke();
                }

                // 4. Directional Laser Pointer Needle towards Cursor
                if (pieWindow.activeSlice >= 0 && pieWindow.cursorDist > 55) {
                    const curRad = (pieWindow.cursorAngle * Math.PI) / 180;
                    const col = pieWindow.slices[pieWindow.activeSlice].color;

                    ctx.beginPath();
                    ctx.moveTo(cx + (r + 4) * Math.cos(curRad), cy + (r + 4) * Math.sin(curRad));
                    ctx.lineTo(cx + (R + 8) * Math.cos(curRad), cy + (R + 8) * Math.sin(curRad));
                    ctx.lineWidth = 2.0;
                    ctx.strokeStyle = Qt.rgba(col.r, col.g, col.b, 0.70);
                    ctx.stroke();
                }
            }
        }

        // ── 8 Radial Slice Widgets (Cards) ──────────────────────────────────
        Repeater {
            model: pieWindow.slices

            delegate: Item {
                width: 76
                height: 56

                readonly property real angleRad: ((-90 + index * 45) * Math.PI) / 180
                property real radiusDist: (index === pieWindow.activeSlice) ? 146 : 142
                readonly property bool isActive: (index === pieWindow.activeSlice)

                x: (pieContainer.width / 2) + radiusDist * Math.cos(angleRad) - width / 2
                y: (pieContainer.height / 2) + radiusDist * Math.sin(angleRad) - height / 2

                Behavior on radiusDist { NumberAnimation { duration: 120 } }

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 2

                    // Hotkey badge + Emoji Row
                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 4

                        Rectangle {
                            width: 15
                            height: 15
                            radius: 3
                            color: isActive ? modelData.color : Theme.bgHover
                            border.color: isActive ? modelData.color : Theme.borderDim
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: modelData.num
                                font.family: Theme.fontMono
                                font.pixelSize: 9
                                font.bold: true
                                color: isActive ? Theme.textOnAccent : Theme.textMuted
                            }
                        }

                        Text {
                            text: modelData.char
                            font.pixelSize: isActive ? 22 : 18
                            scale: isActive ? 1.15 : 1.0

                            Behavior on scale { NumberAnimation { duration: 120 } }
                        }
                    }

                    // Short Label
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: modelData.shortLabel
                        font.family: Theme.fontMono
                        font.pixelSize: 9
                        font.bold: true
                        color: isActive ? modelData.color : Theme.textSecondary
                    }
                }
            }
        }

        // ── Center Hub Singularity (Diameter 144px) ─────────────────────────
        Rectangle {
            id: centerHub
            width: 144
            height: 144
            radius: 72
            anchors.centerIn: parent
            color: ShellState.glassEnabled ? "transparent" : Theme.bgCard
            border.color: (pieWindow.activeSlice >= 0) ? pieWindow.slices[pieWindow.activeSlice].color : Theme.borderDim
            border.width: (pieWindow.activeSlice >= 0) ? 2 : 1

            Behavior on border.color { ColorAnimation { duration: 150 } }

            LiquidGlassSurface {
                radius: 72
                visible: ShellState.glassEnabled
                accentColor: (pieWindow.activeSlice >= 0) ? pieWindow.slices[pieWindow.activeSlice].color : Theme.accentCyan
                showShadow: true
            }

            // Glow core ring
            Rectangle {
                anchors.fill: parent
                anchors.margins: 4
                radius: 68
                color: (pieWindow.activeSlice >= 0)
                    ? Qt.rgba(pieWindow.slices[pieWindow.activeSlice].color.r, pieWindow.slices[pieWindow.activeSlice].color.g, pieWindow.slices[pieWindow.activeSlice].color.b, 0.12)
                    : Qt.rgba(Theme.accentCyan.r, Theme.accentCyan.g, Theme.accentCyan.b, 0.05)
                border.color: Qt.rgba(255, 255, 255, 0.06)
                border.width: 1
            }

            // Dynamic Content: Active Slice View OR Idle Center View
            ColumnLayout {
                anchors.centerIn: parent
                spacing: 3
                Layout.maximumWidth: 126

                // ── State A: Active Hovered Slice ──
                Item {
                    visible: pieWindow.activeSlice >= 0
                    Layout.alignment: Qt.AlignHCenter
                    width: 32
                    height: 32

                    Text {
                        anchors.centerIn: parent
                        text: (pieWindow.activeSlice >= 0) ? pieWindow.slices[pieWindow.activeSlice].char : ""
                        font.pixelSize: 28
                    }
                }

                Text {
                    visible: pieWindow.activeSlice >= 0
                    Layout.alignment: Qt.AlignHCenter
                    text: (pieWindow.activeSlice >= 0) ? pieWindow.slices[pieWindow.activeSlice].shortLabel : ""
                    font.family: Theme.fontMono
                    font.pixelSize: 11
                    font.bold: true
                    color: (pieWindow.activeSlice >= 0) ? pieWindow.slices[pieWindow.activeSlice].color : Theme.textPrimary
                }

                Text {
                    visible: pieWindow.activeSlice >= 0
                    Layout.alignment: Qt.AlignHCenter
                    text: (pieWindow.activeSlice >= 0) ? pieWindow.slices[pieWindow.activeSlice].desc : ""
                    font.family: Theme.fontFamily
                    font.pixelSize: 8
                    color: Theme.textMuted
                    elide: Text.ElideRight
                    Layout.maximumWidth: 110
                    horizontalAlignment: Text.AlignHCenter
                }

                Rectangle {
                    visible: pieWindow.activeSlice >= 0
                    Layout.alignment: Qt.AlignHCenter
                    height: 18
                    radius: 4
                    implicitWidth: clickPillTxt.implicitWidth + 10
                    color: (pieWindow.activeSlice >= 0) ? pieWindow.slices[pieWindow.activeSlice].color : Theme.accentCyan

                    Text {
                        id: clickPillTxt
                        anchors.centerIn: parent
                        text: "Click / ↵ to Run"
                        font.family: Theme.fontMono
                        font.pixelSize: 8
                        font.bold: true
                        color: Theme.textOnAccent
                    }
                }

                // ── State B: Idle Singularity State ──
                Text {
                    visible: pieWindow.activeSlice < 0
                    Layout.alignment: Qt.AlignHCenter
                    text: "⚡"
                    font.pixelSize: 24
                    color: Theme.accentCyan
                }

                Text {
                    visible: pieWindow.activeSlice < 0
                    Layout.alignment: Qt.AlignHCenter
                    text: "GESTURE HUD"
                    font.family: Theme.fontMono
                    font.pixelSize: 11
                    font.bold: true
                    color: Theme.accentCyan
                }

                Text {
                    visible: pieWindow.activeSlice < 0
                    Layout.alignment: Qt.AlignHCenter
                    text: "Flick or keys 1–8"
                    font.family: Theme.fontMono
                    font.pixelSize: 8
                    color: Theme.accentAmber
                }

                Text {
                    visible: pieWindow.activeSlice < 0
                    Layout.alignment: Qt.AlignHCenter
                    text: "[Esc] Dismiss"
                    font.family: Theme.fontMono
                    font.pixelSize: 8
                    color: Theme.textMuted
                }
            }
        }
    }
}
