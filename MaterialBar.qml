import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: root
    property string label: "Plastic"
    property real percent: 0
    property color accent: "#10B981"
    property string prefix: ""
    spacing: 8
    RowLayout {
        Layout.fillWidth: true
        spacing: 8
        Rectangle { width: 9; height: 9; radius: 3; color: root.accent }
        Text { text: root.prefix + root.label; color: "#CBD5E1"; font.pixelSize: 12 }
        Item { Layout.fillWidth: true }
        Text { text: root.percent.toFixed(1) + "%"; color: root.percent >= 80 ? "#FBBF24" : "#F8FAFC"; font.pixelSize: 12; font.bold: true }
    }
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 8
        radius: 4
        color: "#2A3745"
        Rectangle {
            height: parent.height
            width: parent.width * Math.max(0, Math.min(100, root.percent)) / 100
            radius: 4
            color: root.percent >= 80 ? "#F59E0B" : root.accent
            Behavior on width { NumberAnimation { duration: 540; easing.type: Easing.OutCubic } }
        }
    }
}
