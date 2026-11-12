import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import "../theme"
import "../services"
import "../components"

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
        width: 820
        height: 560
        anchors.centerIn: parent
        radius: Theme.cardRadius
        color: ShellState.glassEnabled ? "transparent" : Theme.bgModal
        border.color: ShellState.glassEnabled ? "transparent" : Theme.borderGlow
        border.width: ShellState.glassEnabled ? 0 : 1

        LiquidGlassSurface {
            radius: Theme.cardRadius
            visible: ShellState.glassEnabled
            accentColor: Theme.accentViolet
            showShadow: true
        }

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
                color: ShellState.plasticEnabled ? "transparent" : Theme.bgBase
                border.color: ShellState.plasticEnabled ? "transparent" : (searchInput.activeFocus ? Theme.accentCyan : Theme.borderDim)
                border.width: ShellState.plasticEnabled ? 0 : 1

                LiquidGlassSurface {
                    radius: 10
                    visible: ShellState.plasticEnabled
                    accentColor: searchInput.activeFocus ? Theme.accentCyan : Theme.borderDim
                    showShadow: false
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14
                    spacing: 10

                    Icon {
                        name: "copy"
                        size: 14
                        color: Theme.accentCyan
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
                            text: "Search clipboard history (text, code, images, links)..."
                            font.family: Theme.fontFamily
                            font.pixelSize: 13
                            color: Theme.textMuted
                            visible: !searchInput.text && !searchInput.activeFocus
                        }

                        onTextChanged: {
                            ClipboardService.search(searchInput.text);
                            clipList.currentIndex = 0;
                            if (ClipboardService.items.length > 0) {
                                ClipboardService.selectItem(ClipboardService.items[0]);
                            }
                        }

                        Keys.onEscapePressed: {
                            ShellState.clipboardOpen = false;
                        }

                        Keys.onDownPressed: {
                            clipList.incrementCurrentIndex();
                            if (clipList.currentIndex >= 0 && clipList.currentIndex < ClipboardService.items.length) {
                                ClipboardService.selectItem(ClipboardService.items[clipList.currentIndex]);
                            }
                        }

                        Keys.onUpPressed: {
                            clipList.decrementCurrentIndex();
                            if (clipList.currentIndex >= 0 && clipList.currentIndex < ClipboardService.items.length) {
                                ClipboardService.selectItem(ClipboardService.items[clipList.currentIndex]);
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
                        height: 22
                        implicitWidth: countText.implicitWidth + 12
                        radius: 11
                        color: Theme.bgPill
                        Text {
                            id: countText
                            anchors.centerIn: parent
                            text: ClipboardService.items.length + " clips"
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
                    Layout.preferredWidth: 390
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
                            height: 52
                            radius: 8
                            readonly property bool isCurrent: clipList.currentIndex === index || ClipboardService.selectedId === modelData.id
                            color: ShellState.plasticEnabled
                                ? "transparent"
                                : (isCurrent ? Theme.bgActive : (itemMouse.containsMouse ? Theme.bgHover : "transparent"))

                            LiquidGlassSurface {
                                radius: 8
                                visible: ShellState.plasticEnabled && (itemDelegate.isCurrent || itemMouse.containsMouse)
                                accentColor: itemDelegate.isCurrent ? Theme.accentViolet : Theme.accentCyan
                                hovered: itemMouse.containsMouse
                                pressed: itemMouse.pressed
                                showShadow: false
                            }

                            Behavior on color { ColorAnimation { duration: 100 } }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                anchors.rightMargin: 8
                                spacing: 9

                                // Thumbnail / Icon Container
                                Rectangle {
                                    width: 34
                                    height: 34
                                    radius: 6
                                    color: Theme.bgPill
                                    border.color: Theme.borderDim
                                    border.width: 1
                                    clip: true

                                    // Real thumbnail image if type === "image"
                                    Image {
                                        anchors.fill: parent
                                        source: modelData.type === "image" && modelData.thumb ? ("file://" + modelData.thumb) : ""
                                        fillMode: Image.PreserveAspectCrop
                                        visible: modelData.type === "image" && modelData.thumb && modelData.thumb.length > 0
                                        asynchronous: true
                                        cache: true
                                    }

                                    // Icon vector fallback for text/code/urls
                                    Icon {
                                        anchors.centerIn: parent
                                        name: modelData.type === "url" ? "link" : (modelData.type === "code" ? "code" : (modelData.type === "image" ? "image" : "file-text"))
                                        size: 13
                                        color: modelData.pinned ? Theme.accentAmber : Theme.textSecondary
                                        visible: modelData.type !== "image" || !modelData.thumb
                                    }
                                }

                                // Snippet & Meta
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2

                                    Text {
                                        Layout.fillWidth: true
                                        text: modelData.type === "image" ? "Image (" + (modelData.meta || "PNG") + ")" : modelData.text
                                        font.family: modelData.type === "code" ? Theme.fontMono : Theme.fontFamily
                                        font.pixelSize: 11
                                        font.bold: modelData.type === "image"
                                        color: itemDelegate.isCurrent ? Theme.accentSky : Theme.textPrimary
                                        elide: Text.ElideRight
                                        maximumLineCount: 1
                                    }

                                    Text {
                                        text: "#" + modelData.id + " • " + (modelData.meta || modelData.type.toUpperCase())
                                        font.family: Theme.fontMono
                                        font.pixelSize: 9
                                        color: itemDelegate.isCurrent ? Theme.accentCyan : Theme.textMuted
                                    }
                                }

                                // Delete Button on hover
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
                                    ClipboardService.selectItem(modelData);
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

                // Right Column: Live Decoded Preview (Image or Text)
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
                        anchors.margins: 14
                        spacing: 8

                        // Preview Header
                        RowLayout {
                            Layout.fillWidth: true

                            Text {
                                text: ClipboardService.isImage ? "🖼 IMAGE PREVIEW" : "📄 TEXT PREVIEW"
                                font.family: Theme.fontMono
                                font.pixelSize: 10
                                font.bold: true
                                color: Theme.accentCyan
                            }

                            Text {
                                text: ClipboardService.selectedItem ? (" • #" + ClipboardService.selectedItem.id + " • " + (ClipboardService.selectedItem.meta || "")) : ""
                                font.family: Theme.fontMono
                                font.pixelSize: 9
                                color: Theme.textMuted
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            // Quick Copy Button
                            Rectangle {
                                height: 26
                                implicitWidth: copyRow.implicitWidth + 14
                                radius: 6
                                color: copyMouse.containsMouse ? Theme.accentViolet : Theme.bgPill
                                border.color: Theme.borderDim
                                border.width: 1

                                RowLayout {
                                    id: copyRow
                                    anchors.centerIn: parent
                                    spacing: 5

                                    Text {
                                        text: "⎘"
                                        font.pixelSize: 12
                                        color: copyMouse.containsMouse ? Theme.textOnAccent : Theme.accentViolet
                                    }
                                    Text {
                                        text: ClipboardService.isImage ? "Paste Image" : "Paste"
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 11
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

                        // Divider
                        Rectangle {
                            Layout.fillWidth: true
                            height: 1
                            color: Theme.borderDim
                        }

                        // --- IMAGE PREVIEW VIEWPORT ---
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: 8
                            color: Theme.bgSurface
                            border.color: Theme.borderDim
                            border.width: 1
                            clip: true
                            visible: ClipboardService.isImage

                            Image {
                                id: fullImagePreview
                                anchors.fill: parent
                                anchors.margins: 10
                                source: ClipboardService.isImage ? ClipboardService.previewImagePath : ""
                                fillMode: Image.PreserveAspectFit
                                asynchronous: true
                                cache: false
                            }

                            // Image dimensions badge
                            Rectangle {
                                anchors.bottom: parent.bottom
                                anchors.right: parent.right
                                anchors.margins: 10
                                height: 22
                                implicitWidth: imgDimText.implicitWidth + 12
                                radius: 6
                                color: Qt.rgba(0, 0, 0, 0.75)
                                border.color: Theme.borderDim
                                border.width: 1
                                visible: ClipboardService.selectedItem && ClipboardService.selectedItem.meta

                                Text {
                                    id: imgDimText
                                    anchors.centerIn: parent
                                    text: ClipboardService.selectedItem ? ClipboardService.selectedItem.meta : ""
                                    font.family: Theme.fontMono
                                    font.pixelSize: 9
                                    color: Theme.accentSky
                                }
                            }
                        }

                        // --- TEXT PREVIEW VIEWPORT ---
                        ScrollView {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true
                            visible: !ClipboardService.isImage

                            TextArea {
                                id: previewText
                                text: ClipboardService.previewText || "Select an item to view preview"
                                font.family: Theme.fontMono
                                font.pixelSize: 11
                                color: ClipboardService.previewText ? Theme.textPrimary : Theme.textMuted
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

                        Icon {
                            name: "trash-2"
                            size: 11
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
