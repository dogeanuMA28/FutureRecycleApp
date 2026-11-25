import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    property var stateData: ({})
    property string statusFilter: "Active"
    property string stationFilter: "all"
    readonly property var stations: stateData.stations || []
    readonly property var tickets: stateData.tickets || []
    readonly property var openTickets: tickets.filter(function(t){return t.status !== "Resolved"})
    readonly property var filtered: tickets.filter(function(t) {
        return (root.statusFilter === "All" || (root.statusFilter === "Active" ? t.status !== "Resolved" : t.status === root.statusFilter)) &&
               (root.stationFilter === "all" || root.stationFilter === t.stationId)
    })
    function stationName(sid) {
        for (var i=0; i<stations.length; ++i) if (stations[i].id === sid) return stations[i].name
        return "Archived station"
    }
    function openTicket(stationId) {
        if (stationId) backend.selectStation(stationId)
        createPopup.open()
    }

    Flickable {
        anchors.fill: parent; clip: true
        contentHeight: body.implicitHeight + 28
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
        ColumnLayout {
            id: body; width: parent.width - 16; spacing: 18
            RowLayout {
                Layout.fillWidth: true
                Column {
                    spacing: 5
                    Text { text: "Maintenance & Support"; color: "#F8FAFC"; font.pixelSize: 24; font.bold: true }
                    Text { text: "Report equipment issues and track the fictional service lifecycle"; color: "#91A5BA"; font.pixelSize: 12 }
                }
                Item { Layout.fillWidth: true }
                ActionButton { text: "+ Create Ticket"; implicitWidth: 157; onClicked: root.openTicket(root.stateData.selectedStationId) }
            }
            GridLayout {
                Layout.fillWidth: true; columns: 3; columnSpacing: 12
                MetricCard { label: "OPEN TICKETS"; amount: root.openTickets.length.toString(); note: "Requires work"; accent: "#FBBF24" }
                MetricCard { label: "HIGH PRIORITY"; amount: root.openTickets.filter(function(x){return x.priority === "High"}).length.toString(); note: "Urgent service requests"; accent: "#FB7185" }
                MetricCard { label: "RESOLVED"; amount: root.tickets.filter(function(x){return x.status === "Resolved"}).length.toString(); note: "Closed issues"; accent: "#34D399" }
            }
            Rectangle {
                Layout.fillWidth: true; Layout.preferredHeight: 70; radius: 12; color: "#161F29"; border.color: "#293644"
                RowLayout {
                    anchors.fill: parent; anchors.margins: 14; spacing: 12
                    Text { text: "Service queue"; color: "#A2B4C8"; font.pixelSize: 12 }
                    Item { Layout.fillWidth: true }
                    DarkCombo {
                        implicitWidth: 195
                        model: ["All stations"].concat(root.stations.map(function(s){return s.id + " · " + s.name}))
                        onActivated: function(i){root.stationFilter = i===0 ? "all" : root.stations[i-1].id}
                    }
                    DarkCombo {
                        id: maintenanceFilterCombo
                        implicitWidth: 150
                        model: ["Active", "Open", "In Progress", "Resolved", "All"]
                        onActivated: function(i){root.statusFilter = model[i]}
                    }
                }
            }
            Repeater {
                model: root.filtered
                delegate: Rectangle {
                    id: ticketCard
                    required property var modelData
                    Layout.fillWidth: true; Layout.preferredHeight: 153
                    radius: 14; color: "#161F29"; border.color: "#293644"
                    ColumnLayout {
                        anchors.fill: parent; anchors.margins: 18; spacing: 10
                        RowLayout {
                            Layout.fillWidth: true; spacing: 12
                            Text { text: ticketCard.modelData.title; color: "#F1F5F9"; font.bold: true; font.pixelSize: 15; Layout.fillWidth: true; elide: Text.ElideRight }
                            Text { text: ticketCard.modelData.priority.toUpperCase(); color: ticketCard.modelData.priority === "High" ? "#FB7185" : "#FBBF24"; font.pixelSize: 10; font.bold: true }
                            Rectangle {
                                width: ticketStatusText.implicitWidth + 22; height: 26; radius: 13
                                color: ticketCard.modelData.status === "Resolved" ? "#173B30" : "#453A27"
                                Text { id: ticketStatusText; text: ticketCard.modelData.status; anchors.centerIn: parent; color: ticketCard.modelData.status === "Resolved" ? "#6EE7B7" : "#FCD34D"; font.pixelSize: 11; font.bold: true }
                            }
                        }
                        Text { text: ticketCard.modelData.id + "  ·  " + ticketCard.modelData.stationId + " / " + root.stationName(ticketCard.modelData.stationId) + "  ·  " + ticketCard.modelData.category; color: "#9FB1C5"; font.pixelSize: 11; Layout.fillWidth: true; elide: Text.ElideRight }
                        Text { text: ticketCard.modelData.description || "No additional details"; color: "#7D91A6"; font.pixelSize: 11; Layout.fillWidth: true; elide: Text.ElideRight }
                        RowLayout {
                            Layout.fillWidth: true; spacing: 9
                            Text { text: new Date(ticketCard.modelData.updatedAt).toLocaleDateString(); color: "#71869C"; font.pixelSize: 11; Layout.fillWidth: true }
                            ActionButton { visible: ticketCard.modelData.status === "Open"; text: "Start Work"; tone: "neutral"; implicitWidth: 105; onClicked: backend.setTicketStatus(ticketCard.modelData.id, "In Progress") }
                            ActionButton { visible: ticketCard.modelData.status === "Open" || ticketCard.modelData.status === "In Progress"; text: "Resolve Ticket"; implicitWidth: 130; onClicked: backend.setTicketStatus(ticketCard.modelData.id, "Resolved") }
                            ActionButton { visible: ticketCard.modelData.status === "Resolved"; text: "Reopen"; tone: "neutral"; implicitWidth: 90; onClicked: backend.setTicketStatus(ticketCard.modelData.id, "Open") }
                        }
                    }
                }
            }
            Text { visible: root.filtered.length === 0; text: "No service tickets match these filters."; color: "#94A3B8"; font.pixelSize: 13 }
            Text { text: "DEMO WORKFLOW · NO SERVICE TEAM IS CONTACTED"; color: "#60768B"; font.pixelSize: 10; font.bold: true; Layout.alignment: Qt.AlignHCenter }
        }
    }
    Popup {
        id: createPopup
        anchors.centerIn: parent; width: 485; height: 506
        modal: true; focus: true; closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        background: Rectangle { color: "#1C2936"; border.color: "#43576C"; radius: 16 }
        contentItem: ColumnLayout {
            spacing: 11
            Text { text: "Create Support Ticket"; font.pixelSize: 20; font.bold: true; color: "#F8FAFC" }
            Text { text: "Create a simulated equipment maintenance request."; color: "#92A6BB"; font.pixelSize: 12 }
            Text { text: "STATION"; color: "#9AADC0"; font.pixelSize: 10; font.bold: true }
            DarkCombo {
                id: ticketStationCombo; Layout.fillWidth: true
                model: root.stations.map(function(s){return s.id + " · " + s.name})
                currentIndex: {
                    for (var i=0; i<root.stations.length; ++i) if (root.stations[i].id === root.stateData.selectedStationId) return i
                    return 0
                }
            }
            TextField {
                id: ticketTitle; Layout.fillWidth: true; implicitHeight: 42; maximumLength: 80
                placeholderText: "Issue title (required)"; placeholderTextColor: "#879AAD"; color: "#F8FAFC"
                background: Rectangle { radius: 9; color: "#263746"; border.color: "#41576B" }
            }
            RowLayout {
                Layout.fillWidth: true; spacing: 10
                DarkCombo { id: ticketCategory; Layout.fillWidth: true; model: ["Hardware", "Sensor", "Connectivity", "Other"] }
                DarkCombo { id: ticketPriority; Layout.fillWidth: true; model: ["Low", "Medium", "High"]; currentIndex: 1 }
            }
            TextArea {
                id: ticketDescription
                Layout.fillWidth: true; Layout.preferredHeight: 100
                placeholderText: "Describe the issue..."; placeholderTextColor: "#879AAD"; color: "#F8FAFC"; wrapMode: TextArea.Wrap
                background: Rectangle { radius: 9; color: "#263746"; border.color: "#41576B" }
            }
            RowLayout {
                Layout.fillWidth: true; spacing: 10
                ActionButton { Layout.fillWidth: true; text: "Cancel"; tone: "neutral"; onClicked: createPopup.close() }
                ActionButton {
                    Layout.fillWidth: true; text: "Create Ticket"; enabled: ticketTitle.text.trim().length > 0 && ticketStationCombo.currentIndex >= 0
                    onClicked: {
                        var sid = root.stations[ticketStationCombo.currentIndex].id
                        var created = backend.createTicket(sid, ticketTitle.text, ticketCategory.currentText, ticketPriority.currentText, ticketDescription.text)
                        if (created) { ticketTitle.text = ""; ticketDescription.text = ""; createPopup.close(); root.statusFilter = "Active"; maintenanceFilterCombo.currentIndex = 0 }
                    }
                }
            }
        }
    }
}
