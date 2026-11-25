import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    property var stateData: ({})
    property string stationFilter: "all"
    readonly property var forecasts: stateData.forecasts || []
    readonly property var stations: stateData.stations || []
    readonly property var filtered: forecasts.filter(function(f){ return root.stationFilter === "all" || f.stationId === root.stationFilter })
    readonly property int urgent: forecasts.filter(function(f){return f.urgency !== "Normal"}).length
    property string editingId: ""
    property string editingMaterial: "plastic"
    property real editingRate: 5.0
    signal collectionRequested(string stationId, string material)

    function color(f) { return f.urgency === "Critical" ? "#FB7185" : f.urgency === "Soon" ? "#FBBF24" : "#34D399" }
    function daysLabel(f) { return f.daysRemaining < 0 ? "N/A" : f.daysRemaining === 0 ? "Full" : f.daysRemaining.toFixed(1) + " days" }
    function openRate(f) {
        editingId = f.stationId
        editingMaterial = f.material
        editingRate = f.dailyRate
        rateDialog.open()
    }
    Flickable {
        anchors.fill: parent; clip: true
        contentHeight: body.implicitHeight + 25
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
        ColumnLayout {
            id: body; width: parent.width - 16; spacing: 18
            RowLayout {
                Layout.fillWidth: true
                Column {
                    spacing: 5
                    Text { text: "Container Fill Forecasts"; color: "#F8FAFC"; font.pixelSize: 24; font.bold: true }
                    Text { text: "Estimate upcoming collections from configurable demo fill rates"; color: "#94A3B8"; font.pixelSize: 12 }
                }
                Item { Layout.fillWidth: true }
                Rectangle {
                    width: 140; height: 32; radius: 16; color: "#3E3424"
                    Text { anchors.centerIn: parent; text: "● RULE-BASED ESTIMATE"; font.pixelSize: 10; font.bold: true; color: "#FCD34D" }
                }
            }
            GridLayout {
                Layout.fillWidth: true; columns: 3; columnSpacing: 13
                MetricCard { label: "MONITORED BINS"; amount: root.forecasts.length.toString(); note: "Across the network"; accent: "#60A5FA" }
                MetricCard { label: "COLLECTIONS SOON"; amount: root.urgent.toString(); note: "Within 3 days or already critical"; accent: "#FBBF24" }
                MetricCard { label: "SIMULATED DAILY RATE"; amount: "0–30%"; note: "Editable per station and material"; accent: "#34D399" }
            }
            Rectangle {
                Layout.fillWidth: true; Layout.preferredHeight: 80; radius: 12; color: "#1C3034"; border.color: "#2D6C55"
                RowLayout {
                    anchors.fill: parent; anchors.margins: 17; spacing: 14
                    Text { text: "i"; font.pixelSize: 26; color: "#6EE7B7"; font.bold: true }
                    Text {
                        Layout.fillWidth: true
                        text: "Forecast = (100% − current fill) ÷ simulated daily fill rate. These values are illustrative assumptions, not sensor readings or trained predictions."
                        color: "#C1E8D8"; font.pixelSize: 12; wrapMode: Text.WordWrap
                    }
                }
            }
            RowLayout {
                Layout.fillWidth: true
                Text { text: "Expected Container Capacity"; font.pixelSize: 18; font.bold: true; color: "#F8FAFC" }
                Item { Layout.fillWidth: true }
                DarkCombo {
                    implicitWidth: 255
                    model: ["All stations"].concat(root.stations.map(function(s){return s.id + " · " + s.name}))
                    onActivated: function(index) {root.stationFilter = index === 0 ? "all" : root.stations[index-1].id}
                }
            }
            Repeater {
                model: root.filtered
                delegate: Rectangle {
                    id: forecastCard
                    required property var modelData
                    Layout.fillWidth: true; Layout.preferredHeight: 111
                    color: "#161F29"; border.color: "#293644"; radius: 13
                    RowLayout {
                        anchors.fill: parent; anchors.margins: 16; spacing: 15
                        Rectangle {
                            width: 52; height: 56; radius: 10; color: "#213643"
                            Column {
                                anchors.centerIn: parent; spacing: 4
                                Text { anchors.horizontalCenter: parent.horizontalCenter; text: "▣"; font.pixelSize: 22; color: root.color(forecastCard.modelData) }
                                Text { anchors.horizontalCenter: parent.horizontalCenter; text: forecastCard.modelData.material.slice(0,3).toUpperCase(); font.pixelSize: 9; color: "#AFC4D3" }
                            }
                        }
                        ColumnLayout {
                            Layout.fillWidth: true; spacing: 9
                            RowLayout {
                                Layout.fillWidth: true
                                Text { text: forecastCard.modelData.stationId + " · " + forecastCard.modelData.stationName; color: "#F8FAFC"; font.pixelSize: 13; font.bold: true; Layout.fillWidth: true; elide: Text.ElideRight }
                                Text { text: forecastCard.modelData.material.toUpperCase() + " · " + forecastCard.modelData.fill + "%"; color: "#93A9BC"; font.pixelSize: 11 }
                            }
                            Rectangle {
                                Layout.fillWidth: true; height: 9; radius: 4; color: "#293946"
                                Rectangle { height: parent.height; width: parent.width * forecastCard.modelData.fill / 100; radius: 4; color: root.color(forecastCard.modelData) }
                            }
                            Text { text: forecastCard.modelData.dailyRate.toFixed(1) + "% / simulated day · projected date " + (forecastCard.modelData.projectedDate || "unavailable"); color: "#8299AF"; font.pixelSize: 10 }
                        }
                        Column {
                            spacing: 5
                            Text { anchors.right: parent.right; text: root.daysLabel(forecastCard.modelData); color: root.color(forecastCard.modelData); font.pixelSize: 16; font.bold: true }
                            Text { anchors.right: parent.right; text: forecastCard.modelData.urgency; color: "#8299AF"; font.pixelSize: 10 }
                        }
                        Column {
                            spacing: 6
                            ActionButton { text: "Adjust Rate"; tone: "neutral"; implicitWidth: 109; implicitHeight: 33; onClicked: root.openRate(forecastCard.modelData) }
                            ActionButton { text: "Request Pickup"; implicitWidth: 109; implicitHeight: 33; enabled: forecastCard.modelData.fill > 0; onClicked: root.collectionRequested(forecastCard.modelData.stationId, forecastCard.modelData.material) }
                        }
                    }
                }
            }
            Text { text: "DEMO FORECAST · NO HISTORICAL MODEL, REAL-WORLD SENSOR OR AUTOMATIC DISPATCH"; font.pixelSize: 10; color: "#657B90"; Layout.alignment: Qt.AlignHCenter }
        }
    }
    Popup {
        id: rateDialog; anchors.centerIn: parent; width: 450; height: 290
        modal: true; focus: true; closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        background: Rectangle { color: "#1C2B37"; radius: 15; border.color: "#456074" }
        contentItem: ColumnLayout {
            spacing: 12
            Text { text: "Configure Daily Fill Rate"; color: "#F8FAFC"; font.bold: true; font.pixelSize: 19 }
            Text { text: root.editingId + " · " + root.editingMaterial.toUpperCase(); color: "#9FB3C6"; font.pixelSize: 12 }
            Text { text: "Simulated rate: " + root.editingRate.toFixed(1) + "% per day"; color: "#6EE7B7"; font.pixelSize: 16; font.bold: true }
            Slider {
                Layout.fillWidth: true; from: 0; to: 30; stepSize: .5
                value: root.editingRate
                onMoved: root.editingRate = value
            }
            Text { text: "Use 0% to represent an unknown growth rate; the forecast becomes N/A."; color: "#95A9BD"; font.pixelSize: 11; wrapMode: Text.WordWrap; Layout.fillWidth: true }
            Item { Layout.fillHeight: true }
            RowLayout {
                Layout.fillWidth: true
                ActionButton { text: "Cancel"; tone: "neutral"; Layout.fillWidth: true; onClicked: rateDialog.close() }
                ActionButton { text: "Save Demo Rate"; Layout.fillWidth: true; onClicked: { backend.setDailyFillRate(root.editingId, root.editingMaterial, root.editingRate); rateDialog.close() } }
            }
        }
    }
}
