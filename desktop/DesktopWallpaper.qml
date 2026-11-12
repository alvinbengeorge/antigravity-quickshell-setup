import QtQuick
import Quickshell
import Quickshell.Wayland
import "../theme"
import "../services"

PanelWindow {
    id: root

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "quickshell:desktop:wallpaper"
    WlrLayershell.layer: WlrLayer.Background

    // Base background color with smooth transition
    Rectangle {
        anchors.fill: parent
        color: Theme.bgBase
        Behavior on color { ColorAnimation { duration: 800 } }
    }

    // Procedural Ambient Glow Orbs
    Item {
        anchors.fill: parent
        visible: !ShellState.liteMode

        // Top-left ambient nebula orb
        Rectangle {
            width: root.width * 0.75
            height: root.height * 0.75
            radius: width / 2
            x: -width * 0.2
            y: -height * 0.2
            color: Theme.accentViolet
            opacity: 0.14

            Behavior on color { ColorAnimation { duration: 1200 } }
        }

        // Bottom-right ambient glow orb
        Rectangle {
            width: root.width * 0.75
            height: root.height * 0.75
            radius: width / 2
            x: root.width - width * 0.8
            y: root.height - height * 0.8
            color: Theme.accentSky
            opacity: 0.12

            Behavior on color { ColorAnimation { duration: 1200 } }
        }
    }

    // Image Cross-Fading Layers
    Item {
        id: crossFadeLayer
        anchors.fill: parent
        visible: WallpaperService.mode !== "gradient" && WallpaperService.currentWallpaper.length > 0

        property bool activeIsA: true

        Image {
            id: imgA
            anchors.fill: parent
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: true
            opacity: 1.0

            Behavior on opacity {
                NumberAnimation { duration: 800; easing.type: Easing.InOutQuad }
            }
        }

        Image {
            id: imgB
            anchors.fill: parent
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: true
            opacity: 0.0

            Behavior on opacity {
                NumberAnimation { duration: 800; easing.type: Easing.InOutQuad }
            }
        }

        function loadWallpaper(url) {
            if (!url || url.length === 0) return;
            const fullUrl = url.startsWith("file://") ? url : ("file://" + url);
            if (activeIsA) {
                imgB.source = fullUrl;
                imgB.opacity = 1.0;
                imgA.opacity = 0.0;
                activeIsA = false;
            } else {
                imgA.source = fullUrl;
                imgA.opacity = 1.0;
                imgB.opacity = 0.0;
                activeIsA = true;
            }
        }
    }

    // Subtle dark scrim overlay for UI contrast
    Rectangle {
        anchors.fill: parent
        color: "#000000"
        opacity: WallpaperService.dimOpacity

        Behavior on opacity {
            NumberAnimation { duration: 400 }
        }
    }

    // Celestial Skybox: Procedural Starfield & Constellations
    Item {
        id: skyboxLayer
        anchors.fill: parent
        visible: opacity > 0
        opacity: (ShellState.skyboxEnabled && !ShellState.liteMode) ? 1.0 : 0.0

        Behavior on opacity {
            NumberAnimation { duration: 800; easing.type: Easing.InOutQuad }
        }

        Canvas {
            id: skyCanvas
            anchors.fill: parent

            property real twinkle: 1.0
            property var stars: []
            property var constellations: []

            SequentialAnimation on twinkle {
                running: skyboxLayer.visible
                loops: Animation.Infinite
                NumberAnimation { to: 0.65; duration: 2400; easing.type: Easing.InOutSine }
                NumberAnimation { to: 1.0; duration: 2400; easing.type: Easing.InOutSine }
            }

            onTwinkleChanged: requestPaint()

            function initSkybox() {
                if (width <= 0 || height <= 0) return;
                const starList = [];
                // Deterministic pseudo-random distribution
                const count = 110;
                let seed = 42;
                function rnd() {
                    seed = (seed * 9301 + 49297) % 233280;
                    return seed / 233280;
                }

                for (let i = 0; i < count; i++) {
                    const sx = rnd() * width;
                    const sy = rnd() * (height * 0.75); // Concentrate stars on upper 75%
                    const sr = 0.8 + rnd() * 1.5;
                    const isTwinkler = (i % 5 === 0);
                    const tint = (i % 3 === 0) ? "#E0F2FE" : ((i % 4 === 0) ? "#FEF3C7" : "#FFFFFF");
                    starList.push({ x: sx, y: sy, r: sr, tw: isTwinkler, tint: tint, baseAlpha: 0.35 + rnd() * 0.55 });
                }
                stars = starList;

                // Subtle constellation lines
                const cx1 = width * 0.22, cy1 = height * 0.18;
                const c1 = [
                    { x: cx1, y: cy1 },
                    { x: cx1 + 45, y: cy1 - 25 },
                    { x: cx1 + 95, y: cy1 - 15 },
                    { x: cx1 + 140, y: cy1 - 45 },
                    { x: cx1 + 125, y: cy1 + 15 },
                    { x: cx1 + 55, y: cy1 + 25 },
                    { x: cx1, y: cy1 }
                ];

                const cx2 = width * 0.72, cy2 = height * 0.15;
                const c2 = [
                    { x: cx2, y: cy2 },
                    { x: cx2 + 35, y: cy2 + 30 },
                    { x: cx2 + 75, y: cy2 + 10 },
                    { x: cx2 + 115, y: cy2 + 40 },
                    { x: cx2 + 155, y: cy2 + 20 }
                ];

                constellations = [c1, c2];
                requestPaint();
            }

            onWidthChanged: initSkybox()
            onHeightChanged: initSkybox()
            Component.onCompleted: initSkybox()

            onPaint: {
                const ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);

                // 1. Draw Constellation Lines
                ctx.strokeStyle = "rgba(186, 230, 253, 0.15)";
                ctx.lineWidth = 1;
                for (let c = 0; c < constellations.length; c++) {
                    const pts = constellations[c];
                    if (pts.length > 1) {
                        ctx.beginPath();
                        ctx.moveTo(pts[0].x, pts[0].y);
                        for (let p = 1; p < pts.length; p++) {
                            ctx.lineTo(pts[p].x, pts[p].y);
                        }
                        ctx.stroke();

                        // Constellation star joints
                        for (let p = 0; p < pts.length; p++) {
                            ctx.fillStyle = "rgba(224, 242, 254, 0.8)";
                            ctx.beginPath();
                            ctx.arc(pts[p].x, pts[p].y, 2.2, 0, 2 * Math.PI);
                            ctx.fill();
                        }
                    }
                }

                // 2. Draw Stars
                for (let i = 0; i < stars.length; i++) {
                    const s = stars[i];
                    const alpha = s.tw ? (s.baseAlpha * twinkle) : s.baseAlpha;
                    ctx.fillStyle = s.tint;
                    ctx.globalAlpha = Math.min(1.0, Math.max(0.1, alpha));
                    ctx.beginPath();
                    ctx.arc(s.x, s.y, s.r, 0, 2 * Math.PI);
                    ctx.fill();
                }
                ctx.globalAlpha = 1.0;

                // 3. Subtle Crescent Moon Glow in Top-Right
                const mx = width * 0.88;
                const my = height * 0.14;
                const moonGlow = ctx.createRadialGradient(mx, my, 4, mx, my, 45);
                moonGlow.addColorStop(0, "rgba(254, 243, 199, 0.22)");
                moonGlow.addColorStop(0.5, "rgba(224, 242, 254, 0.08)");
                moonGlow.addColorStop(1, "rgba(0, 0, 0, 0)");
                ctx.fillStyle = moonGlow;
                ctx.beginPath();
                ctx.arc(mx, my, 45, 0, 2 * Math.PI);
                ctx.fill();

                // Moon Disc with subtle shadow to create a crescent
                ctx.fillStyle = "rgba(254, 243, 199, 0.88)";
                ctx.beginPath();
                ctx.arc(mx, my, 12, 0, 2 * Math.PI);
                ctx.fill();

                ctx.fillStyle = "rgba(15, 23, 42, 0.92)";
                ctx.beginPath();
                ctx.arc(mx + 5, my - 3, 11, 0, 2 * Math.PI);
                ctx.fill();
            }
        }
    }

    // React to wallpaper source changes
    Connections {
        target: WallpaperService
        function onCurrentWallpaperChanged() {
            crossFadeLayer.loadWallpaper(WallpaperService.currentWallpaper);
        }
    }

    Component.onCompleted: {
        crossFadeLayer.loadWallpaper(WallpaperService.currentWallpaper);
    }
}
