import QtQuick
import QtQuick.Controls

Button {
    id: root
    property string tone: "primary"    // primary, neutral, warning, danger
    implicitHeight: 40
    implicitWidth: Math.max(106, label.implicitWidth + 28)
    hoverEnabled: true
    background: Rectangle {
        radius: 9
        color: !root.enabled ? "#34414A" : root.tone === "danger" ? (root.hovered ? "#6B3645" : "#462B35")
             : root.tone === "warning" ? (root.hovered ? "#755A2A" : "#514327")
             : root.tone === "neutral" ? (root.hovered ? "#33495B" : "#233443")
             : (root.hovered ? "#34D399" : "#10B981")
        border.color: root.tone === "danger" ? "#995166" : root.tone === "warning" ? "#A78643" : root.tone === "neutral" ? "#40566B" : "#259A70"
    }
    contentItem: Text {
        id: label
        text: root.text
        color: !root.enabled ? "#9CAAB8" : root.tone === "primary" ? "#062319" : root.tone === "danger" ? "#FDA4AF" : root.tone === "warning" ? "#FFE4A7" : "#E9F1FA"
        font.pixelSize: 12
        font.bold: true
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }
}
