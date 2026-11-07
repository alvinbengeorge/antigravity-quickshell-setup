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
