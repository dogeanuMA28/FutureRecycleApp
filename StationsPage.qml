import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    property var stateData: ({})
    signal collectionRequested(string stationId, string material)
    signal maintenanceRequested(string stationId)
    readonly property var stations: stateData.stations || []
    readonly property var selected: {
        for (var i = 0; i < stations.length; i++)
            if (stations[i].id === stateData.selectedStationId) return stations[i]
        return null
    }
    readonly property int selectedTotal: selected ? selected.counts.plastic + selected.counts.paper + selected.counts.metal : 0

    RowLayout {
        anchors.fill: parent
        spacing: 16

        // LEFT: ALL RECYCLING STATIONS
        Rectangle {
            Layout.preferredWidth: 308
            Layout.fillHeight: true
            color: "#161F29"; border.color: "#293644"; radius: 14

            ColumnLayout {
                anchors.fill: parent; anchors.margins: 16; spacing: 12
                RowLayout {
                    Layout.fillWidth: true
                    Text { text: "Station Network"; font.pixelSize: 18; font.bold: true; color: "#F8FAFC" }
                    Item { Layout.fillWidth: true }
                    Rectangle {
                        width: 29; height: 26; radius: 8; color: "#244737"
                        Text { anchors.centerIn: parent; text: root.stations.length; color: "#6EE7B7"; font.pixelSize: 12; font.bold: true }
                    }
                }
                Text { text: "Select a station to inspect"; color: "#8FA2B8"; font.pixelSize: 11 }
                TextField {
                    id: searchInput
                    Layout.fillWidth: true; implicitHeight: 39
                    color: "#E6EDF4"; font.pixelSize: 12
                    placeholderText: "Search stations..."
                    placeholderTextColor: "#6D8295"
                    background: Rectangle { color: "#21303C"; border.color: "#34465B"; radius: 9 }
                    leftPadding: 12
                }
                Flickable {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    contentHeight: listContent.implicitHeight + 8
                    ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
                    ColumnLayout {
                        id: listContent
                        width: parent.width - 9
                        spacing: 9
                        Repeater {
                            model: root.stations.filter(function(s) {
                                var text = searchInput.text.toLowerCase()
                                return !text || (s.name + " " + s.location + " " + s.id).toLowerCase().indexOf(text) >= 0
                            })
                            delegate: Rectangle {
                                id: listCard
                                required property var modelData
                                Layout.fillWidth: true; Layout.preferredHeight: 86
                                radius: 11
                                color: root.stateData.selectedStationId === modelData.id ? "#1A3A32" : hover.hovered ? "#22313D" : "#1C2833"
                                border.color: root.stateData.selectedStationId === modelData.id ? "#10B981" : "#324153"
                                Behavior on color { ColorAnimation { duration: 160 } }
                                ColumnLayout {
                                    anchors.fill: parent; anchors.margins: 12; spacing: 6
                                    RowLayout {
                                        Layout.fillWidth: true
                                        Text { text: listCard.modelData.name; Layout.fillWidth: true; color: "#F8FAFC"; font.pixelSize: 13; font.bold: true; elide: Text.ElideRight }
                                        Text { text: "●"; color: listCard.modelData.status === "Online" ? "#34D399" : "#FBBF24"; font.pixelSize: 11 }
                                    }
                                    Text { text: listCard.modelData.id + " · " + listCard.modelData.location; color: "#93A4B8"; font.pixelSize: 11; elide: Text.ElideRight; Layout.fillWidth: true }
                                    Text { text: listCard.modelData.status.toUpperCase(); color: listCard.modelData.status === "Online" ? "#6EE7B7" : "#FBBF24"; font.pixelSize: 10; font.bold: true }
                                }
                                HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
                                TapHandler { onTapped: backend.selectStation(listCard.modelData.id) }
                            }
                        }
                    }
                }
                Button {
                    Layout.fillWidth: true; implicitHeight: 44
                    text: "+ Add Station"
                    onClicked: addPopup.open()
                    background: Rectangle { radius: 9; color: parent.hovered ? "#34D399" : "#10B981" }
                    contentItem: Text { text: parent.text; color: "#092319"; font.pixelSize: 12; font.bold: true; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                }
            }
        }

        // RIGHT: THE SELECTED STATION, INCLUDING ITS THREE CONTAINERS
        Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            contentHeight: details.implicitHeight + 20
            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

            ColumnLayout {
                id: details
                width: parent.width - 14
                spacing: 17

                RowLayout {
                    Layout.fillWidth: true
                    Column {
                        spacing: 5
                        Text { text: root.selected ? root.selected.name : "No station selected"; color: "#F8FAFC"; font.pixelSize: 24; font.bold: true }
                        Text { text: root.selected ? root.selected.id + "  ·  " + root.selected.location : ""; color: "#8DA0B4"; font.pixelSize: 12 }
                    }
                    Item { Layout.fillWidth: true }
                    Rectangle {
                        width: 114; height: 32; radius: 16
                        color: root.selected && root.selected.status === "Online" ? "#173B30" : "#423622"
                        Text {
                            anchors.centerIn: parent
                            text: "● " + (root.selected ? root.selected.status : "Unknown")
                            color: root.selected && root.selected.status === "Online" ? "#6EE7B7" : "#FBBF24"
                            font.pixelSize: 11; font.bold: true
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true; spacing: 12
                    MetricCard { label: "ITEMS SORTED"; amount: root.selectedTotal.toLocaleString(); note: "This station only"; accent: "#34D399" }
                    MetricCard { label: "PLASTIC"; amount: root.selected ? root.selected.counts.plastic.toLocaleString() : "0"; note: "Objects sorted"; accent: "#10B981" }
                    MetricCard { label: "PAPER"; amount: root.selected ? root.selected.counts.paper.toLocaleString() : "0"; note: "Objects sorted"; accent: "#60A5FA" }
                    MetricCard { label: "METAL"; amount: root.selected ? root.selected.counts.metal.toLocaleString() : "0"; note: "Objects sorted"; accent: "#A78BFA" }
                }

                StationHealth {
                    station: root.selected
                    tickets: root.stateData.tickets || []
                }

                Rectangle {
                    Layout.fillWidth: true; Layout.preferredHeight: 340
                    color: "#161F29"; border.color: "#293644"; radius: 15
                    ColumnLayout {
                        anchors.fill: parent; anchors.margins: 20; spacing: 15
                        Text { text: "Container Monitoring"; color: "#F8FAFC"; font.pixelSize: 18; font.bold: true }
                        Text { text: "Virtual fill levels · 5% added per successful scan"; color: "#91A3B7"; font.pixelSize: 11 }
                        RowLayout {
                            Layout.fillWidth: true; Layout.fillHeight: true; spacing: 12
                            Repeater {
                                model: ["plastic", "paper", "metal"]
                                delegate: Rectangle {
                                    id: binCard
                                    required property string modelData
                                    readonly property int fill: root.selected ? root.selected.bins[modelData] : 0
                                    readonly property color accent: modelData === "plastic" ? "#10B981" : modelData === "paper" ? "#60A5FA" : "#A78BFA"
                                    Layout.fillWidth: true; Layout.fillHeight: true
                                    radius: 11; color: "#1D2934"; border.color: "#314151"
                                    ColumnLayout {
                                        anchors.fill: parent; anchors.margins: 11; spacing: 8
                                        Text { text: binCard.modelData.charAt(0).toUpperCase() + binCard.modelData.slice(1); color: "#EDF3FA"; font.pixelSize: 13; font.bold: true; Layout.alignment: Qt.AlignHCenter }
                                        Item {
                                            Layout.fillWidth: true; Layout.fillHeight: true
                                            Rectangle {
                                                anchors.centerIn: parent
                                                width: Math.min(86, parent.width - 12)
                                                height: Math.min(137, parent.height - 5)
                                                radius: 10; clip: true
                                                color: "#293846"; border.color: "#4B5E6D"; border.width: 2
                                                Rectangle {
                                                    anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
                                                    height: parent.height * binCard.fill / 100
                                                    color: binCard.fill >= 80 ? "#F59E0B" : binCard.accent
                                                    opacity: 0.86
                                                    Behavior on height { NumberAnimation { duration: 580; easing.type: Easing.OutCubic } }
                                                }
                                                Text { anchors.centerIn: parent; text: binCard.fill + "%"; color: "white"; font.pixelSize: 20; font.bold: true; style: Text.Outline; styleColor: "#18212A" }
                                            }
                                        }
                                        Text {
                                            text: binCard.fill >= 80 ? "⚠ Almost full" : "● Operational"
                                            color: binCard.fill >= 80 ? "#FBBF24" : "#6EE7B7"
                                            font.pixelSize: 10
                                            Layout.alignment: Qt.AlignHCenter
                                        }
                                        Button {
                                            Layout.fillWidth: true; implicitHeight: 32
                                            text: "Empty"
                                            onClicked: backend.emptyBin(root.selected.id, binCard.modelData)
                                            background: Rectangle { radius: 7; color: parent.hovered ? "#344758" : "#2B3A49" }
                                            contentItem: Text { text: parent.text; color: "#DBE5EF"; font.pixelSize: 11; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true; Layout.preferredHeight: 270
                    color: "#161F29"; border.color: "#293644"; radius: 15
                    ColumnLayout {
                        anchors.fill: parent; anchors.margins: 20; spacing: 14
                        Text { text: "Station Management"; color: "#F8FAFC"; font.pixelSize: 18; font.bold: true }
                        RowLayout {
                            Layout.fillWidth: true
                            Text { text: "Operating status"; color: "#9AACC0"; font.pixelSize: 12 }
                            Item { Layout.fillWidth: true }
                            ComboBox {
                                id: statusCombo
                                implicitWidth: 170; implicitHeight: 37
                                model: ["Online", "Offline", "Maintenance"]
                                currentIndex: root.selected ? model.indexOf(root.selected.status) : 0
                                onActivated: function(index) { if (root.selected) backend.setStatus(root.selected.id, model[index]) }
                                background: Rectangle { radius: 8; color: "#22313F"; border.color: "#41536B" }
                                contentItem: Text { text: statusCombo.displayText; leftPadding: 12; color: "#F1F5F9"; font.pixelSize: 12; verticalAlignment: Text.AlignVCenter }
                            }
                        }
                        RowLayout {
                            Layout.fillWidth: true; spacing: 10
                            ActionButton {
                                Layout.fillWidth: true; text: "Request Collection"
                                onClicked: {
                                    if (!root.selected) return
                                    var key = "plastic"
                                    for (var i = 0; i < 3; ++i) {
                                        var material = ["plastic", "paper", "metal"][i]
                                        if (root.selected.bins[material] > root.selected.bins[key]) key = material
                                    }
                                    root.collectionRequested(root.selected.id, key)
                                }
                            }
                            ActionButton {
                                Layout.fillWidth: true; text: "Create Service Ticket"; tone: "neutral"
                                onClicked: { if (root.selected) root.maintenanceRequested(root.selected.id) }
                            }
                        }
                        RowLayout {
                            Layout.fillWidth: true; spacing: 10
                            Button {
                                Layout.fillWidth: true; implicitHeight: 42; text: "Empty All Bins"
                                onClicked: { if (root.selected) backend.emptyStation(root.selected.id) }
                                background: Rectangle { radius: 9; color: parent.hovered ? "#304255" : "#22313F"; border.color: "#40536B" }
                                contentItem: Text { text: parent.text; color: "#E4EDF5"; font.pixelSize: 12; font.bold: true; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                            }
                            Button {
                                Layout.fillWidth: true; implicitHeight: 42; text: "Remove Station"
                                onClicked: removeDialog.open()
                                background: Rectangle { radius: 9; color: parent.hovered ? "#553039" : "#34252D"; border.color: "#955362" }
                                contentItem: Text { text: parent.text; color: "#FDA4AF"; font.pixelSize: 12; font.bold: true; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                            }
                        }
                        Text { text: "Operations are simulated and saved locally."; color: "#73879B"; font.pixelSize: 11 }
                    }
                }

                Text { Layout.alignment: Qt.AlignHCenter; text: "SIMULATION MODE · NO PHYSICAL DEVICES CONNECTED"; color: "#62768C"; font.pixelSize: 10; font.bold: true }
            }
        }
    }

    Popup {
        id: addPopup
        anchors.centerIn: parent
        width: 435; height: 302
        modal: true; focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        background: Rectangle { color: "#1B2935"; radius: 16; border.color: "#425368" }
        contentItem: ColumnLayout {
            spacing: 13
            Text { text: "Add a recycling station"; font.pixelSize: 20; font.bold: true; color: "#F8FAFC" }
            Text { text: "New stations start online with empty containers."; color: "#93A6BA"; font.pixelSize: 12 }
            TextField {
                id: newStationName; Layout.fillWidth: true; implicitHeight: 43
                placeholderText: "Station name (e.g. Main Square)"; placeholderTextColor: "#7E92A7"; color: "#F8FAFC"; leftPadding: 12
                background: Rectangle { color: "#263746"; radius: 9; border.color: "#43566B" }
            }
            TextField {
                id: newStationLocation; Layout.fillWidth: true; implicitHeight: 43
                placeholderText: "Location (e.g. North District)"; placeholderTextColor: "#7E92A7"; color: "#F8FAFC"; leftPadding: 12
                background: Rectangle { color: "#263746"; radius: 9; border.color: "#43566B" }
            }
            Item { Layout.fillHeight: true }
            RowLayout {
                Layout.fillWidth: true; spacing: 10
                Button {
                    Layout.fillWidth: true; implicitHeight: 41; text: "Cancel"; onClicked: addPopup.close()
                    background: Rectangle { color: "#314253"; radius: 9 }
                    contentItem: Text { text: parent.text; color: "#E4EDF6"; font.pixelSize: 12; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                }
                Button {
                    Layout.fillWidth: true; implicitHeight: 41; text: "Create Station"
                    enabled: newStationName.text.trim().length > 0 && newStationLocation.text.trim().length > 0
                    onClicked: {
                        var added = backend.addStation(newStationName.text, newStationLocation.text)
                        if (added !== "") {
                            newStationName.text = ""
                            newStationLocation.text = ""
                            addPopup.close()
                            searchInput.text = ""
                        }
                    }
                    background: Rectangle { color: parent.enabled ? "#10B981" : "#315648"; radius: 9 }
                    contentItem: Text { text: parent.text; color: "#092519"; font.pixelSize: 12; font.bold: true; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                }
            }
        }
    }

    Dialog {
        id: removeDialog
        anchors.centerIn: parent
        title: "Remove station?"
        modal: true
        standardButtons: Dialog.Yes | Dialog.No
        onAccepted: { if (root.selected) backend.removeStation(root.selected.id) }
        background: Rectangle { color: "#1B2935"; radius: 14; border.color: "#45576A" }
        contentItem: Text {
            width: 345
            text: "Remove " + (root.selected ? root.selected.name : "this station") + "? Historical scans are kept."
            color: "#E3EBF4"; wrapMode: Text.WordWrap
        }
    }
}
