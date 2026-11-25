import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "Health.js" as Health

Item {
    id: root
    property var stateData: ({})
    readonly property var stations: stateData.stations || []
    readonly property string selectedId: stateData.selectedStationId || ""
    readonly property var selectedStation: {
        for (var i = 0; i < stations.length; i++) {
            if (stations[i].id === selectedId) return stations[i]
        }
        return null
    }
    property bool placementMode: false
    signal stationRequested(string stationId)
    signal collectionRequested(string stationId, string material)

    function accent(status) {
        return status === "Online" ? "#34D399" : status === "Offline" ? "#FB7185" : "#FBBF24"
    }
    function fullestMaterial(station) {
        if (!station) return "plastic"
        var b = station.bins
        return b.plastic >= b.paper && b.plastic >= b.metal ? "plastic"
             : b.paper >= b.metal ? "paper" : "metal"
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 14

        RowLayout {
            Layout.fillWidth: true
            spacing: 12
            Column {
                spacing: 5
                Text { text: "Romania Station Network"; color: "#F8FAFC"; font.pixelSize: 24; font.bold: true }
                Text { text: "Real-world map · fictional station coordinates · drag to pan, scroll to zoom"; color: "#94A3B8"; font.pixelSize: 11 }
            }
            Item { Layout.fillWidth: true }
            ActionButton {
                text: "Show Romania"; tone: "neutral"
                enabled: mapLoader.status === Loader.Ready
                onClicked: mapLoader.item.resetView()
            }
            Rectangle {
                width: 119; height: 31; radius: 15
                color: "#173B30"
                Text { anchors.centerIn: parent; text: "● ROMANIA MAP"; color: "#34D399"; font.pixelSize: 10; font.bold: true }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 16

            Rectangle {
                id: mapFrame
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumWidth: 360
                radius: 16
                color: "#1A2A35"
                border.color: "#314652"
                clip: true

                Loader {
                    id: mapLoader
                    anchors.fill: parent
                    active: root.visible
                    source: "RomaniaMap.qml"
                    onLoaded: {
                        item.stations = Qt.binding(function() { return root.stations })
                        item.selectedId = Qt.binding(function() { return root.selectedId })
                        item.placing = Qt.binding(function() { return root.placementMode })
                        item.stationClicked.connect(function(id) { backend.selectStation(id) })
                        item.coordinateChosen.connect(function(lat, lon) {
                            if (backend.setStationCoordinates(root.selectedId, lat, lon))
                                root.placementMode = false
                        })
                    }
                }

                // If the optional QtLocation module is missing, other pages still load.
                Rectangle {
                    anchors.fill: parent
                    color: "#172630"
                    visible: mapLoader.status === Loader.Error
                    ColumnLayout {
                        anchors.centerIn: parent
                        width: parent.width - 42
                        spacing: 14
                        Text { Layout.alignment: Qt.AlignHCenter; text: "Map component unavailable"; color: "#E2E8F0"; font.pixelSize: 17; font.bold: true }
                        Text {
                            Layout.fillWidth: true
                            text: "Qt Location is needed for the live map. Install the full PySide6 package in your virtual environment. The station and collection pages still work."
                            color: "#A5B4C5"; font.pixelSize: 12; wrapMode: Text.WordWrap
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }
                }
            }

            Rectangle {
                id: detailsPanel
                Layout.preferredWidth: 302
                Layout.fillHeight: true
                radius: 16
                color: "#161F29"
                border.color: "#293644"

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 17
                    spacing: 10

                    // Scroll only the detailed metrics. Buttons are pinned below it,
                    // always within the panel, even at 1160x760 window size.
                    Flickable {
                        id: detailsScroll
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        contentHeight: detailsContent.implicitHeight + 6
                        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                        ColumnLayout {
                            id: detailsContent
                            width: parent.width - 8
                            spacing: 12
                            Text { text: "STATION DETAILS"; color: "#7F94A9"; font.pixelSize: 10; font.bold: true; font.letterSpacing: 1.2 }
                            Text {
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                                text: root.selectedStation ? root.selectedStation.name : "Select a marker"
                                color: "#F8FAFC"; font.pixelSize: 19; font.bold: true
                            }
                            RowLayout {
                                Layout.fillWidth: true
                                Text { text: root.selectedId; color: "#90A5B8"; font.pixelSize: 12 }
                                Item { Layout.fillWidth: true }
                                Rectangle { width: 8; height: 8; radius: 4; color: root.selectedStation ? root.accent(root.selectedStation.status) : "#64748B" }
                                Text { text: root.selectedStation ? root.selectedStation.status : "Unknown"; color: root.selectedStation ? root.accent(root.selectedStation.status) : "#94A3B8"; font.pixelSize: 11; font.bold: true }
                            }
                            Text {
                                Layout.fillWidth: true
                                wrapMode: Text.WordWrap
                                text: root.selectedStation ? root.selectedStation.location : "Select a station pin on the map."
                                color: "#A3B5C7"; font.pixelSize: 12
                            }
                            Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: "#2B3A48" }
                            Text { text: "CONTAINER CAPACITY"; color: "#93A6B9"; font.pixelSize: 11; font.bold: true; font.letterSpacing: .9 }
                            
                            RowLayout {
                                Layout.fillWidth: true

                                readonly property var health:
                                    Health.evaluate(
                                        root.selectedStation,
                                        root.stateData.tickets || []
                                    )

                                Text {
                                    text: "HEALTH SCORE"
                                    color: "#93A6B9"
                                    font.pixelSize: 11
                                    font.bold: true
                                }

                                Item {
                                    Layout.fillWidth: true
                                }

                                Text {
                                    text: parent.health.score +
                                        "/100 · " +
                                        parent.health.label

                                    color: parent.health.color
                                    font.pixelSize: 11
                                    font.bold: true
                                }
                            }

                            Repeater {
                                model: ["plastic", "paper", "metal"]
                                delegate: MaterialBar {
                                    required property string modelData
                                    Layout.fillWidth: true
                                    label: modelData.charAt(0).toUpperCase() + modelData.slice(1)
                                    percent: root.selectedStation ? root.selectedStation.bins[modelData] : 0
                                    accent: modelData === "plastic" ? "#34D399" : modelData === "paper" ? "#60A5FA" : "#A78BFA"
                                }
                            }
                            Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: "#2B3A48" }
                            Text { text: "MAP COORDINATES"; color: "#93A6B9"; font.pixelSize: 10; font.bold: true; font.letterSpacing: .9 }
                            Text {
                                text: root.selectedStation ? Number(root.selectedStation.latitude).toFixed(4) + "° N, " + Number(root.selectedStation.longitude).toFixed(4) + "° E" : "Not available"
                                color: "#CBD5E1"; font.pixelSize: 11
                            }
                            Text {
                                Layout.fillWidth: true
                                wrapMode: Text.WordWrap
                                text: "Approximate demo placement · Not a real GPS measurement"
                                color: "#6E849A"; font.pixelSize: 10
                            }
                        }
                    }

                    Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: "#2B3A48" }

                    ActionButton {
                        Layout.fillWidth: true
                        text: root.placementMode ? "Cancel Marker Placement" : "Place Station Marker"
                        tone: root.placementMode ? "warning" : "neutral"
                        enabled: !!root.selectedStation && mapLoader.status === Loader.Ready
                        onClicked: root.placementMode = !root.placementMode
                    }
                    ActionButton {
                        Layout.fillWidth: true
                        text: "Open Station"
                        tone: "neutral"
                        enabled: !!root.selectedStation
                        onClicked: root.stationRequested(root.selectedId)
                    }
                    ActionButton {
                        Layout.fillWidth: true
                        text: "Request Pickup"
                        enabled: !!root.selectedStation
                        onClicked: root.collectionRequested(root.selectedId, root.fullestMaterial(root.selectedStation))
                    }
                    Text {
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                        text: root.placementMode ? "Click the map to save this demo station's position." : "Collection requests do not dispatch real crews."
                        color: root.placementMode ? "#6EE7B7" : "#718498"
                        font.pixelSize: 10
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 15
            Repeater {
                model: [{ label: "Online", c: "#34D399" }, { label: "Offline", c: "#FB7185" }, { label: "Maintenance", c: "#FBBF24" }]
                delegate: RowLayout {
                    required property var modelData
                    spacing: 6
                    Rectangle { width: 8; height: 8; radius: 4; color: modelData.c }
                    Text { text: modelData.label; color: "#91A7BA"; font.pixelSize: 11 }
                }
            }
            Item { Layout.fillWidth: true }
            Text { text: root.stations.length + " demo stations · © OpenStreetMap contributors"; color: "#8297A9"; font.pixelSize: 10 }
        }
    }
}
