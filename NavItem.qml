import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root
    property string label: ""
    property string iconName: ""
    property bool active: false
    property int alertCount: 0
    signal activated()

    Layout.fillWidth: true
    implicitHeight: 38
    radius: 10
    color: active ? "#173B30" : hover.hovered ? "#1B2834" : "transparent"
    Behavior on color { ColorAnimation { duration: 155 } }

    Rectangle {
        width: 3; height: 24; radius: 2
        color: "#34D399"
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        visible: root.active
    }
    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 15
        anchors.rightMargin: 12
        spacing: 11
        Image {
            Layout.preferredWidth: 19
            Layout.preferredHeight: 19
            source: Qt.resolvedUrl("assets/" + root.iconName + (root.active ? "-active" : "") + ".svg")
            sourceSize.width: 24
            sourceSize.height: 24
            fillMode: Image.PreserveAspectFit
        }
        Text {
            Layout.fillWidth: true
            text: root.label
            font.pixelSize: 13
            font.bold: root.active
            color: root.active ? "#6EE7B7" : "#A7B4C4"
            Behavior on color { ColorAnimation { duration: 155 } }
        }
        Rectangle {
            visible: root.alertCount > 0
            width: 24; height: 21; radius: 10
            color: "#5B3F26"
            Text { anchors.centerIn: parent; text: root.alertCount > 9 ? "9+" : root.alertCount; color: "#FCD34D"; font.pixelSize: 10; font.bold: true }
        }
    }
    HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
    TapHandler { onTapped: root.activated() }
}
