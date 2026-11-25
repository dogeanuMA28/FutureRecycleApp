import QtQuick
import QtQuick.Controls

ComboBox {
    id: root
    implicitWidth: 175
    implicitHeight: 40
    font.pixelSize: 12
    background: Rectangle {
        radius: 9
        color: root.pressed ? "#304657" : "#22313F"
        border.color: root.activeFocus ? "#10B981" : "#42546A"
    }
    contentItem: Text {
        text: root.displayText
        leftPadding: 12
        rightPadding: 26
        color: "#EAF2FA"
        font.pixelSize: 12
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }
}
