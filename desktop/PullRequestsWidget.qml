import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import "../theme"
import "../services"

PanelWindow {
    id: root

    property bool alignLeft: false
    visible: ShellState.desktopPullRequestsVisible

    anchors {
        top: true
        left: root.alignLeft
        right: !root.alignLeft
    }

    margins {
        // Position below DesktopClock (which ends at y=580) with a 16px gap, or at 76 if clock is hidden
        top: (!root.alignLeft && ShellState.desktopClockVisible) ? 596 : 76
        left: root.alignLeft ? 48 : 0
        right: !root.alignLeft ? 48 : 0
    }

    implicitWidth: 300
    implicitHeight: mainCard.implicitHeight

    color: "transparent"

    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "quickshell:desktop:pullrequests"
    WlrLayershell.layer: WlrLayer.Bottom

    // Main Card Surface
    Rectangle {
        id: mainCard
        width: 300
        implicitHeight: contentCol.implicitHeight + 24
        radius: 14
        color: Theme.bgSurfaceGlass
        border.color: Theme.borderGlow
        border.width: 1

        // Top gradient sheen accent line
        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 1
            color: Qt.rgba(Theme.accentSky.r, Theme.accentSky.g, Theme.accentSky.b, 0.45)
            radius: parent.radius
        }

        ColumnLayout {
            id: contentCol
            anchors.fill: parent
            anchors.margins: 12
            spacing: 8

            // Header Section
            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                // PR Branch Icon
                Rectangle {
                    width: 24
                    height: 24
                    radius: 12
                    color: Qt.rgba(Theme.accentSky.r, Theme.accentSky.g, Theme.accentSky.b, 0.12)
                    border.color: Theme.accentSky
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "⎇"
                        font.pixelSize: 13
                        color: Theme.accentSky
                    }
                }

                // Title & Subtitle
                ColumnLayout {
                    spacing: 0
                    Text {
                        text: "PULL REQUESTS"
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        font.bold: true
                        color: Theme.textPrimary
                    }
                    Text {
                        text: GithubService.loading ? "Refreshing..." : (GithubService.count + " open • " + GithubService.lastUpdated)
                        font.family: Theme.fontMono
                        font.pixelSize: 8
                        color: Theme.textMuted
                    }
                }

                Item { Layout.fillWidth: true }

                // Count Badge
                Rectangle {
                    height: 18
                    implicitWidth: countText.implicitWidth + 10
                    radius: 9
                    color: Theme.bgPill
                    border.color: GithubService.count > 0 ? Theme.accentEmerald : Theme.borderDim
                    border.width: 1

                    Text {
                        id: countText
                        anchors.centerIn: parent
                        text: GithubService.count + " OPEN"
                        font.family: Theme.fontMono
                        font.pixelSize: 8
                        font.bold: true
                        color: GithubService.count > 0 ? Theme.accentEmerald : Theme.textMuted
                    }
                }

                // Refresh Button
                Rectangle {
                    width: 22
                    height: 22
                    radius: 5
                    color: refreshMouse.containsMouse ? Theme.bgHover : Theme.bgPill
                    border.color: Theme.borderDim
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "↻"
                        font.pixelSize: 11
                        font.bold: true
                        color: refreshMouse.containsMouse ? Theme.accentSky : Theme.textSecondary

                        RotationAnimation on rotation {
                            running: GithubService.loading
                            loops: Animation.Infinite
                            from: 0
                            to: 360
                            duration: 1000
                        }
                    }

                    MouseArea {
                        id: refreshMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: GithubService.refresh(true)
                    }
                }

                // Open GitHub in browser button
                Rectangle {
                    width: 22
                    height: 22
                    radius: 5
                    color: ghMouse.containsMouse ? Theme.bgHover : Theme.bgPill
                    border.color: Theme.borderDim
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "↗"
                        font.pixelSize: 10
                        font.bold: true
                        color: ghMouse.containsMouse ? Theme.accentViolet : Theme.textSecondary
                    }

                    MouseArea {
                        id: ghMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: GithubService.openAllPrs()
                    }
                }
            }

            // Divider
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Theme.borderDim
            }

            // Empty State
            Item {
                visible: GithubService.count === 0 && !GithubService.loading
                Layout.fillWidth: true
                Layout.preferredHeight: visible ? 70 : 0
                implicitHeight: visible ? 70 : 0

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 4

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "✓"
                        font.pixelSize: 18
                        color: Theme.accentEmerald
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "All Caught Up"
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        font.bold: true
                        color: Theme.textPrimary
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "No open pull requests"
                        font.family: Theme.fontMono
                        font.pixelSize: 9
                        color: Theme.textMuted
                    }
                }
            }

            // PR Scrollable List Container (compact, max height 250px)
            Item {
                id: prListContainer
                visible: GithubService.count > 0
                Layout.fillWidth: true
                Layout.preferredHeight: visible ? Math.min(250, GithubService.prs.length * 52) : 0
                implicitHeight: Layout.preferredHeight

                ListView {
                    id: prList
                    anchors.fill: parent
                    clip: true
                    spacing: 5
                    boundsBehavior: Flickable.StopAtBounds
                    model: GithubService.prs

                    ScrollBar.vertical: ScrollBar {
                        active: true
                        policy: prList.contentHeight > prList.height ? ScrollBar.AlwaysOn : ScrollBar.AsNeeded
                    }

                    delegate: Rectangle {
                        id: prCard
                        required property var modelData
                        required property int index

                        width: prList.width - (prList.contentHeight > prList.height ? 8 : 0)
                        implicitHeight: cardCol.implicitHeight + 10
                        radius: 8
                        color: prItemMouse.containsMouse ? Theme.bgHover : Theme.bgCard
                        border.color: prItemMouse.containsMouse ? Theme.accentSky : Theme.borderDim
                        border.width: 1

                        ColumnLayout {
                            id: cardCol
                            anchors.fill: parent
                            anchors.margins: 7
                            spacing: 3

                            // 1. PR Title First
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 4

                                Text {
                                    text: prCard.modelData.title ?? ""
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 10
                                    font.bold: true
                                    color: prItemMouse.containsMouse ? Theme.textPrimary : Theme.textSecondary
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }

                                // Draft Tag
                                Rectangle {
                                    visible: prCard.modelData.is_draft ?? false
                                    height: 12
                                    implicitWidth: draftText.implicitWidth + 6
                                    radius: 3
                                    color: Qt.rgba(Theme.accentAmber.r, Theme.accentAmber.g, Theme.accentAmber.b, 0.15)
                                    border.color: Theme.accentAmber
                                    border.width: 1

                                    Text {
                                        id: draftText
                                        anchors.centerIn: parent
                                        text: "DRAFT"
                                        font.family: Theme.fontMono
                                        font.pixelSize: 7
                                        font.bold: true
                                        color: Theme.accentAmber
                                    }
                                }
                            }

                            // 2. Repository & Metadata Second
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 4

                                Text {
                                    text: prCard.modelData.repo ?? ""
                                    font.family: Theme.fontMono
                                    font.pixelSize: 9
                                    font.bold: true
                                    color: Theme.accentSky
                                    elide: Text.ElideRight
                                    Layout.maximumWidth: 130
                                }

                                Text {
                                    text: "#" + (prCard.modelData.number ?? "")
                                    font.family: Theme.fontMono
                                    font.pixelSize: 9
                                    color: Theme.textMuted
                                }

                                Text {
                                    text: "•"
                                    font.pixelSize: 8
                                    color: Theme.textMuted
                                }

                                Text {
                                    text: prCard.modelData.updated_ago ?? ""
                                    font.family: Theme.fontMono
                                    font.pixelSize: 8
                                    color: Theme.textMuted
                                }

                                Item { Layout.fillWidth: true }

                                // Comments count
                                RowLayout {
                                    visible: prCard.modelData.comments > 0
                                    spacing: 2
                                    Text {
                                        text: "💬"
                                        font.pixelSize: 8
                                    }
                                    Text {
                                        text: String(prCard.modelData.comments ?? 0)
                                        font.family: Theme.fontMono
                                        font.pixelSize: 8
                                        color: Theme.textMuted
                                    }
                                }
                            }
                        }

                        MouseArea {
                            id: prItemMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                GithubService.openPr(prCard.modelData.url);
                            }
                        }
                    }
                }
            }

            // Footer Section
            RowLayout {
                Layout.fillWidth: true
                spacing: 4

                Text {
                    text: "Click to open PR in browser"
                    font.family: Theme.fontMono
                    font.pixelSize: 8
                    color: Theme.textMuted
                }

                Item { Layout.fillWidth: true }

                Rectangle {
                    height: 16
                    implicitWidth: allLinkText.implicitWidth + 8
                    radius: 3
                    color: allLinkMouse.containsMouse ? Theme.bgHover : "transparent"

                    Text {
                        id: allLinkText
                        anchors.centerIn: parent
                        text: "GitHub ↗"
                        font.family: Theme.fontMono
                        font.pixelSize: 8
                        font.bold: true
                        color: allLinkMouse.containsMouse ? Theme.accentSky : Theme.textMuted
                    }

                    MouseArea {
                        id: allLinkMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: GithubService.openAllPrs()
                    }
                }
            }
        }
    }
}
