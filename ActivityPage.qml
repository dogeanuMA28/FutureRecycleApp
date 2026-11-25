import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    property var stateData: ({})
    property string stationFilter: "all"
    property string typeFilter: "All"
    readonly property var stations: stateData.stations || []
    readonly property var events: stateData.activity || []
    readonly property var filtered: events.filter(function(e) {
        return (root.stationFilter === "all" || e.stationId === root.stationFilter) &&
               (root.typeFilter === "All" || e.type === root.typeFilter)
    })
    function stationName(id) {
        for (var i=0; i<stations.length; ++i) if (stations[i].id === id) return stations[i].name
        return id ? "Archived station" : "System"
    }
    function colorFor(type) {
        return type === "Scan" ? "#34D399" : type === "Collection" ? "#60A5FA" : type === "Maintenance" ? "#FBBF24" : type === "Station" ? "#A78BFA" : "#93A5B8"
    }

    Flickable {
        anchors.fill: parent; clip: true
        contentHeight: body.implicitHeight + 30
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
        ColumnLayout {
            id: body; width: parent.width - 16; spacing: 18
            RowLayout {
                Layout.fillWidth: true
                Column {
                    spacing: 5
                    Text { text: "Activity History"; font.pixelSize: 24; font.bold: true; color: "#F8FAFC" }
                    Text { text: "An audit-style timeline of scans, collections and service actions"; color: "#91A5BA"; font.pixelSize: 12 }
                }
                Item { Layout.fillWidth: true }
                Rectangle {
                    width: 115; height: 32; radius: 16; color: "#173B30"
                    Text { anchors.centerIn: parent; text: root.events.length + " EVENTS"; font.pixelSize: 11; font.bold: true; color: "#6EE7B7" }
                }
            }
            Rectangle {
                Layout.fillWidth: true; Layout.preferredHeight: 72
                radius: 13; color: "#161F29"; border.color: "#293644"
                RowLayout {
                    anchors.fill: parent; anchors.margins: 15; spacing: 12
                    Text { text: "Filter timeline"; color: "#9FB1C5"; font.pixelSize: 12 }
                    Item { Layout.fillWidth: true }
                    DarkCombo {
                        implicitWidth: 245
                        model: ["All stations"].concat(root.stations.map(function(s){return s.id + " · " + s.name}))
                        onActivated: function(index) { root.stationFilter = index === 0 ? "all" : root.stations[index - 1].id }
                    }
                    DarkCombo {
                        implicitWidth: 145
                        model: ["All", "Scan", "Collection", "Maintenance", "Station", "System"]
                        onActivated: function(index){root.typeFilter = model[index]}
                    }
                }
            }
            Repeater {
                model: root.filtered
                delegate: Rectangle {
                    id: eventCard
                    required property var modelData
                    Layout.fillWidth: true; Layout.preferredHeight: 82
                    radius: 12; color: "#161F29"; border.color: "#293644"
                    RowLayout {
                        anchors.fill: parent; anchors.margins: 15; spacing: 15
                        Rectangle { width: 36; height: 36; radius: 10; color: "#293846"; Text { anchors.centerIn: parent; text: "●"; color: root.colorFor(eventCard.modelData.type); font.pixelSize: 17 } }
                        ColumnLayout {
                            Layout.fillWidth: true; spacing: 5
                            Text { text: eventCard.modelData.title; color: "#F1F5F9"; font.pixelSize: 13; font.bold: true; Layout.fillWidth: true; elide: Text.ElideRight }
                            Text { text: (eventCard.modelData.stationId ? eventCard.modelData.stationId + " · " + root.stationName(eventCard.modelData.stationId) + "  /  " : "") + eventCard.modelData.details; color: "#899DB0"; font.pixelSize: 11; Layout.fillWidth: true; elide: Text.ElideRight }
                        }
                        ColumnLayout {
                            spacing: 6
                            Text { text: eventCard.modelData.type.toUpperCase(); color: root.colorFor(eventCard.modelData.type); font.pixelSize: 10; font.bold: true; Layout.alignment: Qt.AlignRight }
                            Text { text: new Date(eventCard.modelData.createdAt).toLocaleString(); color: "#74889B"; font.pixelSize: 10; Layout.alignment: Qt.AlignRight }
                        }
                    }
                }
            }
            Text { visible: root.filtered.length === 0; text: "No activity matches these filters."; color: "#94A3B8"; font.pixelSize: 13 }
            Text { text: "MOST RECENT 200 EVENTS · STORED LOCALLY · DEMO DATA"; color: "#60768B"; font.pixelSize: 10; font.bold: true; Layout.alignment: Qt.AlignHCenter }
        }
    }
}
