import QtQuick
import QtQuick.Layouts
import Quickshell
import "../theme"
import "../services"
import "../components"

Rectangle {
    id: root
    height: 34
    radius: height / 2
    color: ShellState.glassEnabled ? "transparent" : (mouseArea.containsMouse ? Theme.bgHover : Theme.bgPill)
    border.color: ShellState.glassEnabled ? "transparent" : (mouseArea.containsMouse ? Theme.accentSky : Theme.borderDim)
    border.width: ShellState.glassEnabled ? 0 : 1

    LiquidGlassSurface {
        radius: root.radius
        visible: ShellState.glassEnabled
        accentColor: DockerService.daemonRunning && DockerService.summary.running > 0 ? Theme.accentEmerald : Theme.accentSky
        hovered: mouseArea.containsMouse
        pressed: mouseArea.pressed
    }

    Behavior on color { ColorAnimation { duration: 150 } }
    Behavior on border.color { ColorAnimation { duration: 150 } }

    implicitWidth: contentRow.implicitWidth + 20

    RowLayout {
        id: contentRow
        anchors.centerIn: parent
        spacing: 7

        // Docker Layers Icon
        Icon {
            name: "layers"
            size: 14
            color: mouseArea.containsMouse ? Theme.accentSky : Theme.textPrimary
        }

        // Status indicator dot
        Rectangle {
            width: 6
            height: 6
            radius: 3
            color: {
                if (!DockerService.daemonRunning) return Theme.accentRose;
                if (DockerService.summary.running > 0) return Theme.accentEmerald;
                return Theme.textMuted;
            }

            // Gentle pulse when active containers are running (disabled in Lite Mode)
            SequentialAnimation on opacity {
                running: !ShellState.liteMode && DockerService.daemonRunning && DockerService.summary.running > 0
                loops: Animation.Infinite
                NumberAnimation { from: 1.0; to: 0.35; duration: 1200; easing.type: Easing.InOutQuad }
                NumberAnimation { from: 0.35; to: 1.0; duration: 1200; easing.type: Easing.InOutQuad }
            }
        }

        // Running Count
        Text {
            text: !DockerService.daemonRunning ? "OFFLINE" : DockerService.summary.running
            font.family: Theme.fontMono
            font.pixelSize: 11
            font.bold: true
            color: {
                if (!DockerService.daemonRunning) return Theme.accentRose;
                if (DockerService.summary.running > 0) return Theme.accentEmerald;
                return Theme.textMuted;
            }
        }

        // Total count visible on hover
        Text {
            visible: mouseArea.containsMouse && DockerService.daemonRunning
            text: "/" + DockerService.summary.total
            font.family: Theme.fontMono
            font.pixelSize: 10
            color: Theme.textMuted
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton

        onClicked: mouse => {
            if (mouse.button === Qt.LeftButton) {
                ShellState.toggleDocker();
            } else if (mouse.button === Qt.RightButton) {
                DockerService.refresh();
                DockerService.updateStats();
            }
        }
    }
}
