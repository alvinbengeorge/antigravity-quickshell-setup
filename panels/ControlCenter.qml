import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import "../theme"
import "../services"

PanelWindow {
    id: controlCenterWindow

    visible: ShellState.controlCenterOpen
    color: "transparent"

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "quickshell:controlcenter"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: ShellState.controlCenterOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    // Backdrop click to close
    MouseArea {
        anchors.fill: parent
        onClicked: ShellState.controlCenterOpen = false

        Rectangle {
            anchors.fill: parent
            color: "#000000"
            opacity: 0.45
        }
    }

    // Dropdown Card anchored to top-right below the bar
    Rectangle {
        id: menuCard
        width: 380
        anchors.top: parent.top
        anchors.topMargin: 56
        anchors.right: parent.right
        anchors.rightMargin: 16
        implicitHeight: mainCol.implicitHeight + 32
        radius: Theme.cardRadius
        color: Theme.bgModal
        border.color: Theme.borderGlow
        border.width: 1

        // Consume clicks inside
        MouseArea {
            anchors.fill: parent
            onClicked: {}
        }

        ColumnLayout {
            id: mainCol
            anchors.fill: parent
            anchors.margins: 18
            spacing: 16

            // Header Row
            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: "CONNECTIVITY & CONTROLS"
                    font.family: Theme.fontMono
                    font.pixelSize: 11
                    font.bold: true
                    color: Theme.accentCyan
                }
                Item { Layout.fillWidth: true }
                // Refresh button
                Rectangle {
                    width: 24
                    height: 24
                    radius: 12
                    color: refreshMouse.containsMouse ? Theme.bgHover : "transparent"
                    Text {
                        anchors.centerIn: parent
                        text: "🔄"
                        font.pixelSize: 11
                    }
                    MouseArea {
                        id: refreshMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: NetworkService.refresh()
                    }
                }
            }

            // Quick Toggle Tiles (Wi-Fi & Bluetooth)
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                // Wi-Fi Toggle Tile
                Rectangle {
                    Layout.fillWidth: true
                    height: 58
                    radius: 12
                    color: NetworkService.wifiEnabled ? Theme.bgCard : Theme.bgPill
                    border.color: NetworkService.wifiEnabled ? Theme.accentCyan : Theme.borderDim
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 10

                        Image {
                            source: NetworkService.wifiEnabled ? "../assets/wifi.svg" : "../assets/wifi-off.svg"
                            width: 22
                            height: 22
                            sourceSize.width: 22
                            sourceSize.height: 22
                            fillMode: Image.PreserveAspectFit
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            Text {
                                text: "Wi-Fi"
                                font.family: Theme.fontFamily
                                font.pixelSize: 12
                                font.bold: true
                                color: Theme.textPrimary
                            }
                            Text {
                                text: NetworkService.wifiEnabled ? (NetworkService.activeSsid ? NetworkService.activeSsid : "On") : "Disabled"
                                font.family: Theme.fontFamily
                                font.pixelSize: 10
                                color: Theme.textMuted
                                elide: Text.ElideRight
                                Layout.maximumWidth: 100
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: NetworkService.toggleWifi()
                    }
                }

                // Bluetooth Toggle Tile
                Rectangle {
                    Layout.fillWidth: true
                    height: 58
                    radius: 12
                    color: NetworkService.btPowered ? Theme.bgCard : Theme.bgPill
                    border.color: NetworkService.btPowered ? Theme.accentSky : Theme.borderDim
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 10

                        Image {
                            source: NetworkService.btPowered ? "../assets/bluetooth.svg" : "../assets/bluetooth-off.svg"
                            width: 22
                            height: 22
                            sourceSize.width: 22
                            sourceSize.height: 22
                            fillMode: Image.PreserveAspectFit
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            Text {
                                text: "Bluetooth"
                                font.family: Theme.fontFamily
                                font.pixelSize: 12
                                font.bold: true
                                color: Theme.textPrimary
                            }
                            Text {
                                text: NetworkService.btPowered ? "Enabled" : "Disabled"
                                font.family: Theme.fontFamily
                                font.pixelSize: 10
                                color: Theme.textMuted
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: NetworkService.toggleBluetooth()
                    }
                }
            }

            // Wi-Fi Section
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: "AVAILABLE WI-FI NETWORKS"
                        font.family: Theme.fontMono
                        font.pixelSize: 10
                        font.bold: true
                        color: Theme.textMuted
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: NetworkService.networks.length + " found"
                        font.family: Theme.fontMono
                        font.pixelSize: 10
                        color: Theme.accentCyan
                    }
                }

                // Networks Scroll List
                Rectangle {
                    Layout.fillWidth: true
                    height: 150
                    radius: 10
                    color: Theme.bgPill
                    border.color: Theme.borderDim
                    border.width: 1
                    clip: true

                    ListView {
                        id: wifiListView
                        anchors.fill: parent
                        anchors.margins: 6
                        spacing: 4
                        model: NetworkService.networks

                        ScrollBar.vertical: ScrollBar {
                            active: true
                            policy: ScrollBar.AsNeeded
                        }

                        delegate: Rectangle {
                            width: wifiListView.width - 12
                            height: 34
                            radius: 6
                            color: modelData.inUse ? Theme.bgCard : (netMouse.containsMouse ? Theme.bgHover : "transparent")
                            border.color: modelData.inUse ? Theme.accentCyan : "transparent"
                            border.width: 1

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                anchors.rightMargin: 8
                                spacing: 8

                                Text {
                                    text: modelData.inUse ? "✓" : (modelData.security.includes("WPA") ? "🔒" : "🌐")
                                    font.pixelSize: 11
                                    color: modelData.inUse ? Theme.accentCyan : Theme.textMuted
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.ssid
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 11
                                    font.bold: modelData.inUse
                                    color: modelData.inUse ? Theme.accentCyan : Theme.textPrimary
                                    elide: Text.ElideRight
                                }

                                Text {
                                    text: modelData.signal + "%"
                                    font.family: Theme.fontMono
                                    font.pixelSize: 10
                                    color: Theme.textMuted
                                }
                            }

                            MouseArea {
                                id: netMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (!modelData.inUse) {
                                        NetworkService.connectWifi(modelData.ssid);
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Bluetooth Section
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: "BLUETOOTH DEVICES"
                        font.family: Theme.fontMono
                        font.pixelSize: 10
                        font.bold: true
                        color: Theme.textMuted
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: NetworkService.btDevices.length + " paired"
                        font.family: Theme.fontMono
                        font.pixelSize: 10
                        color: Theme.accentSky
                    }
                }

                // Devices List
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    Repeater {
                        model: NetworkService.btDevices
                        Rectangle {
                            Layout.fillWidth: true
                            height: 36
                            radius: 8
                            color: modelData.connected ? Theme.bgCard : (devMouse.containsMouse ? Theme.bgHover : Theme.bgPill)
                            border.color: modelData.connected ? Theme.accentSky : Theme.borderDim
                            border.width: 1

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 10
                                spacing: 8

                                Text {
                                    text: modelData.connected ? "🎧" : "📱"
                                    font.pixelSize: 12
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.name
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 11
                                    color: modelData.connected ? Theme.accentSky : Theme.textPrimary
                                    elide: Text.ElideRight
                                }

                                Rectangle {
                                    width: 58
                                    height: 22
                                    radius: 11
                                    color: modelData.connected ? Theme.accentRose : Theme.bgHover

                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData.connected ? "Disconnect" : "Connect"
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 9
                                        font.bold: true
                                        color: modelData.connected ? Theme.textOnAccent : Theme.textSecondary
                                    }
                                }
                            }

                            MouseArea {
                                id: devMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    NetworkService.toggleBtDevice(modelData.mac, modelData.connected);
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
