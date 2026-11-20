import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../theme"
import "../services"
import "../components"

PanelWindow {
    id: root

    property bool alignLeft: false
    property bool use24Hour: ShellState.use24Hour
    property bool showSeconds: true
    property bool showCalendar: ShellState.clockShowCalendar

    onUse24HourChanged: {
        if (ShellState.use24Hour !== root.use24Hour) {
            ShellState.use24Hour = root.use24Hour;
        }
    }

    onShowCalendarChanged: {
        if (ShellState.clockShowCalendar !== root.showCalendar) {
            ShellState.clockShowCalendar = root.showCalendar;
        }
    }

    function toggleFormat() {
        ShellState.use24Hour = !ShellState.use24Hour;
    }

    function setFormat(is24) {
        ShellState.use24Hour = is24;
    }

    function getFormattedHours() {
        const h = root.now.getHours();
        if (root.use24Hour) {
            return h < 10 ? ("0" + h) : h.toString();
        } else {
            const h12 = h % 12 || 12;
            return h12.toString();
        }
    }

    property var now: new Date()

    visible: !ShellState.liteMode && ShellState.desktopClockVisible

    Timer {
        interval: 1000
        running: root.visible
        repeat: true
        onTriggered: root.now = new Date()
    }

    anchors {
        top: true
        left: root.alignLeft
        right: !root.alignLeft
    }

    margins {
        top: 76
        left: root.alignLeft ? 48 : 0
        right: !root.alignLeft ? 48 : 0
    }

    implicitWidth: 360
    implicitHeight: mainCard.implicitHeight

    color: "transparent"

    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "quickshell:desktop:clock"
    WlrLayershell.layer: WlrLayer.Bottom

    function getGreeting() {
        const h = root.now.getHours();
        if (h >= 5 && h < 12) return "Good Morning";
        if (h >= 12 && h < 17) return "Good Afternoon";
        if (h >= 17 && h < 22) return "Good Evening";
        return "Deep Space / Late Night";
    }

    function getDayOfYear() {
        const start = new Date(root.now.getFullYear(), 0, 0);
        const diff = root.now - start;
        const oneDay = 1000 * 60 * 60 * 24;
        return Math.floor(diff / oneDay);
    }

    function getWeekNumber() {
        const d = new Date(Date.UTC(root.now.getFullYear(), root.now.getMonth(), root.now.getDate()));
        const dayNum = d.getUTCDay() || 7;
        d.setUTCDate(d.getUTCDate() + 4 - dayNum);
        const yearStart = new Date(Date.UTC(d.getUTCFullYear(), 0, 1));
        return Math.ceil((((d - yearStart) / 86400000) + 1) / 7);
    }

    // Main Card Surface
    Rectangle {
        id: mainCard
        width: 360
        implicitHeight: contentCol.implicitHeight + 36
        radius: 20
        color: ShellState.glassEnabled ? "transparent" : Theme.bgSurfaceGlass
        border.color: ShellState.glassEnabled ? "transparent" : Theme.borderGlow
        border.width: ShellState.glassEnabled ? 0 : 1

        LiquidGlassSurface {
            radius: 20
            visible: ShellState.glassEnabled
            accentColor: Theme.accentCyan
            showShadow: true
        }

        ColumnLayout {
            id: contentCol
            anchors.fill: parent
            anchors.margins: 18
            spacing: 14

            // Top Status & Action Bar
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                // Status Badge
                Rectangle {
                    height: 24
                    implicitWidth: badgeRow.implicitWidth + 14
                    radius: 12
                    color: Theme.bgPill
                    border.color: Theme.borderDim
                    border.width: 1

                    RowLayout {
                        id: badgeRow
                        anchors.centerIn: parent
                        spacing: 6

                        Rectangle {
                            width: 6
                            height: 6
                            radius: 3
                            color: Theme.accentEmerald
                            opacity: 0.9
                        }

                        Text {
                            text: root.getGreeting().toUpperCase()
                            font.family: Theme.fontMono
                            font.pixelSize: 9
                            font.bold: true
                            color: Theme.accentSky
                        }
                    }
                }

                Item { Layout.fillWidth: true }


                // 12H / 24H Segmented Toggle
                Rectangle {
                    height: 26
                    implicitWidth: toggleRow.implicitWidth + 4
                    radius: 6
                    color: Theme.bgPill
                    border.color: Theme.borderDim
                    border.width: 1

                    RowLayout {
                        id: toggleRow
                        anchors.centerIn: parent
                        spacing: 2

                        // 12H Pill
                        Rectangle {
                            height: 20
                            implicitWidth: text12.implicitWidth + 10
                            radius: 4
                            color: ShellState.plasticEnabled
                                ? "transparent"
                                : (!root.use24Hour ? Theme.accentViolet : (mouse12.containsMouse ? Theme.bgHover : "transparent"))

                            LiquidGlassSurface {
                                radius: 4
                                visible: ShellState.plasticEnabled && (!root.use24Hour || mouse12.containsMouse)
                                accentColor: Theme.accentViolet
                                hovered: mouse12.containsMouse
                                pressed: mouse12.pressed
                                showShadow: false
                            }

                            Behavior on color { ColorAnimation { duration: 150 } }

                            Text {
                                id: text12
                                anchors.centerIn: parent
                                text: "12H"
                                font.family: Theme.fontMono
                                font.pixelSize: 10
                                font.bold: true
                                color: !root.use24Hour ? (ShellState.plasticEnabled ? Theme.accentViolet : Theme.textOnAccent) : (mouse12.containsMouse ? Theme.textPrimary : Theme.textMuted)
                            }

                            MouseArea {
                                id: mouse12
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.setFormat(false)
                            }
                        }

                        // 24H Pill
                        Rectangle {
                            height: 20
                            implicitWidth: text24.implicitWidth + 10
                            radius: 4
                            color: ShellState.plasticEnabled
                                ? "transparent"
                                : (root.use24Hour ? Theme.accentViolet : (mouse24.containsMouse ? Theme.bgHover : "transparent"))

                            LiquidGlassSurface {
                                radius: 4
                                visible: ShellState.plasticEnabled && (root.use24Hour || mouse24.containsMouse)
                                accentColor: Theme.accentViolet
                                hovered: mouse24.containsMouse
                                pressed: mouse24.pressed
                                showShadow: false
                            }

                            Behavior on color { ColorAnimation { duration: 150 } }

                            Text {
                                id: text24
                                anchors.centerIn: parent
                                text: "24H"
                                font.family: Theme.fontMono
                                font.pixelSize: 10
                                font.bold: true
                                color: root.use24Hour ? (ShellState.plasticEnabled ? Theme.accentViolet : Theme.textOnAccent) : (mouse24.containsMouse ? Theme.textPrimary : Theme.textMuted)
                            }

                            MouseArea {
                                id: mouse24
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.setFormat(true)
                            }
                        }
                    }
                }

                // Calendar Dropdown Toggle
                Rectangle {
                    width: 26
                    height: 26
                    radius: 6
                    color: ShellState.plasticEnabled
                        ? "transparent"
                        : (root.showCalendar ? Theme.accentViolet : (calMouse.containsMouse ? Theme.bgHover : Theme.bgPill))
                    border.color: ShellState.plasticEnabled
                        ? "transparent"
                        : (root.showCalendar ? Theme.accentViolet : Theme.borderDim)
                    border.width: ShellState.plasticEnabled ? 0 : 1

                    LiquidGlassSurface {
                        radius: 6
                        visible: ShellState.plasticEnabled
                        accentColor: root.showCalendar ? Theme.accentViolet : Theme.accentCyan
                        hovered: calMouse.containsMouse
                        pressed: calMouse.pressed
                        showShadow: false
                    }

                    Icon {
                        anchors.centerIn: parent
                        name: "calendar"
                        size: 13
                        color: root.showCalendar
                            ? (ShellState.plasticEnabled ? Theme.accentViolet : Theme.textOnAccent)
                            : (calMouse.containsMouse ? Theme.textPrimary : Theme.textMuted)
                    }

                    // Calendar Event Notification Pip
                    Rectangle {
                        visible: CalendarService.count > 0
                        anchors.top: parent.top
                        anchors.right: parent.right
                        anchors.topMargin: -3
                        anchors.rightMargin: -3
                        width: 14
                        height: 14
                        radius: 7
                        color: Theme.accentAmber
                        border.color: Theme.bgCard
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: CalendarService.count
                            font.family: Theme.fontMono
                            font.pixelSize: 8
                            font.bold: true
                            color: Theme.bgBase
                        }
                    }

                    MouseArea {
                        id: calMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            ShellState.controlCenterTab = "notifications";
                            ShellState.controlCenterOpen = true;
                        }
                    }
                }
            }

            // Hero Digital Clock Display
            MouseArea {
                Layout.fillWidth: true
                implicitHeight: clockHeroRow.implicitHeight
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.toggleFormat()

                RowLayout {
                    id: clockHeroRow
                    anchors.centerIn: parent
                    spacing: 4

                    // Hours
                    Text {
                        text: root.use24Hour ? Qt.formatTime(root.now, "HH") : (root.now.getHours() % 12 || 12).toString()
                        font.family: Theme.fontFamily
                        font.pixelSize: 58
                        font.bold: true
                        color: Theme.textPrimary
                    }

                    // Pulsing Colon
                    Text {
                        text: ":"
                        font.family: Theme.fontMono
                        font.pixelSize: 54
                        font.bold: true
                        color: Theme.accentSky
                        opacity: (root.now.getSeconds() % 2 === 0) ? 1.0 : 0.35

                        Behavior on opacity {
                            NumberAnimation { duration: 250 }
                        }
                    }

                    // Minutes
                    Text {
                        text: Qt.formatTime(root.now, "mm")
                        font.family: Theme.fontFamily
                        font.pixelSize: 58
                        font.bold: true
                        color: Theme.textPrimary
                    }

                    // Side stack: AM/PM tag and Seconds pill
                    ColumnLayout {
                        Layout.leftMargin: 8
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 4

                        // AM / PM Pill (when 12h mode)
                        Rectangle {
                            visible: !root.use24Hour
                            implicitWidth: ampmText.implicitWidth + 8
                            height: 16
                            radius: 4
                            color: Theme.accentViolet
                            Text {
                                id: ampmText
                                anchors.centerIn: parent
                                text: root.now.getHours() >= 12 ? "PM" : "AM"
                                font.family: Theme.fontMono
                                font.pixelSize: 9
                                font.bold: true
                                color: Theme.textOnAccent
                            }
                        }

                        // Seconds Pill
                        Rectangle {
                            implicitWidth: secText.implicitWidth + 10
                            height: 20
                            radius: 10
                            color: Theme.bgPill
                            border.color: Theme.borderDim
                            border.width: 1

                            Text {
                                id: secText
                                anchors.centerIn: parent
                                text: Qt.formatTime(root.now, "ss")
                                font.family: Theme.fontMono
                                font.pixelSize: 11
                                font.bold: true
                                color: Theme.accentSky
                            }
                        }
                    }
                }
            }

            // Date & Weekday Display
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: Qt.formatDate(root.now, "dddd").toUpperCase()
                    font.family: Theme.fontMono
                    font.pixelSize: 12
                    font.bold: true
                    color: Theme.accentViolet
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: Qt.formatDate(root.now, "MMMM d, yyyy")
                    font.family: Theme.fontFamily
                    font.pixelSize: 14
                    color: Theme.textSecondary
                }
            }

            // Divider Line
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Theme.borderDim
            }

            // Metadata Chips (Week Number, Day of Year, Local Timezone)
            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                // Week Chip
                Rectangle {
                    Layout.fillWidth: true
                    height: 28
                    radius: 8
                    color: Theme.bgPill
                    border.color: Theme.borderDim
                    border.width: 1

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 4
                        Text {
                            text: "WK"
                            font.family: Theme.fontMono
                            font.pixelSize: 9
                            color: Theme.textMuted
                        }
                        Text {
                            text: root.getWeekNumber()
                            font.family: Theme.fontMono
                            font.pixelSize: 11
                            font.bold: true
                            color: Theme.textPrimary
                        }
                    }
                }

                // Day of Year Chip
                Rectangle {
                    Layout.fillWidth: true
                    height: 28
                    radius: 8
                    color: Theme.bgPill
                    border.color: Theme.borderDim
                    border.width: 1

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 4
                        Text {
                            text: "DAY"
                            font.family: Theme.fontMono
                            font.pixelSize: 9
                            color: Theme.textMuted
                        }
                        Text {
                            text: root.getDayOfYear()
                            font.family: Theme.fontMono
                            font.pixelSize: 11
                            font.bold: true
                            color: Theme.textPrimary
                        }
                    }
                }

                // Year Progress Chip
                Rectangle {
                    Layout.fillWidth: true
                    height: 28
                    radius: 8
                    color: Theme.bgPill
                    border.color: Theme.borderDim
                    border.width: 1

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 4
                        Text {
                            text: "YR"
                            font.family: Theme.fontMono
                            font.pixelSize: 9
                            color: Theme.textMuted
                        }
                        Text {
                            text: Math.round((root.getDayOfYear() / 365) * 100) + "%"
                            font.family: Theme.fontMono
                            font.pixelSize: 11
                            font.bold: true
                            color: Theme.accentEmerald
                        }
                    }
                }
            }

            // ── Divider ───────────────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Theme.borderDim
            }

            // ── Today's Schedule & Future Events ──────────────────────
            ColumnLayout {
                id: scheduleCol
                Layout.fillWidth: true
                spacing: 8

                // Header Row
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Rectangle {
                        width: 6
                        height: 6
                        radius: 3
                        color: CalendarService.hasEventsToday ? Theme.accentAmber : Theme.textMuted
                    }

                    Text {
                        text: "TODAY'S SCHEDULE"
                        font.family: Theme.fontMono
                        font.pixelSize: 10
                        font.bold: true
                        color: Theme.accentAmber
                    }

                    Item { Layout.fillWidth: true }

                    // Count Badge
                    Rectangle {
                        height: 18
                        implicitWidth: schedCountTxt.implicitWidth + 10
                        radius: 9
                        color: Theme.bgPill
                        border.color: CalendarService.count > 0 ? Theme.accentAmber : Theme.borderDim
                        border.width: 1

                        Text {
                            id: schedCountTxt
                            anchors.centerIn: parent
                            text: CalendarService.loading ? "SYNCING..." : (CalendarService.count + " EVENTS")
                            font.family: Theme.fontMono
                            font.pixelSize: 8
                            font.bold: true
                            color: CalendarService.count > 0 ? Theme.accentAmber : Theme.textMuted
                        }
                    }

                    // Refresh Button
                    Rectangle {
                        width: 18
                        height: 18
                        radius: 4
                        color: refCalMouse.containsMouse ? Theme.bgHover : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: "↻"
                            font.pixelSize: 11
                            color: refCalMouse.containsMouse ? Theme.accentAmber : Theme.textMuted

                            RotationAnimation on rotation {
                                running: CalendarService.loading
                                loops: Animation.Infinite
                                from: 0; to: 360
                                duration: 1000
                            }
                        }

                        MouseArea {
                            id: refCalMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: CalendarService.refresh(true)
                        }
                    }
                }

                // Today's Events List
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 6
                    visible: CalendarService.todayEvents.length > 0

                    Repeater {
                        model: CalendarService.todayEvents

                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: evCol.implicitHeight + 14
                            radius: 8
                            color: evMouse.containsMouse
                                ? Qt.rgba(Theme.bgHover.r, Theme.bgHover.g, Theme.bgHover.b, 0.8)
                                : Qt.rgba(Theme.bgCard.r, Theme.bgCard.g, Theme.bgCard.b, 0.5)
                            border.color: modelData.is_now
                                ? Theme.accentEmerald
                                : (evMouse.containsMouse ? Theme.accentAmber : Theme.borderDim)
                            border.width: 1

                            Behavior on border.color { ColorAnimation { duration: 150 } }
                            Behavior on color { ColorAnimation { duration: 150 } }

                            RowLayout {
                                id: evCol
                                anchors.fill: parent
                                anchors.margins: 8
                                spacing: 8

                                // Color pill
                                Rectangle {
                                    width: 3
                                    Layout.fillHeight: true
                                    radius: 1.5
                                    color: modelData.calendar_color || Theme.accentAmber
                                }

                                // Event Info
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 6

                                        Text {
                                            text: modelData.title
                                            font.family: Theme.fontFamily
                                            font.pixelSize: 11
                                            font.bold: true
                                            color: Theme.textPrimary
                                            Layout.fillWidth: true
                                            elide: Text.ElideRight
                                        }

                                        // Status Pill (NOW / Starts in)
                                        Rectangle {
                                            visible: modelData.is_now || (!modelData.is_all_day && modelData.starts_in_mins > 0 && modelData.starts_in_mins <= 180)
                                            height: 14
                                            implicitWidth: statusTxt.implicitWidth + 8
                                            radius: 3
                                            color: modelData.is_now ? Theme.accentEmerald : Qt.rgba(Theme.accentSky.r, Theme.accentSky.g, Theme.accentSky.b, 0.2)

                                            Text {
                                                id: statusTxt
                                                anchors.centerIn: parent
                                                text: modelData.is_now ? "NOW" : (modelData.starts_in_mins <= 60 ? (modelData.starts_in_mins + "m") : (Math.floor(modelData.starts_in_mins / 60) + "h"))
                                                font.family: Theme.fontMono
                                                font.pixelSize: 8
                                                font.bold: true
                                                color: modelData.is_now ? Theme.bgBase : Theme.accentSky
                                            }
                                        }
                                    }

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 6

                                        Text {
                                            text: modelData.time_str
                                            font.family: Theme.fontMono
                                            font.pixelSize: 9
                                            color: Theme.accentSky
                                        }

                                        Text {
                                            visible: modelData.location && modelData.location.length > 0
                                            text: "• " + modelData.location
                                            font.family: Theme.fontFamily
                                            font.pixelSize: 9
                                            color: Theme.textMuted
                                            Layout.fillWidth: true
                                            elide: Text.ElideRight
                                        }
                                    }
                                }
                            }

                            MouseArea {
                                id: evMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: CalendarService.openCalendar()
                            }
                        }
                    }
                }

                // Empty State
                Rectangle {
                    Layout.fillWidth: true
                    height: 34
                    radius: 8
                    visible: CalendarService.todayEvents.length === 0
                    color: Theme.bgPill
                    border.color: Theme.borderDim
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "🎉 No events scheduled for today"
                        font.family: Theme.fontMono
                        font.pixelSize: 9
                        color: Theme.textMuted
                    }
                }

                // ── Upcoming / Future Events Preview ─────────────────────────
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4
                    visible: CalendarService.upcomingEvents.length > 0

                    Text {
                        text: "UPCOMING THIS WEEK"
                        font.family: Theme.fontMono
                        font.pixelSize: 9
                        font.bold: true
                        color: Theme.textMuted
                        Layout.topMargin: 4
                    }

                    Repeater {
                        model: CalendarService.upcomingEvents.slice(0, 3)

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Rectangle {
                                width: 4
                                height: 4
                                radius: 2
                                color: Theme.accentViolet
                            }

                            Text {
                                text: modelData.date_str
                                font.family: Theme.fontMono
                                font.pixelSize: 9
                                font.bold: true
                                color: Theme.accentViolet
                            }

                            Text {
                                text: modelData.title
                                font.family: Theme.fontFamily
                                font.pixelSize: 10
                                color: Theme.textSecondary
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }

                            Text {
                                text: modelData.time_str
                                font.family: Theme.fontMono
                                font.pixelSize: 8
                                color: Theme.textMuted
                            }
                        }
                    }
                }

                // ── Footer ────────────────────────────────────────────────
                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: 4

                    Text {
                        text: "Calendar • " + (CalendarService.status === "offline" ? "Offline" : "Synced")
                        font.family: Theme.fontMono
                        font.pixelSize: 9
                        color: Theme.textMuted
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        text: "Google Calendar ↗"
                        font.family: Theme.fontMono
                        font.pixelSize: 9
                        font.bold: true
                        color: openCalM.containsMouse ? Theme.accentCyan : Theme.textMuted

                        MouseArea {
                            id: openCalM
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
}
