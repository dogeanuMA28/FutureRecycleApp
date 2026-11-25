import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    property var stateData: ({})
    signal calendarRequested(string jobId)
    property string statusFilter: "Active"
    property string stationFilter: "all"
    property string requestedMaterial: "plastic"
    readonly property var stations: stateData.stations || []
    readonly property var jobs: stateData.collections || []
    readonly property var active: jobs.filter(function(x) { return x.status === "Requested" || x.status === "Scheduled" })
    readonly property var filtered: jobs.filter(function(x) {
        var statusOk = root.statusFilter === "All" || (root.statusFilter === "Active" ? (x.status === "Requested" || x.status === "Scheduled") : x.status === root.statusFilter)
        return statusOk && (root.stationFilter === "all" || x.stationId === root.stationFilter)
    })
    function stationName(sid) {
        for (var i = 0; i < stations.length; ++i) if (stations[i].id === sid) return stations[i].name
        return "Archived station"
    }
    function openRequest(stationId, material) {
        if (stationId) backend.selectStation(stationId)
        root.requestedMaterial = material || "plastic"
        materialCombo.currentIndex = Math.max(0, ["plastic", "paper", "metal"].indexOf(root.requestedMaterial))
        requestPopup.open()
    }
    readonly property string selectedId: stateData.selectedStationId || ""
    readonly property var selectedStation: {
        for (var i = 0; i < stations.length; ++i) if (stations[i].id === selectedId) return stations[i]
        return null
    }

    Flickable {
        anchors.fill: parent; clip: true
        contentHeight: body.implicitHeight + 26
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
        ColumnLayout {
            id: body
            width: parent.width - 16
            spacing: 18
            RowLayout {
                Layout.fillWidth: true
                Column {
                    spacing: 5
                    Text { text: "Collection Management"; font.pixelSize: 24; font.bold: true; color: "#F8FAFC" }
                    Text { text: "Request pickups, schedule service and record completed collections"; font.pixelSize: 12; color: "#91A5BA" }
                }
                Item { Layout.fillWidth: true }
                ActionButton { text: "Pickup Calendar"; tone: "neutral"; implicitWidth: 141; onClicked: root.calendarRequested("") }
                ActionButton { text: "+ Request Collection"; implicitWidth: 176; onClicked: root.openRequest(root.selectedId, "plastic") }
            }
            GridLayout {
                Layout.fillWidth: true; columns: 3; columnSpacing: 12
                MetricCard { label: "ACTIVE REQUESTS"; amount: root.active.length.toString(); note: "Awaiting collection"; accent: "#FBBF24" }
                MetricCard { label: "SCHEDULED"; amount: root.jobs.filter(function(x){return x.status === "Scheduled"}).length.toString(); note: "Simulated scheduling"; accent: "#60A5FA" }
                MetricCard { label: "COMPLETED"; amount: root.jobs.filter(function(x){return x.status === "Completed"}).length.toString(); note: "Containers emptied"; accent: "#34D399" }
            }
            Rectangle {
                Layout.fillWidth: true; Layout.preferredHeight: 70; radius: 12; color: "#161F29"; border.color: "#293644"
                RowLayout {
                    anchors.fill: parent; anchors.margins: 14; spacing: 12
                    Text { text: "Filter collections"; color: "#A2B4C8"; font.pixelSize: 12 }
                    Item { Layout.fillWidth: true }
                    DarkCombo {
                        implicitWidth: 192
                        model: ["All stations"].concat(root.stations.map(function(s) { return s.id + " · " + s.name }))
                        onActivated: function(index) { root.stationFilter = index === 0 ? "all" : root.stations[index - 1].id }
                    }
                    DarkCombo {
                        id: collectionFilterCombo
                        implicitWidth: 146
                        model: ["Active", "Requested", "Scheduled", "Completed", "Cancelled", "All"]
                        onActivated: function(index) { root.statusFilter = model[index] }
                    }
                }
            }
            Text { text: root.filtered.length + " collection records"; color: "#93A7B9"; font.pixelSize: 12 }
            Repeater {
                model: root.filtered
                delegate: Rectangle {
                    id: jobCard
                    required property var modelData
                    Layout.fillWidth: true; Layout.preferredHeight: 145
                    radius: 14; color: "#161F29"; border.color: "#293644"
                    ColumnLayout {
                        anchors.fill: parent; anchors.margins: 18; spacing: 10
                        RowLayout {
                            Layout.fillWidth: true; spacing: 10
                            Rectangle { width: 9; height: 9; radius: 5; color: jobCard.modelData.status === "Completed" ? "#34D399" : jobCard.modelData.status === "Cancelled" ? "#64748B" : "#FBBF24" }
                            Text { text: jobCard.modelData.id + "  ·  " + jobCard.modelData.material.toUpperCase(); color: "#F1F5F9"; font.bold: true; font.pixelSize: 15 }
                            Item { Layout.fillWidth: true }
                            Rectangle {
                                width: badgeText.implicitWidth + 22; height: 26; radius: 13
                                color: jobCard.modelData.status === "Completed" ? "#173B30" : jobCard.modelData.status === "Cancelled" ? "#293543" : "#453A27"
                                Text { id: badgeText; anchors.centerIn: parent; text: jobCard.modelData.status; color: jobCard.modelData.status === "Completed" ? "#6EE7B7" : jobCard.modelData.status === "Cancelled" ? "#94A3B8" : "#FCD34D"; font.pixelSize: 11; font.bold: true }
                            }
                        }
                        RowLayout {
                            Layout.fillWidth: true; spacing: 9
                            Text { text: jobCard.modelData.stationId + " · " + root.stationName(jobCard.modelData.stationId); color: "#9FB1C5"; font.pixelSize: 12 }
                            Item { Layout.fillWidth: true }
                            Text { text: new Date(jobCard.modelData.createdAt).toLocaleDateString(); color: "#71869C"; font.pixelSize: 11 }
                        }
                        RowLayout {
                            Layout.fillWidth: true; spacing: 8
                            Text { text: (jobCard.modelData.scheduledFor ? "Pickup: " + jobCard.modelData.scheduledFor + " · " + jobCard.modelData.scheduledSlot + "   |   " : "") + (jobCard.modelData.note || "No special instructions"); color: "#74889C"; font.pixelSize: 11; Layout.fillWidth: true; elide: Text.ElideRight }
                            ActionButton { visible: jobCard.modelData.status === "Requested"; text: "Choose Date"; implicitWidth: 104; tone: "neutral"; onClicked: root.calendarRequested(jobCard.modelData.id) }
                            ActionButton { visible: jobCard.modelData.status === "Scheduled"; text: "Reschedule"; implicitWidth: 101; tone: "neutral"; onClicked: root.calendarRequested(jobCard.modelData.id) }
                            ActionButton { visible: jobCard.modelData.status === "Scheduled"; text: "Complete Pickup"; implicitWidth: 135; onClicked: { confirmComplete.jobId = jobCard.modelData.id; confirmComplete.open() } }
                            ActionButton { visible: jobCard.modelData.status === "Requested" || jobCard.modelData.status === "Scheduled"; text: "Cancel"; tone: "danger"; implicitWidth: 83; onClicked: backend.setCollectionStatus(jobCard.modelData.id, "Cancelled") }
                        }
                    }
                }
            }
            Text { visible: root.filtered.length === 0; text: "No collections match these filters."; color: "#94A3B8"; font.pixelSize: 13 }
            Text { text: "DATES ARE MANAGED IN PICKUP CALENDAR · NO REAL PICKUP IS BOOKED"; color: "#60768B"; font.pixelSize: 10; font.bold: true; Layout.alignment: Qt.AlignHCenter }
        }
    }

    Popup {
        id: requestPopup
        anchors.centerIn: parent; width: 475; height: 368
        modal: true; focus: true; closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        background: Rectangle { color: "#1C2936"; radius: 16; border.color: "#43576C" }
        contentItem: ColumnLayout {
            spacing: 12
            Text { text: "Request a Collection"; color: "#F8FAFC"; font.pixelSize: 20; font.bold: true }
            Text { text: "Create a simulated pickup for a station container."; color: "#92A6BB"; font.pixelSize: 12 }
            Text { text: "STATION"; color: "#A3B5C9"; font.pixelSize: 10; font.bold: true }
            DarkCombo {
                id: requestStationCombo
                Layout.fillWidth: true
                model: root.stations.map(function(s) { return s.id + " · " + s.name })
                currentIndex: {
                    for (var i = 0; i < root.stations.length; i++) if (root.stations[i].id === root.selectedId) return i
                    return 0
                }
            }
            Text { text: "MATERIAL"; color: "#A3B5C9"; font.pixelSize: 10; font.bold: true }
            DarkCombo { id: materialCombo; Layout.fillWidth: true; model: ["plastic", "paper", "metal"]; currentIndex: 0 }
            TextField {
                id: collectionNote
                Layout.fillWidth: true; implicitHeight: 42; maximumLength: 200
                placeholderText: "Optional pickup instructions"; placeholderTextColor: "#8296AA"; color: "#F8FAFC"
                background: Rectangle { radius: 9; color: "#263746"; border.color: "#41576B" }
            }
            RowLayout {
                Layout.fillWidth: true; spacing: 10
                ActionButton { Layout.fillWidth: true; text: "Cancel"; tone: "neutral"; onClicked: requestPopup.close() }
                ActionButton {
                    Layout.fillWidth: true; text: "Create Request"; enabled: requestStationCombo.currentIndex >= 0
                    onClicked: {
                        if (requestStationCombo.currentIndex < 0) return
                        var sid = root.stations[requestStationCombo.currentIndex].id
                        var jobId = backend.requestCollection(sid, materialCombo.currentText, collectionNote.text)
                        if (jobId) { requestPopup.close(); collectionNote.text = ""; root.statusFilter = "Active"; collectionFilterCombo.currentIndex = 0 }
                    }
                }
            }
        }
    }
    Dialog {
        id: confirmComplete
        property string jobId: ""
        anchors.centerIn: parent; title: "Complete simulated pickup?"; modal: true
        standardButtons: Dialog.Yes | Dialog.No
        onAccepted: backend.setCollectionStatus(jobId, "Completed")
        contentItem: Text { width: 350; text: "This records a completed collection and sets that container fill level to 0%."; color: "#E2EBF4"; wrapMode: Text.WordWrap }
        background: Rectangle { color: "#1C2936"; radius: 14; border.color: "#43576C" }
    }
}
