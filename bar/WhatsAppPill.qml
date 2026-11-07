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
    border.color: ShellState.glassEnabled ? "transparent" : (mouseArea.containsMouse ? Theme.accentEmerald : (WhatsAppService.status === "ready" && WhatsAppService.unreadCount > 0 ? Theme.accentEmerald : Theme.borderDim))
    border.width: ShellState.glassEnabled ? 0 : 1

    LiquidGlassSurface {
        radius: root.radius
        visible: ShellState.glassEnabled
        accentColor: WhatsAppService.unreadCount > 0 ? Theme.accentEmerald : Theme.accentCyan
        hovered: mouseArea.containsMouse
    }

    Behavior on color { ColorAnimation { duration: 150 } }
    Behavior on border.color { ColorAnimation { duration: 150 } }

    implicitWidth: contentRow.implicitWidth + 20

    RowLayout {
        id: contentRow
        anchors.centerIn: parent
        spacing: 6

        // WhatsApp Icon
        Icon {
            name: "whatsapp"
            size: 14
            color: {
                if (WhatsAppService.status === "ready") return "#25D366";
                if (WhatsAppService.status === "qr_ready") return Theme.accentCyan;
                if (WhatsAppService.status === "disconnected") return Theme.accentAmber;
                if (WhatsAppService.status === "offline") return Theme.accentRose;
                return Theme.textMuted;
            }
        }

        // Status indicator dot
        Rectangle {
            width: 6
            height: 6
            radius: 3
            color: {
                if (WhatsAppService.status === "ready") return "#25D366";
                if (WhatsAppService.status === "qr_ready") return Theme.accentCyan;
                if (WhatsAppService.status === "reconnecting" || WhatsAppService.status === "loading") return Theme.accentSky;
                if (WhatsAppService.status === "disconnected") return Theme.accentAmber;
                return Theme.accentRose;
            }

            // Pulse animation when unread messages > 0 or initializing
            SequentialAnimation on opacity {
                running: !ShellState.liteMode && (WhatsAppService.unreadCount > 0 || WhatsAppService.status === "reconnecting")
                loops: Animation.Infinite
                NumberAnimation { from: 1.0; to: 0.35; duration: 1000; easing.type: Easing.InOutQuad }
                NumberAnimation { from: 0.35; to: 1.0; duration: 1000; easing.type: Easing.InOutQuad }
            }
        }

        // Status label / Unread Counter
        Text {
            text: {
                if (WhatsAppService.status === "ready") {
                    return WhatsAppService.unreadCount > 0 ? (WhatsAppService.unreadCount + " new") : "WA";
                }
                if (WhatsAppService.status === "qr_ready") return "QR";
                if (WhatsAppService.status === "reconnecting") return "CONN...";
                if (WhatsAppService.status === "disconnected") return "OFF";
                if (WhatsAppService.status === "offline") return "DOWN";
                return "...";
            }
            font.family: Theme.fontMono
            font.pixelSize: 11
            font.bold: true
            color: {
                if (WhatsAppService.status === "ready") {
                    return WhatsAppService.unreadCount > 0 ? "#25D366" : Theme.textPrimary;
                }
                if (WhatsAppService.status === "qr_ready") return Theme.accentCyan;
                if (WhatsAppService.status === "disconnected") return Theme.accentAmber;
                if (WhatsAppService.status === "offline") return Theme.accentRose;
                return Theme.textMuted;
            }
        }

        // Contact info on hover
        Text {
            visible: mouseArea.containsMouse && WhatsAppService.status === "ready"
            text: WhatsAppService.userName
            font.family: Theme.fontFamily
            font.pixelSize: 10
            color: Theme.textMuted
            elide: Text.ElideRight
            Layout.maximumWidth: 70
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
                ShellState.toggleWhatsApp();
            } else if (mouse.button === Qt.RightButton) {
                WhatsAppService.refresh();
            }
        }
    }
}
