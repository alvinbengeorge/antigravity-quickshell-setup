import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import "../theme"
import "../services"
import "../components"

PanelWindow {
    id: root

    property bool alignLeft: true

    visible: !ShellState.liteMode && ShellState.desktopJiraVisible

    function isReviewTask(t) {
        if (!t) return false;
        const s = (t.status || "").toLowerCase();
        return s.includes("review");
    }

    readonly property var todoTasks:       (JiraService.tasks || []).filter(t => t.category === "to_do" && !root.isReviewTask(t))
    readonly property var reviewTasks:     (JiraService.tasks || []).filter(t => root.isReviewTask(t))
    readonly property var inProgressTasks: (JiraService.tasks || []).filter(t => t.category === "in_progress" && !root.isReviewTask(t))
    readonly property var doneTasks:       (JiraService.tasks || []).filter(t => t.category === "done")

    anchors {
        top: true
        left: root.alignLeft
        right: !root.alignLeft
    }

    margins {
        top: (!root.alignLeft || !ShellState.desktopAntigravityVisible) ? 76 : (76 + ShellState.antigravityWidgetHeight + 14)
        left: root.alignLeft ? 48 : 0
        right: !root.alignLeft ? 48 : 0
    }

    Behavior on margins.top {
        NumberAnimation { duration: 250; easing.type: Easing.OutQuad }
    }

    implicitWidth: 500
    implicitHeight: mainCard.implicitHeight

    color: "transparent"

    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "quickshell:desktop:jira"
    WlrLayershell.layer: WlrLayer.Bottom

    // ── Kanban column component ─────────────────────────────────────────────
    component KanbanColumn: Rectangle {
        id: kCol
        property string label: "TO DO"
        property int taskCount: 0
        property var tasks: []
        property color headerColor: Theme.textMuted
        property color accentColor: Theme.textMuted
        property real columnHeight: 420

        radius: 10
        color: ShellState.plasticEnabled ? Qt.rgba(0.12, 0.16, 0.24, 0.35) : Qt.rgba(Theme.bgCard.r, Theme.bgCard.g, Theme.bgCard.b, 0.6)
        border.color: ShellState.plasticEnabled ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(kCol.accentColor.r, kCol.accentColor.g, kCol.accentColor.b, 0.25)
        border.width: 1
        height: kCol.columnHeight
        Layout.preferredHeight: kCol.columnHeight
        Layout.fillHeight: false
        clip: true

        ColumnLayout {
            id: kColLayout
            anchors.fill: parent
            anchors.margins: 8
            spacing: 6

            // Column header
            RowLayout {
                Layout.fillWidth: true
                spacing: 5

                Rectangle {
                    width: 6
                    height: 6
                    radius: 3
                    color: kCol.accentColor
                }

                Text {
                    text: kCol.label
                    font.family: Theme.fontMono
                    font.pixelSize: 8
                    font.bold: true
                    color: kCol.headerColor
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }

                Rectangle {
                    height: 16
                    implicitWidth: colCountText.implicitWidth + 8
                    radius: 8
                    color: Qt.rgba(kCol.accentColor.r, kCol.accentColor.g, kCol.accentColor.b, 0.18)

                    Text {
                        id: colCountText
                        anchors.centerIn: parent
                        text: kCol.taskCount
                        font.family: Theme.fontMono
                        font.pixelSize: 8
                        font.bold: true
                        color: kCol.accentColor
                    }
                }
            }

            // Thin accent line under header
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Qt.rgba(kCol.accentColor.r, kCol.accentColor.g, kCol.accentColor.b, 0.3)
            }

            // Task list
            ListView {
                id: kListView
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: 5
                boundsBehavior: Flickable.StopAtBounds
                model: kCol.tasks

                ScrollBar.vertical: ScrollBar {
                    policy: kListView.contentHeight > kListView.height ? ScrollBar.AlwaysOn : ScrollBar.AsNeeded
                }

                // Empty column placeholder
                Item {
                    anchors.fill: parent
                    visible: kCol.tasks.length === 0 && !JiraService.loading

                    Text {
                        anchors.centerIn: parent
                        text: "Empty"
                        font.family: Theme.fontMono
                        font.pixelSize: 9
                        color: Theme.textMuted
                        opacity: 0.5
                    }
                }

                delegate: Rectangle {
                    id: kCard
                    required property var modelData
                    required property int index
                    property color accentColor: kCol.accentColor

                    width: kListView.width - (kListView.contentHeight > kListView.height ? 8 : 0)
                    implicitHeight: kCardCol.implicitHeight + 14
                    radius: 8
                    color: kMouse.containsMouse ? Theme.bgHover : Theme.bgCard
                    border.color: kMouse.containsMouse ? kCard.accentColor : Theme.borderDim
                    border.width: 1

                    ColumnLayout {
                        id: kCardCol
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 4

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 4

                            Rectangle {
                                height: 14
                                implicitWidth: kKeyText.implicitWidth + 8
                                radius: 3
                                color: Qt.rgba(kCard.accentColor.r, kCard.accentColor.g, kCard.accentColor.b, 0.14)
                                border.color: kCard.accentColor
                                border.width: 0.5

                                Text {
                                    id: kKeyText
                                    anchors.centerIn: parent
                                    text: kCard.modelData.key ?? ""
                                    font.family: Theme.fontMono
                                    font.pixelSize: 8
                                    font.bold: true
                                    color: kCard.accentColor
                                }
                            }

                            Item { Layout.fillWidth: true }

                            Text {
                                text: {
                                    const p = kCard.modelData.priority_level;
                                    if (p === "high") return "▲";
                                    if (p === "low") return "▼";
                                    return "▬";
                                }
                                font.pixelSize: 8
                                color: {
                                    const p = kCard.modelData.priority_level;
                                    if (p === "high") return Theme.accentRose;
                                    if (p === "low") return Theme.accentSky;
                                    return Theme.accentAmber;
                                }
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            text: kCard.modelData.summary ?? ""
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                            font.bold: true
                            color: kMouse.containsMouse ? Theme.textPrimary : Theme.textSecondary
                            wrapMode: Text.Wrap
                            maximumLineCount: 2
                            elide: Text.ElideRight
                        }

                        Text {
                            text: kCard.modelData.updated_ago ?? ""
                            font.family: Theme.fontMono
                            font.pixelSize: 8
                            color: Theme.textMuted
                        }
                    }

                    MouseArea {
                        id: kMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: JiraService.openTask(kCard.modelData.url)
                    }
                }
            }
        }
    }

    // ── Main card ───────────────────────────────────────────────────────────
    Rectangle {
        id: mainCard
        width: 500
        implicitHeight: contentCol.implicitHeight + 28
        radius: 18
        color: ShellState.glassEnabled ? "transparent" : Theme.bgSurfaceGlass
        border.color: ShellState.glassEnabled ? "transparent" : Theme.borderGlow
        border.width: ShellState.glassEnabled ? 0 : 1

        LiquidGlassSurface {
            radius: 18
            visible: ShellState.glassEnabled
            accentColor: Theme.accentSky
            showShadow: true
        }

        ColumnLayout {
            id: contentCol
            anchors.fill: parent
            anchors.margins: 14
            spacing: 10

            // ── Header ──────────────────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: 9

                Rectangle {
                    width: 34
                    height: 34
                    radius: 17
                    color: Theme.bgCard
                    border.color: Theme.accentSky
                    border.width: 1.5
                    clip: true

                    Image {
                        id: avatarImg
                        anchors.fill: parent
                        source: (JiraService.user && JiraService.user.avatarLocal && JiraService.user.avatarLocal.length > 0)
                                ? ("file://" + JiraService.user.avatarLocal)
                                : ((JiraService.user && JiraService.user.avatarUrl) ? JiraService.user.avatarUrl : "")
                        fillMode: Image.PreserveAspectCrop
                        smooth: true
                        visible: status === Image.Ready
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: !avatarImg.visible
                        text: (JiraService.user && JiraService.user.displayName && JiraService.user.displayName.length > 0)
                              ? JiraService.user.displayName.substring(0, 2).toUpperCase()
                              : "AG"
                        font.family: Theme.fontFamily
                        font.pixelSize: 12
                        font.bold: true
                        color: Theme.accentSky
                    }
                }

                ColumnLayout {
                    spacing: 1
                    Layout.fillWidth: true

                    RowLayout {
                        spacing: 6
                        Text {
                            text: (JiraService.user && JiraService.user.displayName) ? JiraService.user.displayName : "alvin.george"
                            font.family: Theme.fontFamily
                            font.pixelSize: 12
                            font.bold: true
                            color: Theme.textPrimary
                            elide: Text.ElideRight
                        }

                        Rectangle {
                            height: 14
                            implicitWidth: jiraBadgeText.implicitWidth + 8
                            radius: 3
                            color: Qt.rgba(Theme.accentSky.r, Theme.accentSky.g, Theme.accentSky.b, 0.15)
                            border.color: Theme.accentSky
                            border.width: 1

                            Text {
                                id: jiraBadgeText
                                anchors.centerIn: parent
                                text: "JIRA"
                                font.family: Theme.fontMono
                                font.pixelSize: 8
                                font.bold: true
                                color: Theme.accentSky
                            }
                        }
                    }

                    Text {
                        text: (JiraService.user && JiraService.user.emailAddress)
                              ? JiraService.user.emailAddress
                              : "alvin.george@askmeidentity.com"
                        font.family: Theme.fontMono
                        font.pixelSize: 9
                        color: Theme.textMuted
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }

                // Refresh
                Rectangle {
                    width: 24
                    height: 24
                    radius: 6
                    color: refreshMouse.containsMouse ? Theme.bgHover : Theme.bgPill
                    border.color: Theme.borderDim
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "↻"
                        font.pixelSize: 13
                        font.bold: true
                        color: refreshMouse.containsMouse ? Theme.accentSky : Theme.textMuted

                        RotationAnimation on rotation {
                            running: JiraService.loading
                            loops: Animation.Infinite
                            from: 0; to: 360
                            duration: 1000
                        }
                    }

                    MouseArea {
                        id: refreshMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: JiraService.refresh(true)
                    }
                }

                // Open in browser
                Rectangle {
                    width: 24
                    height: 24
                    radius: 6
                    color: jiraLinkMouse.containsMouse ? Theme.bgHover : Theme.bgPill
                    border.color: Theme.borderDim
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "↗"
                        font.pixelSize: 11
                        font.bold: true
                        color: jiraLinkMouse.containsMouse ? Theme.accentSky : Theme.textMuted
                    }

                    MouseArea {
                        id: jiraLinkMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: JiraService.openJira()
                    }
                }
            }

            // ── Kanban Board (3 columns: Left split 50/50, Middle, Right) ──
            RowLayout {
                Layout.fillWidth: true
                spacing: 7

                // Left column: TO DO & IN PROGRESS split half and half
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    Layout.preferredHeight: 420
                    Layout.fillHeight: false
                    spacing: 6

                    KanbanColumn {
                        Layout.fillWidth: true
                        columnHeight: 207
                        label: "TO DO"
                        taskCount: root.todoTasks.length
                        tasks: root.todoTasks
                        headerColor: Theme.textSecondary
                        accentColor: Theme.textMuted
                    }

                    KanbanColumn {
                        Layout.fillWidth: true
                        columnHeight: 207
                        label: "IN PROGRESS"
                        taskCount: root.inProgressTasks.length
                        tasks: root.inProgressTasks
                        headerColor: Theme.accentCyan
                        accentColor: Theme.accentCyan
                    }
                }

                KanbanColumn {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    columnHeight: 420
                    label: "IN / UNDER REVIEW"
                    taskCount: root.reviewTasks.length
                    tasks: root.reviewTasks
                    headerColor: Theme.accentAmber
                    accentColor: Theme.accentAmber
                }

                KanbanColumn {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    columnHeight: 420
                    label: "DONE"
                    taskCount: root.doneTasks.length
                    tasks: root.doneTasks
                    headerColor: Theme.accentEmerald
                    accentColor: Theme.accentEmerald
                }
            }

            // ── Footer ──────────────────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: 4

                Text {
                    text: "Click card to open  •  " + JiraService.count + " total  •  Updated " + JiraService.lastUpdated
                    font.family: Theme.fontMono
                    font.pixelSize: 8
                    color: Theme.textMuted
                }

                Item { Layout.fillWidth: true }

                Rectangle {
                    height: 16
                    implicitWidth: openWorkText.implicitWidth + 8
                    radius: 3
                    color: openWorkMouse.containsMouse ? Theme.bgHover : "transparent"

                    Text {
                        id: openWorkText
                        anchors.centerIn: parent
                        text: "Your Work ↗"
                        font.family: Theme.fontMono
                        font.pixelSize: 8
                        font.bold: true
                        color: openWorkMouse.containsMouse ? Theme.accentSky : Theme.textMuted
                    }

                    MouseArea {
                        id: openWorkMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: JiraService.openJira()
                    }
                }
            }
        }
    }
}
