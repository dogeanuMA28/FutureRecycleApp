import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root
    property string label: ""
    property string amount: "0"
    property string note: ""
    property color accent: "#10B981"

    Layout.fillWidth: true
    Layout.preferredHeight: 133
    radius: 13
    color: "#161F29"
    border.color: "#293644"
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 9
        Rectangle { width: 33; height: 4; radius: 2; color: root.accent }
        Text { text: root.label; color: "#9AAAC0"; font.pixelSize: 10; font.bold: true; font.letterSpacing: 0.8 }
        Text { text: root.amount; color: "#F8FAFC"; font.pixelSize: 28; font.bold: true }
        Text { text: root.note; color: "#73849A"; font.pixelSize: 10; elide: Text.ElideRight; Layout.fillWidth: true }
    }
}
