import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import "../theme"
import "../services"

PanelWindow {
    id: clipWindow

    visible: ShellState.clipboardOpen
    color: "transparent"

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "quickshell:clipboard"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: ShellState.clipboardOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    onVisibleChanged: {
        if (visible) {
            searchInput.text = "";
            ClipboardService.refresh();
            Qt.callLater(() => {
                searchInput.forceActiveFocus();
            });
        }
    }

    // Backdrop click
    MouseArea {
        anchors.fill: parent
        onClicked: ShellState.clipboardOpen = false

        Rectangle {
            anchors.fill: parent
            color: "#000000"
            opacity: 0.70
        }
    }

    // Modal Card
    Rectangle {
        id: card
        width: 780
        height: 540
        anchors.centerIn: parent
        radius: Theme.cardRadius
        color: Theme.bgModal
        border.color: Theme.borderGlow
        border.width: 1

        MouseArea {
            anchors.fill: parent
            onClicked: {}
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 18
            spacing: 12

            // Search & Header Bar
            Rectangle {
                Layout.fillWidth: true
                height: 46
                radius: 10
                color: Theme.bgBase
                border.color: searchInput.activeFocus ? Theme.accentCyan : Theme.borderDim
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14
                    spacing: 10

                    Text {
                        text: "📋"
                        font.pixelSize: 14
                    }

                    TextInput {
                        id: searchInput
                        Layout.fillWidth: true
                        font.family: Theme.fontFamily
                        font.pixelSize: 13
                        color: Theme.textPrimary
                        selectByMouse: true
                        clip: true

                        Text {
                            text: "Search clipboard history..."
                            font.family: Theme.fontFamily
                            font.pixelSize: 13
                            color: Theme.textMuted
                            visible: !searchInput.text && !searchInput.activeFocus
                        }

                        onTextChanged: {
                            ClipboardService.search(searchInput.text);
                            clipList.currentIndex = 0;
                            if (ClipboardService.items.length > 0) {
                                ClipboardService.selectItem(ClipboardService.items[0].id);
                            }
                        }

                        Keys.onEscapePressed: {
                            ShellState.clipboardOpen = false;
                        }

                        Keys.onDownPressed: {
                            clipList.incrementCurrentIndex();
                            if (clipList.currentItem) {
                                ClipboardService.selectItem(ClipboardService.items[clipList.currentIndex].id);
                            }
                        }

                        Keys.onUpPressed: {
                            clipList.decrementCurrentIndex();
                            if (clipList.currentItem) {
                                ClipboardService.selectItem(ClipboardService.items[clipList.currentIndex].id);
                            }
                        }

                        Keys.onReturnPressed: {
                            if (ClipboardService.items.length > 0 && clipList.currentIndex >= 0) {
                                const selected = ClipboardService.items[clipList.currentIndex];
                                if (selected) ClipboardService.copyItem(selected.id);
                            }
                        }

                        Keys.onDeletePressed: {
                            if (ClipboardService.items.length > 0 && clipList.currentIndex >= 0) {
                                const selected = ClipboardService.items[clipList.currentIndex];
                                if (selected) ClipboardService.deleteItem(selected.id, selected.text);
                            }
                        }
                    }

                    // Count Badge
                    Rectangle {
                        height: 20
                        implicitWidth: countText.implicitWidth + 10
                        radius: 10
                        color: Theme.bgPill
                        Text {
                            id: countText
                            anchors.centerIn: parent
                            text: ClipboardService.items.length + " items"
                            font.family: Theme.fontMono
                            font.pixelSize: 9
                            color: Theme.textMuted
                        }
                    }
                }
            }

            // Split View: List on Left, Preview on Right
            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 12

                // Left Column: Items List
                Rectangle {
                    Layout.preferredWidth: 380
                    Layout.fillHeight: true
                    radius: 10
                    color: Theme.bgCard
                    border.color: Theme.borderDim
                    border.width: 1
                    clip: true

                    ListView {
                        id: clipList
                        anchors.fill: parent
                        anchors.margins: 6
                        model: ClipboardService.items
                        spacing: 4
                        boundsBehavior: Flickable.StopAtBounds

                        delegate: Rectangle {
                            id: itemDelegate
                            width: clipList.width
                            height: 48
                            radius: 8
                            readonly property bool isCurrent: clipList.currentIndex === index || ClipboardService.selectedId === modelData.id
                            color: isCurrent ? Theme.bgActive : (itemMouse.containsMouse ? Theme.bgHover : "transparent")

                            Behavior on color { ColorAnimation { duration: 100 } }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 10
                                spacing: 8

                                // Type icon pill
                                Rectangle {
                                    width: 26
                                    height: 26
                                    radius: 6
                                    color: Theme.bgPill
                                    border.color: Theme.borderDim
                                    border.width: 1

                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData.type === "url" ? "🔗" : (modelData.type === "code" ? "💻" : (modelData.type === "image" ? "🖼" : "📄"))
                                        font.pixelSize: 11
                                    }
                                }

                                // Text snippet
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2

                                    Text {
                                        Layout.fillWidth: true
                                        text: modelData.text
                                        font.family: Theme.fontMono
                                        font.pixelSize: 11
                                        color: itemDelegate.isCurrent ? Theme.accentSky : Theme.textPrimary
                                        elide: Text.ElideRight
                                        maximumLineCount: 1
                                    }

                                    Text {
                                        text: "#" + modelData.id + " • " + modelData.type.toUpperCase()
                                        font.family: Theme.fontMono
                                        font.pixelSize: 9
                                        color: Theme.textMuted
                                    }
                                }

                                // Delete button on hover
                                Rectangle {
                                    width: 20
                                    height: 20
                                    radius: 10
                                    visible: itemMouse.containsMouse
                                    color: delMouse.containsMouse ? Theme.accentRose : "transparent"

                                    Text {
                                        anchors.centerIn: parent
                                        text: "✕"
                                        font.pixelSize: 10
                                        color: delMouse.containsMouse ? "#FFFFFF" : Theme.textMuted
                                    }

                                    MouseArea {
                                        id: delMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            ClipboardService.deleteItem(modelData.id, modelData.text);
                                        }
                                    }
                                }
                            }

                            MouseArea {
                                id: itemMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    clipList.currentIndex = index;
                                    ClipboardService.selectItem(modelData.id);
                                }
                                onDoubleClicked: {
                                    ClipboardService.copyItem(modelData.id);
                                }
                            }
                        }

                        // Empty State
                        Text {
                            anchors.centerIn: parent
                            text: "No clipboard items found"
                            font.family: Theme.fontFamily
                            font.pixelSize: 12
                            color: Theme.textMuted
                            visible: ClipboardService.items.length === 0
                        }
                    }
                }

                // Right Column: Live Decoded Preview
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 10
                    color: Theme.bgCard
                    border.color: Theme.borderDim
                    border.width: 1
                    clip: true

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 8

                        // Preview Header
                        RowLayout {
                            Layout.fillWidth: true

                            Text {
                                text: "PREVIEW CONTENT"
                                font.family: Theme.fontMono
                                font.pixelSize: 10
                                font.bold: true
                                color: Theme.accentCyan
                            }

                            Item { Layout.fillWidth: true }

                            // Quick Copy Button
                            Rectangle {
                                height: 24
                                implicitWidth: copyRow.implicitWidth + 12
                                radius: 6
                                color: copyMouse.containsMouse ? Theme.accentViolet : Theme.bgPill
                                border.color: Theme.borderDim
                                border.width: 1

                                RowLayout {
                                    id: copyRow
                                    anchors.centerIn: parent
                                    spacing: 4

                                    Text {
                                        text: "⎘"
                                        font.pixelSize: 11
                                        color: copyMouse.containsMouse ? Theme.textOnAccent : Theme.accentViolet
                                    }
                                    Text {
                                        text: "Paste"
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 10
                                        font.bold: true
                                        color: copyMouse.containsMouse ? Theme.textOnAccent : Theme.textPrimary
                                    }
                                }

                                MouseArea {
                                    id: copyMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (ClipboardService.selectedId) {
                                            ClipboardService.copyItem(ClipboardService.selectedId);
                                        }
                                    }
                                }
                            }
                        }

                        // Preview Scroll Area
                        ScrollView {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true

                            TextArea {
                                id: previewText
                                text: ClipboardService.previewContent || "Select an item to view preview"
                                font.family: Theme.fontMono
                                font.pixelSize: 11
                                color: ClipboardService.previewContent ? Theme.textPrimary : Theme.textMuted
                                wrapMode: Text.WrapAnywhere
                                readOnly: true
                                background: null
                                selectByMouse: true
                            }
                        }
                    }
                }
            }

            // Bottom Footer Bar
            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: "<Enter> Paste • <Del> Delete • <Esc> Close • <Double-Click> Paste"
                    font.family: Theme.fontMono
                    font.pixelSize: 9
                    color: Theme.textMuted
                }

                Item { Layout.fillWidth: true }

                // Clear History Button
                Rectangle {
                    height: 24
                    implicitWidth: clearRow.implicitWidth + 12
                    radius: 6
                    color: clearMouse.containsMouse ? Theme.accentRose : Theme.bgPill
                    border.color: Theme.borderDim
                    border.width: 1

                    RowLayout {
                        id: clearRow
                        anchors.centerIn: parent
                        spacing: 4

                        Text {
                            text: "🗑"
                            font.pixelSize: 10
                            color: clearMouse.containsMouse ? "#FFFFFF" : Theme.accentRose
                        }
                        Text {
                            text: "Clear All"
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                            color: clearMouse.containsMouse ? "#FFFFFF" : Theme.textMuted
                        }
                    }

                    MouseArea {
                        id: clearMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: ClipboardService.clearAll()
                    }
                }
            }
        }
    }
}
