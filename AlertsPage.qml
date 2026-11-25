import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    property var stateData: ({})
    signal collectionRequested(string stationId, string material)
    signal stationRequested(string stationId)
    signal maintenanceRequested()
    readonly property var alerts: stateData.alerts || []
    readonly property int unacknowledged: alerts.filter(function(a){return !a.acknowledged}).length

    Flickable {
        anchors.fill: parent; clip: true
        contentHeight: body.implicitHeight + 28
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
        ColumnLayout {
            id: body
            width: parent.width - 16
            spacing: 18
            RowLayout {
                Layout.fillWidth: true
                Column {
                    spacing: 5
                    Text { text: "Alerts & Notifications"; font.pixelSize: 24; font.bold: true; color: "#F8FAFC" }
                    Text { text: "Actionable issues derived from your station network"; font.pixelSize: 12; color: "#91A5BA" }
                }
                Item { Layout.fillWidth: true }
                Rectangle {
                    width: 148; height: 34; radius: 17; color: root.unacknowledged > 0 ? "#453A26" : "#173B30"
                    Text { anchors.centerIn: parent; text: root.unacknowledged + " NEED ATTENTION"; color: root.unacknowledged ? "#FCD34D" : "#6EE7B7"; font.pixelSize: 10; font.bold: true }
                }
            }
            GridLayout {
                Layout.fillWidth: true; columns: 3; columnSpacing: 12
                MetricCard { label: "ACTIVE ALERTS"; amount: root.alerts.length.toString(); note: "Open conditions"; accent: "#FBBF24" }
                MetricCard { label: "UNACKNOWLEDGED"; amount: root.unacknowledged.toString(); note: "Still needing review"; accent: "#FB7185" }
                MetricCard { label: "ACKNOWLEDGED"; amount: (root.alerts.length - root.unacknowledged).toString(); note: "Remain until resolved"; accent: "#34D399" }
            }
            Rectangle {
                Layout.fillWidth: true; Layout.preferredHeight: 70
                radius: 12; color: "#1B2A34"; border.color: "#304555"
                RowLayout {
                    anchors.fill: parent; anchors.margins: 17; spacing: 14
                    Text { text: "!"; font.pixelSize: 27; font.bold: true; color: "#FBBF24" }
                    Text {
                        Layout.fillWidth: true; wrapMode: Text.WordWrap; font.pixelSize: 12; color: "#C3D0DE"
                        text: "Alerts are generated automatically. Acknowledging an alert marks it as seen; completing a pickup, resolving a ticket, or restoring a station clears the underlying warning."
                    }
                }
            }
            Repeater {
                model: root.alerts
                delegate: Rectangle {
                    id: alertCard
                    required property var modelData
                    Layout.fillWidth: true; Layout.preferredHeight: 134
                    radius: 14; color: modelData.acknowledged ? "#151F29" : "#1C2730"
                    border.color: modelData.acknowledged ? "#304050" : modelData.severity === "High" ? "#6E5141" : "#62563A"
                    ColumnLayout {
                        anchors.fill: parent; anchors.margins: 17; spacing: 8
                        RowLayout {
                            Layout.fillWidth: true; spacing: 9
                            Text { text: alertCard.modelData.severity === "High" ? "●" : "!"; color: alertCard.modelData.severity === "High" ? "#FB7185" : "#FBBF24"; font.pixelSize: 18; font.bold: true }
                            Text { text: alertCard.modelData.title; color: "#F1F5F9"; font.pixelSize: 15; font.bold: true; Layout.fillWidth: true; elide: Text.ElideRight }
                            Text { text: alertCard.modelData.acknowledged ? "ACKNOWLEDGED" : alertCard.modelData.severity.toUpperCase(); color: alertCard.modelData.acknowledged ? "#94A3B8" : "#FBBF24"; font.pixelSize: 10; font.bold: true }
                        }
                        Text { text: alertCard.modelData.stationId + " · " + alertCard.modelData.stationName + "  /  " + alertCard.modelData.detail; color: "#9BAFC2"; font.pixelSize: 12; Layout.fillWidth: true; elide: Text.ElideRight }
                        RowLayout {
                            Layout.fillWidth: true; spacing: 9
                            Text { text: alertCard.modelData.type === "fill" ? "CAPACITY ALERT" : alertCard.modelData.type === "ticket" ? "SERVICE ISSUE" : "STATION STATUS"; color: "#71869B"; font.pixelSize: 10; font.bold: true; Layout.fillWidth: true }
                            ActionButton {
                                visible: !alertCard.modelData.acknowledged
                                text: "Acknowledge"; tone: "neutral"; implicitWidth: 116
                                onClicked: backend.acknowledgeAlert(alertCard.modelData.id)
                            }
                            ActionButton {
                                text: alertCard.modelData.type === "fill" ? "Request Pickup" : alertCard.modelData.type === "ticket" ? "View Tickets" : "View Station"
                                implicitWidth: 143
                                onClicked: {
                                    if (alertCard.modelData.type === "fill") root.collectionRequested(alertCard.modelData.stationId, alertCard.modelData.material)
                                    else if (alertCard.modelData.type === "ticket") root.maintenanceRequested()
                                    else root.stationRequested(alertCard.modelData.stationId)
                                }
                            }
                        }
                    }
                }
            }
            Rectangle {
                visible: root.alerts.length === 0
                Layout.fillWidth: true; Layout.preferredHeight: 175
                color: "#173B30"; border.color: "#276148"; radius: 15
                Column {
                    anchors.centerIn: parent; spacing: 12
                    Text { text: "✓"; color: "#6EE7B7"; font.pixelSize: 36; anchors.horizontalCenter: parent.horizontalCenter }
                    Text { text: "All clear — no active alerts"; color: "#E8FFF4"; font.pixelSize: 17; font.bold: true; anchors.horizontalCenter: parent.horizontalCenter }
                    Text { text: "Your network is operating within the demo thresholds."; color: "#9BD8B8"; font.pixelSize: 12; anchors.horizontalCenter: parent.horizontalCenter }
                }
            }
            Text { text: "SIMULATED SYSTEM ALERTS · NO PUSH MESSAGES OR SMS ARE SENT"; Layout.alignment: Qt.AlignHCenter; color: "#60768B"; font.pixelSize: 10; font.bold: true }
        }
    }
}
