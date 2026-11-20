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

    property bool alignLeft: false
    visible: !ShellState.liteMode && ShellState.desktopAgendaVisible

    anchors {
        top: true
        left: root.alignLeft
        right: !root.alignLeft
    }

    margins {
        top: 76
        left: root.alignLeft ? 48 : 0
        // Position next to DesktopClock (width 360 + 16px gap + 48px right margin) if clock is visible
        right: !root.alignLeft ? (ShellState.desktopClockVisible ? (48 + 360 + 16) : 48) : 0
    }

    implicitWidth: 320
    implicitHeight: mainCard.implicitHeight

    color: "transparent"

    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "quickshell:desktop:agenda"
    WlrLayershell.layer: WlrLayer.Bottom

    // Main Card Surface
    Rectangle {
        id: mainCard
        width: 320
        implicitHeight: contentCol.implicitHeight + 24
        radius: 14
        color: ShellState.glassEnabled ? "transparent" : Theme.bgSurfaceGlass
        border.color: ShellState.glassEnabled ? "transparent" : Theme.borderGlow
        border.width: ShellState.glassEnabled ? 0 : 1

        LiquidGlassSurface {
            radius: 14
            visible: ShellState.glassEnabled
            accentColor: Theme.accentAmber
            showShadow: true
        }

        ColumnLayout {
            id: contentCol
            anchors.fill: parent
            anchors.margins: 14
            spacing: 10

            // ── Header Section ──────────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                // Calendar Gem Icon
                Rectangle {
                    width: 26
                    height: 26
                    radius: 13
                    color: ShellState.plasticEnabled ? "transparent" : Qt.rgba(Theme.accentAmber.r, Theme.accentAmber.g, Theme.accentAmber.b, 0.15)
                    border.color: ShellState.plasticEnabled ? "transparent" : Theme.accentAmber
                    border.width: ShellState.plasticEnabled ? 0 : 1

                    LiquidGlassSurface {
                        radius: 13
                        visible: ShellState.plasticEnabled
                        accentColor: Theme.accentAmber
                        showShadow: false
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "📅"
                        font.pixelSize: 13
                    }
                }

                // Title & Subtitle
                ColumnLayout {
                    spacing: 1
                    Text {
                        text: "AGENDA & EVENTS"
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        font.bold: true
                        color: Theme.textPrimary
                    }
                    Text {
                        text: !NetworkService.isOnline
                              ? ("Offline • " + CalendarService.count + " cached")
                              : (CalendarService.loading ? "Updating..." : (CalendarService.count + " events today • " + CalendarService.lastUpdated))
                        font.family: Theme.fontMono
                        font.pixelSize: 8
                        color: !NetworkService.isOnline ? Theme.accentAmber : Theme.textMuted
                    }
                }

                Item { Layout.fillWidth: true }

                // Count Badge
                Rectangle {
                    height: 18
                    implicitWidth: countText.implicitWidth + 10
                    radius: 9
                    color: Theme.bgPill
                    border.color: !NetworkService.isOnline ? Theme.accentAmber : (CalendarService.count > 0 ? Theme.accentAmber : Theme.borderDim)
                    border.width: 1

                    Text {
                        id: countText
                        anchors.centerIn: parent
                        text: !NetworkService.isOnline
                              ? (CalendarService.count + " CACHED")
                              : (CalendarService.count + " TODAY")
                        font.family: Theme.fontMono
                        font.pixelSize: 8
                        font.bold: true
                        color: !NetworkService.isOnline ? Theme.accentAmber : (CalendarService.count > 0 ? Theme.accentAmber : Theme.textMuted)
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
                        font.pixelSize: 12
                        color: refreshMouse.containsMouse ? Theme.accentAmber : Theme.textMuted

                        RotationAnimation on rotation {
                            running: CalendarService.loading
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
                        onClicked: CalendarService.refresh(true)
                    }
                }
            }

            // ── Next Event Hero Banner ──────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                visible: CalendarService.nextEvent !== null
                implicitHeight: heroCol.implicitHeight + 16
                radius: 10
                color: ShellState.plasticEnabled
                    ? Qt.rgba(Theme.accentAmber.r, Theme.accentAmber.g, Theme.accentAmber.b, 0.12)
                    : Qt.rgba(Theme.bgCard.r, Theme.bgCard.g, Theme.bgCard.b, 0.75)
                border.color: Qt.rgba(Theme.accentAmber.r, Theme.accentAmber.g, Theme.accentAmber.b, 0.35)
                border.width: 1

                ColumnLayout {
                    id: heroCol
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 6

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        // Status dot
                        Rectangle {
                            width: 6
                            height: 6
                            radius: 3
                            color: (CalendarService.nextEvent && CalendarService.nextEvent.is_now) ? Theme.accentEmerald : Theme.accentAmber
                        }

                        Text {
                            text: {
                                const ev = CalendarService.nextEvent;
                                if (!ev) return "";
                                if (ev.is_now) return "HAPPENING NOW";
                                if (ev.is_all_day) return "TODAY • ALL DAY";
                                if (ev.starts_in_mins <= 60) return "STARTS IN " + ev.starts_in_mins + "m";
                                const hrs = Math.floor(ev.starts_in_mins / 60);
                                const mins = ev.starts_in_mins % 60;
                                return "STARTS IN " + hrs + "h " + (mins > 0 ? (mins + "m") : "");
                            }
                            font.family: Theme.fontMono
                            font.pixelSize: 8
                            font.bold: true
                            color: (CalendarService.nextEvent && CalendarService.nextEvent.is_now) ? Theme.accentEmerald : Theme.accentAmber
                            Layout.fillWidth: true
                        }

                        // Join Call Button (if meeting url exists)
                        Rectangle {
                            visible: CalendarService.nextEvent && CalendarService.nextEvent.meet_url !== null
                            height: 18
                            implicitWidth: joinText.implicitWidth + 10
                            radius: 4
                            color: joinMouse.containsMouse ? Theme.accentAmber : Qt.rgba(Theme.accentAmber.r, Theme.accentAmber.g, Theme.accentAmber.b, 0.25)
                            border.color: Theme.accentAmber
                            border.width: 1

                            Text {
                                id: joinText
                                anchors.centerIn: parent
                                text: "Join Call ↗"
                                font.family: Theme.fontMono
                                font.pixelSize: 8
                                font.bold: true
                                color: joinMouse.containsMouse ? Theme.bgBase : Theme.accentAmber
                            }

                            MouseArea {
                                id: joinMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (CalendarService.nextEvent && CalendarService.nextEvent.meet_url) {
                                        CalendarService.openMeet(CalendarService.nextEvent.meet_url);
                                    }
                                }
                            }
                        }
                    }

                    // Next Event Title
                    Text {
                        text: CalendarService.nextEvent ? CalendarService.nextEvent.title : ""
                        font.family: Theme.fontFamily
                        font.pixelSize: 13
                        font.bold: true
                        color: Theme.textPrimary
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }

                    // Next Event Time & Location
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Text {
                            text: CalendarService.nextEvent ? CalendarService.nextEvent.time_str : ""
                            font.family: Theme.fontMono
                            font.pixelSize: 9
                            color: Theme.accentSky
                        }

                        Item { Layout.fillWidth: true }

                        Text {
                            visible: CalendarService.nextEvent && CalendarService.nextEvent.location.length > 0
                            text: CalendarService.nextEvent ? CalendarService.nextEvent.location : ""
                            font.family: Theme.fontFamily
                            font.pixelSize: 9
                            color: Theme.textMuted
                            elide: Text.ElideRight
                            Layout.maximumWidth: 150
                        }
                    }
                }
            }

            // ── Today's Schedule List ───────────────────────────────────────
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 6

                Text {
                    text: "TODAY'S SCHEDULE"
                    font.family: Theme.fontMono
                    font.pixelSize: 8
                    font.bold: true
                    color: Theme.textMuted
                }

                // Empty State
                Rectangle {
                    visible: CalendarService.todayEvents.length === 0
                    Layout.fillWidth: true
                    height: 50
                    radius: 8
                    color: Qt.rgba(Theme.bgCard.r, Theme.bgCard.g, Theme.bgCard.b, 0.4)
                    border.color: Theme.borderDim
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "🎉 No events scheduled for today!"
                        font.family: Theme.fontMono
                        font.pixelSize: 9
                        color: Theme.textMuted
                    }
                }

                Repeater {
                    model: CalendarService.todayEvents

                    Rectangle {
                        id: evCard
                        Layout.fillWidth: true
                        implicitHeight: evRow.implicitHeight + 12
                        radius: 8
                        color: evMouse.containsMouse ? Theme.bgHover : Qt.rgba(Theme.bgCard.r, Theme.bgCard.g, Theme.bgCard.b, 0.5)
                        border.color: evMouse.containsMouse ? Theme.accentAmber : Theme.borderDim
                        border.width: 1

                        RowLayout {
                            id: evRow
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 8

                            // Calendar color pill
                            Rectangle {
                                width: 3
                                height: 24
                                radius: 1.5
                                color: modelData.calendar_color || Theme.accentAmber
                            }

                            // Event Details
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                Text {
                                    text: modelData.title
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 11
                                    font.bold: true
                                    color: modelData.is_now ? Theme.accentAmber : Theme.textPrimary
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 6

                                    Text {
                                        text: modelData.time_str
                                        font.family: Theme.fontMono
                                        font.pixelSize: 8
                                        color: modelData.is_now ? Theme.accentEmerald : Theme.textMuted
                                    }

                                    Text {
                                        visible: modelData.location && modelData.location.length > 0
                                        text: "• " + modelData.location
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 8
                                        color: Theme.textMuted
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }
                                }
                            }

                            // Meet Icon / Link
                            Rectangle {
                                visible: modelData.meet_url !== null && modelData.meet_url !== undefined
                                width: 20
                                height: 20
                                radius: 4
                                color: Theme.bgPill
                                border.color: Theme.borderDim
                                border.width: 1

                                Text {
                                    anchors.centerIn: parent
                                    text: "↗"
                                    font.pixelSize: 10
                                    color: Theme.accentAmber
                                }
                            }
                        }

                        MouseArea {
                            id: evMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (modelData.meet_url) {
                                    CalendarService.openMeet(modelData.meet_url);
                                } else {
                                    CalendarService.openCalendar();
                                }
                            }
                        }
                    }
                }
            }

            // ── Upcoming Events Preview (Next 7 Days) ────────────────────────
            ColumnLayout {
                Layout.fillWidth: true
                visible: CalendarService.upcomingEvents.length > 0
                spacing: 4

                Text {
                    text: "UPCOMING THIS WEEK"
                    font.family: Theme.fontMono
                    font.pixelSize: 8
                    font.bold: true
                    color: Theme.textMuted
                }

                Repeater {
                    model: CalendarService.upcomingEvents.slice(0, 3)

                    Rectangle {
                        Layout.fillWidth: true
                        height: 24
                        radius: 5
                        color: "transparent"

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 4
                            anchors.rightMargin: 4
                            spacing: 6

                            Rectangle {
                                width: 4
                                height: 4
                                radius: 2
                                color: Theme.accentSky
                            }

                            Text {
                                text: modelData.title
                                font.family: Theme.fontFamily
                                font.pixelSize: 10
                                color: Theme.textSecondary
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            Text {
                                text: modelData.date_str
                                font.family: Theme.fontMono
                                font.pixelSize: 8
                                color: Theme.textMuted
                            }
                        }
                    }
                }
            }

            // ── Footer ──────────────────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: 4

                Text {
                    text: "LEEE & ALVEE  •  " + (NetworkService.isOnline ? "Sync active" : "Offline mode")
                    font.family: Theme.fontMono
                    font.pixelSize: 8
                    color: Theme.textMuted
                }

                Item { Layout.fillWidth: true }

                Rectangle {
                    height: 16
                    implicitWidth: openCalText.implicitWidth + 8
                    radius: 3
                    color: openCalMouse.containsMouse ? Theme.bgHover : "transparent"

                    Text {
                        id: openCalText
                        anchors.centerIn: parent
                        text: "Google Calendar ↗"
                        font.family: Theme.fontMono
                        font.pixelSize: 8
                        font.bold: true
                        color: openCalMouse.containsMouse ? Theme.accentAmber : Theme.textMuted
                    }

                    MouseArea {
                        id: openCalMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: CalendarService.openCalendar()
                    }
                }
            }
        }
    }
}
