import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../theme"
import "../services"

PanelWindow {
    id: root

    property bool alignLeft: false
    property bool use24Hour: true
    property bool showSeconds: true
    property bool showCalendar: true

    property var now: new Date()

    visible: ShellState.desktopClockVisible

    Timer {
        interval: 1000
        running: true
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
        color: Theme.bgSurfaceGlass
        border.color: Theme.borderGlow
        border.width: 1

        // Subtle gradient sheen
        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 1
            color: Qt.rgba(Theme.accentSky.r, Theme.accentSky.g, Theme.accentSky.b, 0.4)
            radius: parent.radius
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

                            SequentialAnimation on opacity {
                                loops: Animation.Infinite
                                PropertyAnimation { to: 0.4; duration: 1500 }
                                PropertyAnimation { to: 1.0; duration: 1500 }
                            }
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

                // Reposition Toggle (Left <-> Right)
                Rectangle {
                    width: 26
                    height: 26
                    radius: 6
                    color: posMouse.containsMouse ? Theme.bgHover : Theme.bgPill
                    border.color: Theme.borderDim
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: root.alignLeft ? "⇥" : "⇤"
                        font.pixelSize: 12
                        color: posMouse.containsMouse ? Theme.accentSky : Theme.textMuted
                    }

                    MouseArea {
                        id: posMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.alignLeft = !root.alignLeft
                    }
                }

                // 12H / 24H Toggle Button
                Rectangle {
                    height: 26
                    implicitWidth: modeText.implicitWidth + 12
                    radius: 6
                    color: modeMouse.containsMouse ? Theme.bgHover : Theme.bgPill
                    border.color: Theme.borderDim
                    border.width: 1

                    Text {
                        id: modeText
                        anchors.centerIn: parent
                        text: root.use24Hour ? "24H" : "12H"
                        font.family: Theme.fontMono
                        font.pixelSize: 10
                        font.bold: true
                        color: modeMouse.containsMouse ? Theme.accentViolet : Theme.textMuted
                    }

                    MouseArea {
                        id: modeMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.use24Hour = !root.use24Hour
                    }
                }

                // Calendar Dropdown Toggle
                Rectangle {
                    width: 26
                    height: 26
                    radius: 6
                    color: root.showCalendar ? Theme.accentViolet : (calMouse.containsMouse ? Theme.bgHover : Theme.bgPill)
                    border.color: root.showCalendar ? Theme.accentViolet : Theme.borderDim
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "📅"
                        font.pixelSize: 11
                    }

                    MouseArea {
                        id: calMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.showCalendar = !root.showCalendar
                    }
                }
            }

            // Hero Digital Clock Display
            MouseArea {
                Layout.fillWidth: true
                implicitHeight: clockHeroRow.implicitHeight
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.use24Hour = !root.use24Hour

                RowLayout {
                    id: clockHeroRow
                    anchors.centerIn: parent
                    spacing: 4

                    // Hours
                    Text {
                        text: root.use24Hour ? Qt.formatTime(root.now, "HH") : Qt.formatTime(root.now, "hh")
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
                                text: Qt.formatTime(root.now, "AP")
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

            // Expandable Mini Calendar Grid
            ColumnLayout {
                id: calendarSection
                Layout.fillWidth: true
                visible: root.showCalendar
                Layout.preferredHeight: root.showCalendar ? implicitHeight : 0
                clip: true
                spacing: 8

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Theme.borderDim
                }

                // Month header
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: Qt.formatDate(root.now, "MMMM yyyy").toUpperCase()
                    font.family: Theme.fontMono
                    font.pixelSize: 11
                    font.bold: true
                    color: Theme.accentSky
                }

                // Weekday initials
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    Repeater {
                        model: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
                        Item {
                            Layout.fillWidth: true
                            height: 20
                            Text {
                                anchors.centerIn: parent
                                text: modelData
                                font.family: Theme.fontMono
                                font.pixelSize: 10
                                font.bold: true
                                color: (modelData === "Sa" || modelData === "Su") ? Theme.accentRose : Theme.textMuted
                            }
                        }
                    }
                }

                // Days Grid (6 rows x 7 days)
                GridLayout {
                    Layout.fillWidth: true
                    columns: 7
                    columnSpacing: 2
                    rowSpacing: 2

                    Repeater {
                        // 42 cells total (6 weeks x 7 days)
                        model: 42

                        delegate: Item {
                            Layout.fillWidth: true
                            height: 26

                            readonly property int currentYear: root.now.getFullYear()
                            readonly property int currentMonth: root.now.getMonth()
                            readonly property int todayDate: root.now.getDate()

                            // First day of current month: 0=Sun, 1=Mon, ..., 6=Sat
                            readonly property int rawFirstDay: new Date(currentYear, currentMonth, 1).getDay()
                            // Shift so Mon=0, Sun=6
                            readonly property int firstDayOffset: (rawFirstDay + 6) % 7
                            readonly property int totalDaysInMonth: new Date(currentYear, currentMonth + 1, 0).getDate()

                            readonly property int dayNumber: index - firstDayOffset + 1
                            readonly property bool isCurrentMonthDay: (dayNumber >= 1 && dayNumber <= totalDaysInMonth)
                            readonly property bool isToday: isCurrentMonthDay && (dayNumber === todayDate)

                            Rectangle {
                                anchors.centerIn: parent
                                width: 24
                                height: 24
                                radius: 12
                                visible: isCurrentMonthDay
                                color: isToday ? Theme.accentViolet : "transparent"
                                border.color: isToday ? Theme.accentSky : "transparent"
                                border.width: isToday ? 1 : 0

                                Text {
                                    anchors.centerIn: parent
                                    text: isCurrentMonthDay ? dayNumber : ""
                                    font.family: Theme.fontMono
                                    font.pixelSize: 10
                                    font.bold: isToday
                                    color: isToday ? Theme.textOnAccent : Theme.textPrimary
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
