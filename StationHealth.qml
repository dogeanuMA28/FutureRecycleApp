import QtQuick
import QtQuick.Layouts
import "Health.js" as Health

Rectangle {
    id: root
    property var station: null
    property var tickets: []
    readonly property var health: Health.evaluate(station, tickets)

    Layout.fillWidth: true
    Layout.preferredHeight: 159
    radius: 15
    color: "#161F29"
    border.color: "#293644"

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 19
        spacing: 9
        RowLayout {
            Layout.fillWidth: true
            Column {
                spacing: 4
                Text { text: "Station Health Score"; font.pixelSize: 17; font.bold: true; color: "#F8FAFC" }
                Text { text: "Status · Capacity · Maintenance"; font.pixelSize: 11; color: "#91A3B7" }
            }
            Item { Layout.fillWidth: true }
            Column {
                spacing: 2
                Text {
                    anchors.right: parent.right
                    text: root.station ? root.health.score + "/100" : "—"
                    font.pixelSize: 24
                    font.bold: true
                    color: root.health.color
                }
                Text { anchors.right: parent.right; text: root.health.label; font.pixelSize: 11; font.bold: true; color: root.health.color }
            }
        }
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 9
            radius: 5
            color: "#2A3947"
            clip: true
            Rectangle {
                width: parent.width * root.health.score / 100
                height: parent.height
                radius: 5
                color: root.health.color
                Behavior on width { NumberAnimation { duration: 280 } }
            }
        }
        RowLayout {
            Layout.fillWidth: true
            spacing: 13
            Text { text: "Status −" + root.health.statusPenalty; color: "#A8B7C8"; font.pixelSize: 11 }
            Text { text: "Capacity −" + root.health.capacityPenalty; color: "#A8B7C8"; font.pixelSize: 11 }
            Text { text: "Tickets −" + root.health.ticketPenalty; color: "#A8B7C8"; font.pixelSize: 11 }
            Item { Layout.fillWidth: true }
            Text { text: root.health.openTickets + " open tickets"; color: "#8698AA"; font.pixelSize: 10 }
        }
        Text { text: "SIMULATED SCORE · NOT A HARDWARE MEASUREMENT"; color: "#64748B"; font.pixelSize: 9; font.bold: true }
    }
}
