import QtQuick
import Qt5Compat.GraphicalEffects

Item {
    id: root

    property string name: ""
    property color color: "#FFFFFF"
    property real size: 16

    width: size
    height: size
    implicitWidth: size
    implicitHeight: size

    Image {
        id: baseImg
        anchors.fill: parent
        source: {
            if (!root.name) return "";
            if (root.name.startsWith("/") || root.name.startsWith("file://") || root.name.startsWith("qrc:/")) {
                return root.name;
            }
            return Qt.resolvedUrl("../assets/icons/" + root.name + (root.name.endsWith(".svg") ? "" : ".svg"));
        }
        sourceSize.width: Math.max(24, Math.round(root.size * 2))
        sourceSize.height: Math.max(24, Math.round(root.size * 2))
        fillMode: Image.PreserveAspectFit
        smooth: true
        mipmap: true
        visible: false
    }

    ColorOverlay {
        anchors.fill: baseImg
        source: baseImg
        color: root.color
        visible: root.name.length > 0 && baseImg.status === Image.Ready
    }
}
