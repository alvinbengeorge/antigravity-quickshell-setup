import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import "../theme"
import "../services"
import "../components"

Rectangle {
    id: root
    height: 34
    radius: height / 2
    color: ShellState.glassEnabled ? "transparent" : Theme.bgPill
    border.color: ShellState.glassEnabled ? "transparent" : Theme.borderDim
    border.width: ShellState.glassEnabled ? 0 : 1

    LiquidGlassSurface {
        radius: root.radius
        visible: ShellState.glassEnabled
        accentColor: Theme.accentSky
    }

    implicitWidth: sysRow.implicitWidth + 18

    RowLayout {
        id: sysRow
        anchors.centerIn: parent
        spacing: 6

        // CPU Metric
        Item {
            implicitWidth: cpuRow.implicitWidth + 8
            implicitHeight: 24
            Layout.alignment: Qt.AlignVCenter

            LiquidGlassSurface {
                radius: 6
                visible: ShellState.plasticEnabled && cpuMouse.containsMouse
                accentColor: SystemStats.cpuPercent > 80 ? Theme.accentRose : (SystemStats.cpuPercent > 50 ? Theme.accentAmber : Theme.accentSky)
                hovered: cpuMouse.containsMouse
                pressed: cpuMouse.pressed
                showShadow: false
            }

            Rectangle {
                anchors.fill: parent
                radius: 6
                visible: !ShellState.plasticEnabled
                color: cpuMouse.containsMouse ? Theme.bgHover : "transparent"
                border.color: cpuMouse.containsMouse ? Theme.borderDim : "transparent"
                border.width: 1
                Behavior on color { ColorAnimation { duration: 150 } }
            }

            RowLayout {
                id: cpuRow
                anchors.centerIn: parent
                spacing: 3
                Text {
                    text: "CPU"
                    font.family: Theme.fontMono
                    font.pixelSize: 10
                    color: cpuMouse.containsMouse ? Theme.textPrimary : Theme.textMuted
                }
                Text {
                    text: SystemStats.cpuPercent + "%"
                    font.family: Theme.fontMono
                    font.pixelSize: 11
                    color: SystemStats.cpuPercent > 80 ? Theme.accentRose : (SystemStats.cpuPercent > 50 ? Theme.accentAmber : Theme.accentSky)
                }
            }

            MouseArea {
                id: cpuMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: ShellState.toggleSystemMonitor("cpu")
            }
        }

        // Divider
        Rectangle {
            width: 1
            height: 12
            color: Theme.borderDim
        }

        // Memory & Swap Cycleable Metric (Click label to open System Monitor, Click number/Right-click/Wheel to cycle)
        Item {
            id: memMetric
            implicitWidth: memRow.implicitWidth + 8
            implicitHeight: 24
            Layout.alignment: Qt.AlignVCenter

            // 0: RAM, 1: SWP
            property int memMode: 0

            LiquidGlassSurface {
                radius: 6
                visible: ShellState.plasticEnabled && memMouse.containsMouse
                accentColor: {
                    if (memMetric.memMode === 0) {
                        return SystemStats.memPercent > 85 ? Theme.accentRose : (SystemStats.memPercent > 70 ? Theme.accentAmber : Theme.accentEmerald);
                    } else {
                        return SystemStats.swapPercent > 80 ? Theme.accentRose : (SystemStats.swapPercent > 50 ? Theme.accentAmber : Theme.accentEmerald);
                    }
                }
                hovered: memMouse.containsMouse
                pressed: memMouse.pressed
                showShadow: false
            }

            Rectangle {
                anchors.fill: parent
                radius: 6
                visible: !ShellState.plasticEnabled
                color: memMouse.containsMouse ? Theme.bgHover : "transparent"
                border.color: memMouse.containsMouse ? Theme.borderDim : "transparent"
                border.width: 1
                Behavior on color { ColorAnimation { duration: 150 } }
            }

            RowLayout {
                id: memRow
                anchors.centerIn: parent
                spacing: 4

                // Clickable Label ("RAM" or "SWP") -> Opens System Resource Monitor directly
                Text {
                    text: memMetric.memMode === 0 ? "RAM" : "SWP"
                    font.family: Theme.fontMono
                    font.pixelSize: 10
                    color: labelMouse.containsMouse ? Theme.textPrimary : Theme.textMuted

                    MouseArea {
                        id: labelMouse
                        anchors.fill: parent
                        anchors.margins: -3
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            ShellState.toggleSystemMonitor(memMetric.memMode === 0 ? "ram" : "swap");
                        }
                    }
                }

                // Clickable Percentage ("78%" or "30%") -> Cycles between RAM and SWP
                Text {
                    text: (memMetric.memMode === 0 ? SystemStats.memPercent : SystemStats.swapPercent) + "%"
                    font.family: Theme.fontMono
                    font.pixelSize: 11
                    color: {
                        if (memMetric.memMode === 0) {
                            return SystemStats.memPercent > 85 ? Theme.accentRose : (SystemStats.memPercent > 70 ? Theme.accentAmber : Theme.accentEmerald);
                        } else {
                            return SystemStats.swapPercent > 80 ? Theme.accentRose : (SystemStats.swapPercent > 50 ? Theme.accentAmber : Theme.accentEmerald);
                        }
                    }

                    MouseArea {
                        id: valMouse
                        anchors.fill: parent
                        anchors.margins: -3
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            memMetric.memMode = (memMetric.memMode === 0) ? 1 : 0;
                        }
                    }
                }
            }

            // Overall MouseArea for Right-Click (cycle) and Wheel (cycle) and Left-Click fallback
            MouseArea {
                id: memMouse
                anchors.fill: parent
                z: -1
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onClicked: mouse => {
                    if (mouse.button === Qt.RightButton) {
                        memMetric.memMode = (memMetric.memMode === 0) ? 1 : 0;
                    } else {
                        ShellState.toggleSystemMonitor(memMetric.memMode === 0 ? "ram" : "swap");
                    }
                }
                onWheel: wheel => {
                    memMetric.memMode = (memMetric.memMode === 0) ? 1 : 0;
                }
            }
        }

        // Divider
        Rectangle {
            width: 1
            height: 12
            color: Theme.borderDim
        }

        // Live Network Throughput Metric (Click cycles strictly between Download ↓ and Upload ↑)
        Item {
            id: netMetric
            implicitWidth: netRow.implicitWidth + 8
            implicitHeight: 24
            Layout.alignment: Qt.AlignVCenter

            // 0: Download only (↓), 1: Upload only (↑)
            property int displayMode: 0

            LiquidGlassSurface {
                radius: 6
                visible: ShellState.plasticEnabled && netMouse.containsMouse
                accentColor: netMetric.displayMode === 0 ? Theme.accentEmerald : Theme.accentAmber
                hovered: netMouse.containsMouse
                pressed: netMouse.pressed
                showShadow: false
            }

            Rectangle {
                anchors.fill: parent
                radius: 6
                visible: !ShellState.plasticEnabled
                color: netMouse.containsMouse ? Theme.bgHover : "transparent"
                border.color: netMouse.containsMouse ? Theme.borderDim : "transparent"
                border.width: 1
                Behavior on color { ColorAnimation { duration: 150 } }
            }

            RowLayout {
                id: netRow
                anchors.centerIn: parent
                spacing: 3

                Icon {
                    name: netMetric.displayMode === 0 ? "arrow-down" : "arrow-up"
                    size: 11
                    color: netMetric.displayMode === 0 ? Theme.accentEmerald : Theme.accentAmber
                }

                Text {
                    text: netMetric.displayMode === 0 ? SystemStats.netDown : SystemStats.netUp
                    font.family: Theme.fontMono
                    font.pixelSize: 11
                    color: netMouse.containsMouse ? Theme.textPrimary : Theme.textSecondary
                }
            }

            MouseArea {
                id: netMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    // Toggle strictly between Download (0) and Upload (1)
                    netMetric.displayMode = (netMetric.displayMode === 0) ? 1 : 0;
                }
            }
        }

        // Divider
        Rectangle {
            width: 1
            height: 12
            color: Theme.borderDim
        }

        // Antigravity Usage & Quota Metric (5h limit, Weekly limit, Context tokens)
        Item {
            id: agyMetric
            implicitWidth: agyRow.implicitWidth + 8
            implicitHeight: 24
            Layout.alignment: Qt.AlignVCenter

            // 0: 5h limit remaining, 1: Weekly limit remaining, 2: Context tokens
            property int displayMode: 0

            LiquidGlassSurface {
                radius: 6
                visible: ShellState.plasticEnabled && agyMouse.containsMouse
                accentColor: AntigravityService.isActive ? Theme.accentCyan : Theme.accentViolet
                hovered: agyMouse.containsMouse
                pressed: agyMouse.pressed
                showShadow: false
            }

            Rectangle {
                anchors.fill: parent
                radius: 6
                visible: !ShellState.plasticEnabled
                color: agyMouse.containsMouse ? Theme.bgHover : "transparent"
                border.color: agyMouse.containsMouse ? Theme.borderDim : "transparent"
                border.width: 1
                Behavior on color { ColorAnimation { duration: 150 } }
            }

            RowLayout {
                id: agyRow
                anchors.centerIn: parent
                spacing: 3

                Icon {
                    name: "sparkles"
                    size: 11
                    color: AntigravityService.isActive ? Theme.accentCyan : Theme.accentViolet
                }

                Text {
                    text: agyMetric.displayMode === 0 ? "5h" : (agyMetric.displayMode === 1 ? "Wk" : "Ctx")
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                    color: AntigravityService.isActive ? Theme.accentCyan : Theme.accentViolet
                }

                Text {
                    text: {
                        if (agyMetric.displayMode === 0) {
                            return AntigravityService.gemini5hRemaining + "%";
                        } else if (agyMetric.displayMode === 1) {
                            return AntigravityService.geminiWeeklyRemaining + "%";
                        } else {
                            return AntigravityService.contextTokensStr;
                        }
                    }
                    font.family: Theme.fontMono
                    font.pixelSize: 11
                    color: {
                        if (agyMetric.displayMode === 0) {
                            return AntigravityService.gemini5hRemaining < 20 ? Theme.accentRose : (AntigravityService.gemini5hRemaining < 50 ? Theme.accentAmber : Theme.accentCyan);
                        } else if (agyMetric.displayMode === 1) {
                            return AntigravityService.geminiWeeklyRemaining < 20 ? Theme.accentRose : (AntigravityService.geminiWeeklyRemaining < 50 ? Theme.accentAmber : Theme.accentCyan);
                        } else {
                            return AntigravityService.contextPercent > 80 ? Theme.accentRose : (AntigravityService.contextPercent > 50 ? Theme.accentAmber : Theme.accentCyan);
                        }
                    }
                }
            }

            MouseArea {
                id: agyMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    agyMetric.displayMode = (agyMetric.displayMode + 1) % 3;
                }
            }
        }

        // Divider
        Rectangle {
            width: 1
            height: 12
            color: Theme.borderDim
        }

        // Sound & Brightness Unified Metric (Left-click cycles between Volume and Brightness, Right-click mutes)
        Item {
            id: outputMetric
            implicitWidth: outputRow.implicitWidth + 8
            implicitHeight: 24
            Layout.alignment: Qt.AlignVCenter

            // 0: Volume / Sound, 1: Brightness
            property int displayMode: 0

            LiquidGlassSurface {
                radius: 6
                visible: ShellState.plasticEnabled && outputMouse.containsMouse
                accentColor: {
                    if (outputMetric.displayMode === 0) {
                        return AudioService.muted ? Theme.accentRose : Theme.accentCyan;
                    } else {
                        return Theme.accentAmber;
                    }
                }
                hovered: outputMouse.containsMouse
                pressed: outputMouse.pressed
                showShadow: false
            }

            Rectangle {
                anchors.fill: parent
                radius: 6
                visible: !ShellState.plasticEnabled
                color: outputMouse.containsMouse ? Theme.bgHover : "transparent"
                border.color: outputMouse.containsMouse ? Theme.borderDim : "transparent"
                border.width: 1
                Behavior on color { ColorAnimation { duration: 150 } }
            }

            RowLayout {
                id: outputRow
                anchors.centerIn: parent
                spacing: 4

                Icon {
                    name: {
                        if (outputMetric.displayMode === 0) {
                            return AudioService.muted ? "volume-x" : (AudioService.volume > 0.5 ? "volume-2" : "volume-1");
                        } else {
                            return "sun";
                        }
                    }
                    size: 13
                    color: {
                        if (outputMetric.displayMode === 0) {
                            return AudioService.muted ? Theme.accentRose : (outputMouse.containsMouse ? Theme.accentCyan : Theme.textSecondary);
                        } else {
                            return outputMouse.containsMouse ? Theme.accentAmber : Theme.textSecondary;
                        }
                    }
                }

                Text {
                    text: {
                        if (outputMetric.displayMode === 0) {
                            return AudioService.muted ? "Mute" : Math.round(AudioService.volume * 100) + "%";
                        } else {
                            return BrightnessService.percent + "%";
                        }
                    }
                    font.family: Theme.fontMono
                    font.pixelSize: 11
                    color: {
                        if (outputMetric.displayMode === 0) {
                            return AudioService.muted ? Theme.accentRose : (outputMouse.containsMouse ? Theme.accentCyan : Theme.textSecondary);
                        } else {
                            return outputMouse.containsMouse ? Theme.accentAmber : Theme.textSecondary;
                        }
                    }
                }
            }

            MouseArea {
                id: outputMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onClicked: mouse => {
                    if (mouse.button === Qt.RightButton) {
                        if (outputMetric.displayMode === 0) {
                            AudioService.toggleMute();
                        } else {
                            BrightnessService.setPercent(50);
                        }
                    } else {
                        // Left click cycles between Volume and Brightness
                        outputMetric.displayMode = (outputMetric.displayMode === 0) ? 1 : 0;
                        if (outputMetric.displayMode === 1) {
                            BrightnessService.refresh(true);
                        }
                    }
                }
                onWheel: wheel => {
                    if (outputMetric.displayMode === 0) {
                        if (wheel.angleDelta.y > 0) AudioService.changeVolume(0.05);
                        else AudioService.changeVolume(-0.05);
                    } else {
                        if (wheel.angleDelta.y > 0) BrightnessService.increase();
                        else BrightnessService.decrease();
                    }
                }
            }
        }

        // Divider (Battery)
        Rectangle {
            width: 1
            height: 12
            color: Theme.borderDim
            visible: BatteryService.available
        }

        // Battery Metric
        Item {
            implicitWidth: batRow.implicitWidth + 8
            implicitHeight: 24
            Layout.alignment: Qt.AlignVCenter
            visible: BatteryService.available

            LiquidGlassSurface {
                radius: 6
                visible: ShellState.plasticEnabled && batMouse.containsMouse
                accentColor: BatteryService.isCharging ? Theme.accentEmerald : (BatteryService.percentage <= 20 ? Theme.accentRose : Theme.accentAmber)
                hovered: batMouse.containsMouse
                pressed: batMouse.pressed
                showShadow: false
            }

            Rectangle {
                anchors.fill: parent
                radius: 6
                visible: !ShellState.plasticEnabled
                color: batMouse.containsMouse ? Theme.bgHover : "transparent"
                border.color: batMouse.containsMouse ? Theme.borderDim : "transparent"
                border.width: 1
                Behavior on color { ColorAnimation { duration: 150 } }
            }

            RowLayout {
                id: batRow
                anchors.centerIn: parent
                spacing: 3

                Icon {
                    name: BatteryService.isCharging ? "battery-charging" : (BatteryService.percentage <= 20 ? "battery-warning" : "battery")
                    size: 13
                    color: BatteryService.isCharging ? Theme.accentEmerald : (BatteryService.percentage <= 20 ? Theme.accentRose : (BatteryService.percentage <= 40 ? Theme.accentAmber : Theme.textSecondary))
                }

                Text {
                    text: BatteryService.percentage + "%"
                    font.family: Theme.fontMono
                    font.pixelSize: 11
                    color: BatteryService.isCharging ? Theme.accentEmerald : (BatteryService.percentage <= 20 ? Theme.accentRose : (BatteryService.percentage <= 40 ? Theme.accentAmber : Theme.textSecondary))
                }
            }

            MouseArea {
                id: batMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: BatteryService.openPowerStatistics()
            }
        }
    }
}
