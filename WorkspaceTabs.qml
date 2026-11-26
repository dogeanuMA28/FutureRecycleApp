import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// Shared nested navigation: related screens stay inside one sidebar workspace.
Item {
    id: root
    property var tabs: []
    property int currentIndex: 0
    signal selected(int tabIndex)
    implicitHeight: 47
    Layout.fillWidth: true
    Layout.preferredHeight: 47

    RowLayout {
        anchors.fill: parent
        spacing: 8
        Repeater {
            model: root.tabs
            delegate: Button {
                id: tabButton
                required property string modelData
                required property int index
                text: modelData
                implicitHeight: 39
                implicitWidth: Math.max(110, tabLabel.implicitWidth + 32)
                hoverEnabled: true
                onClicked: root.selected(index)
                background: Rectangle {
                    radius: 10
                    color: tabButton.index === root.currentIndex ? "#163F33"
                         : tabButton.hovered ? "#243542" : "#17222D"
                    border.color: tabButton.index === root.currentIndex ? "#10B981" : "#2B3B4B"
                }
                contentItem: Text {
                    id: tabLabel
                    text: tabButton.text
                    font.pixelSize: 12
                    font.bold: tabButton.index === root.currentIndex
                    color: tabButton.index === root.currentIndex ? "#6EE7B7" : "#B2C2D2"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }
        Item { Layout.fillWidth: true }
    }
}
