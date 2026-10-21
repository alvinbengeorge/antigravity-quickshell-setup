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
    color: Theme.bgPill
    border.color: Theme.borderDim
    border.width: 1

    implicitWidth: sysRow.implicitWidth + 24

    RowLayout {
        id: sysRow
        anchors.centerIn: parent
        spacing: 10

        // CPU Metric
        RowLayout {
            spacing: 4
            Text {
                text: "CPU"
                font.family: Theme.fontMono
                font.pixelSize: 10
                color: Theme.textMuted
            }
            Text {
                text: SystemStats.cpuPercent + "%"
                font.family: Theme.fontMono
                font.pixelSize: 11
                color: SystemStats.cpuPercent > 80 ? Theme.accentRose : (SystemStats.cpuPercent > 50 ? Theme.accentAmber : Theme.accentSky)
            }
        }

        // Divider
        Rectangle {
            width: 1
            height: 12
            color: Theme.borderDim
        }

        // Memory Metric
        RowLayout {
            spacing: 4
            Text {
                text: "RAM"
                font.family: Theme.fontMono
                font.pixelSize: 10
                color: Theme.textMuted
            }
            Text {
                text: SystemStats.memPercent + "%"
                font.family: Theme.fontMono
                font.pixelSize: 11
                color: SystemStats.memPercent > 85 ? Theme.accentRose : (SystemStats.memPercent > 70 ? Theme.accentAmber : Theme.accentEmerald)
            }
        }

        // Divider
        Rectangle {
            width: 1
            height: 12
            color: Theme.borderDim
        }

        // SWAP Metric
        RowLayout {
            spacing: 4
            Text {
                text: "SWP"
                font.family: Theme.fontMono
                font.pixelSize: 10
                color: Theme.textMuted
            }
            Text {
                text: SystemStats.swapPercent + "%"
                font.family: Theme.fontMono
                font.pixelSize: 11
                color: SystemStats.swapPercent > 80 ? Theme.accentRose : (SystemStats.swapPercent > 50 ? Theme.accentAmber : Theme.accentEmerald)
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
            implicitWidth: agyRow.implicitWidth
            implicitHeight: 20
            Layout.alignment: Qt.AlignVCenter

            // 0: 5h limit remaining, 1: Weekly limit remaining, 2: Context tokens
            property int displayMode: 0

            RowLayout {
                id: agyRow
                anchors.fill: parent
                spacing: 4

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

        // Volume Metric
        Item {
            id: volItem
            implicitWidth: volRow.implicitWidth
            implicitHeight: 20
            Layout.alignment: Qt.AlignVCenter

            RowLayout {
                id: volRow
                anchors.fill: parent
                spacing: 5

                Icon {
                    name: AudioService.muted ? "volume-x" : (AudioService.volume > 0.5 ? "volume-2" : "volume-1")
                    size: 13
                    color: AudioService.muted ? Theme.accentRose : Theme.textSecondary
                }

                Text {
                    text: AudioService.muted ? "Mute" : Math.round(AudioService.volume * 100) + "%"
                    font.family: Theme.fontMono
                    font.pixelSize: 11
                    color: AudioService.muted ? Theme.accentRose : Theme.textSecondary
                }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: AudioService.toggleMute()
                onWheel: wheel => {
                    if (wheel.angleDelta.y > 0) {
                        AudioService.changeVolume(0.05);
                    } else if (wheel.angleDelta.y < 0) {
                        AudioService.changeVolume(-0.05);
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
        RowLayout {
            spacing: 4
            visible: BatteryService.available

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
    }
}
