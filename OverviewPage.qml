import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "Health.js" as Health

Item {
    id: root
    property var stateData: ({})
    signal scanRequested()
    signal stationRequested(string stationId)
    signal analyticsRequested()
    signal activityRequested()
    signal alertsRequested()
    signal collectionsRequested()

    readonly property var stations: stateData.stations || []
    readonly property var history: stateData.history || []
    readonly property var totals: {
        var result = {plastic: 0, paper: 0, metal: 0, all: 0, online: 0}
        for (var i = 0; i < stations.length; i++) {
            var s = stations[i]
            result.plastic += s.counts.plastic
            result.paper += s.counts.paper
            result.metal += s.counts.metal
            if (s.status === "Online") result.online++
        }
        result.all = result.plastic + result.paper + result.metal
        return result
    }
    readonly property var alerts: stateData.alerts || []
    readonly property var activity: stateData.activity || []
    readonly property var collections: stateData.collections || []
    readonly property var tickets: stateData.tickets || []

    Flickable {
        anchors.fill: parent
        clip: true
        contentHeight: pageContent.implicitHeight + 25
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

        ColumnLayout {
            id: pageContent
            width: parent.width - 16
            spacing: 18

            RowLayout {
                Layout.fillWidth: true
                Column {
                    spacing: 6
                    Text { text: "Network Overview"; color: "#F8FAFC"; font.pixelSize: 24; font.bold: true }
                    Text { text: "All your smart recycling stations, in one place"; color: "#9BACBF"; font.pixelSize: 12 }
                }
                Item { Layout.fillWidth: true }
                Button {
                    text: "+ New Scan"
                    implicitWidth: 148; implicitHeight: 43
                    onClicked: root.scanRequested()
                    background: Rectangle { color: parent.hovered ? "#34D399" : "#10B981"; radius: 10 }
                    contentItem: Text {
                        text: parent.text; color: "#072117"; font.bold: true; font.pixelSize: 13
                        horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 132
                radius: 16
                color: "#10382D"
                border.color: "#256148"
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 23
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        Text { text: "FUTURERECYCLE NETWORK"; color: "#73E9B5"; font.pixelSize: 10; font.bold: true; font.letterSpacing: 1.6 }
                        Text { text: root.totals.online + " of " + root.stations.length + " stations online"; color: "#F8FAFC"; font.pixelSize: 24; font.bold: true }
                        Text { text: "Live demo simulation · All values are fictional"; color: "#A3D3BE"; font.pixelSize: 12 }
                    }
                    Rectangle {
                        width: 76; height: 76; radius: 38
                        color: "#1C6049"; border.color: "#4DDCA0"; border.width: 2
                        Text { anchors.centerIn: parent; text: "✓"; font.pixelSize: 34; font.bold: true; color: "#75F0B8" }
                    }
                }
            }

            GridLayout {
                Layout.fillWidth: true
                columns: 4
                columnSpacing: 12
                MetricCard { label: "TOTAL PROCESSED"; amount: root.totals.all.toLocaleString(); note: "Across all stations"; accent: "#34D399" }
                MetricCard { label: "PLASTIC ITEMS"; amount: root.totals.plastic.toLocaleString(); note: "Sorted into plastic"; accent: "#10B981" }
                MetricCard { label: "PAPER ITEMS"; amount: root.totals.paper.toLocaleString(); note: "Sorted into paper"; accent: "#60A5FA" }
                MetricCard { label: "METAL ITEMS"; amount: root.totals.metal.toLocaleString(); note: "Sorted into metal"; accent: "#A78BFA" }
            }

            RowLayout {
                Layout.fillWidth: true; spacing: 12
                Rectangle {
                    Layout.fillWidth: true; Layout.preferredHeight: 87; radius: 12
                    color: "#1A2A32"; border.color: "#344551"
                    RowLayout {
                        anchors.fill: parent; anchors.margins: 14
                        Column {
                            spacing: 6
                            Text { text: "OPEN COLLECTIONS"; color: "#91A5B9"; font.pixelSize: 10; font.bold: true }
                            Text { text: root.collections.filter(function(c){return c.status === "Requested" || c.status === "Scheduled"}).length + " pickup requests"; color: "#F8FAFC"; font.pixelSize: 18; font.bold: true }
                        }
                        Item { Layout.fillWidth: true }
                        Button { text: "Manage ›"; flat: true; onClicked: root.collectionsRequested(); contentItem: Text { text: parent.text; color: "#6EE7B7"; font.pixelSize: 12; font.bold: true } }
                    }
                }
                Rectangle {
                    Layout.fillWidth: true; Layout.preferredHeight: 87; radius: 12
                    color: "#1A2A32"; border.color: "#344551"
                    RowLayout {
                        anchors.fill: parent; anchors.margins: 14
                        Column {
                            spacing: 6
                            Text { text: "NETWORK ISSUES"; color: "#91A5B9"; font.pixelSize: 10; font.bold: true }
                            Text { text: root.alerts.length + " active alerts"; color: "#FBBF24"; font.pixelSize: 18; font.bold: true }
                        }
                        Item { Layout.fillWidth: true }
                        Button { text: "Review ›"; flat: true; onClicked: root.alertsRequested(); contentItem: Text { text: parent.text; color: "#6EE7B7"; font.pixelSize: 12; font.bold: true } }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 15
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 260
                    radius: 15; color: "#161F29"; border.color: "#293644"
                    ColumnLayout {
                        anchors.fill: parent; anchors.margins: 20; spacing: 16
                        Text { text: "Network Waste Distribution"; color: "#F8FAFC"; font.pixelSize: 17; font.bold: true }
                        Text { text: "Combined material breakdown"; color: "#8C9EB2"; font.pixelSize: 11 }
                        MaterialBar { Layout.fillWidth: true; label: "Plastic"; percent: root.totals.all ? root.totals.plastic * 100 / root.totals.all : 0; accent: "#10B981" }
                        MaterialBar { Layout.fillWidth: true; label: "Paper"; percent: root.totals.all ? root.totals.paper * 100 / root.totals.all : 0; accent: "#60A5FA" }
                        MaterialBar { Layout.fillWidth: true; label: "Metal"; percent: root.totals.all ? root.totals.metal * 100 / root.totals.all : 0; accent: "#A78BFA" }
                        Item { Layout.fillHeight: true }
                    }
                }
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 260
                    radius: 15; color: "#161F29"; border.color: "#293644"
                    ColumnLayout {
                        anchors.fill: parent; anchors.margins: 20; spacing: 14
                        RowLayout {
                            Layout.fillWidth: true
                            Text { text: "Network Alerts"; font.pixelSize: 17; font.bold: true; color: "#F8FAFC" }
                            Item { Layout.fillWidth: true }
                            Text { text: root.alerts.length + " active"; color: root.alerts.length ? "#FBBF24" : "#34D399"; font.pixelSize: 11; font.bold: true }
                        }
                        Text { text: "Capacity and station availability"; color: "#8C9EB2"; font.pixelSize: 11 }
                        Repeater {
                            model: root.alerts.slice(0, 3)
                            delegate: Rectangle {
                                required property var modelData
                                Layout.fillWidth: true; Layout.preferredHeight: 43
                                radius: 9; color: "#232B34"
                                RowLayout {
                                    anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 12; spacing: 10
                                    Text { text: "!"; color: "#FBBF24"; font.pixelSize: 18; font.bold: true }
                                    Column {
                                        Layout.fillWidth: true; spacing: 2
                                        Text { text: modelData.title; color: "#E8EDF4"; font.pixelSize: 11; font.bold: true; elide: Text.ElideRight; width: parent.width }
                                        Text { text: modelData.stationId + " · " + modelData.stationName; color: "#8697AC"; font.pixelSize: 10 }
                                    }
                                    Text { text: "›"; color: "#9BACBF"; font.pixelSize: 18 }
                                }
                                TapHandler { onTapped: root.alertsRequested() }
                            }
                        }
                        Text { visible: root.alerts.length === 0; text: "✓ No active alerts"; color: "#34D399"; font.pixelSize: 13 }
                        Item { Layout.fillHeight: true }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Text { text: "Station Network"; color: "#F8FAFC"; font.pixelSize: 19; font.bold: true }
                Item { Layout.fillWidth: true }
                Text { text: "Select a station to inspect"; color: "#7E92A7"; font.pixelSize: 11 }
            }
            GridLayout {
                Layout.fillWidth: true
                columns: 3
                columnSpacing: 13
                rowSpacing: 13
                Repeater {
                    model: root.stations.slice(0, 6)
                    delegate: Rectangle {
                        id: stationTile
                        required property var modelData
                        Layout.fillWidth: true; Layout.preferredHeight: 157
                        radius: 13
                        color: tileHover.hovered ? "#202E3A" : "#161F29"
                        border.color: tileHover.hovered ? "#4C9978" : "#293644"
                        Behavior on color { ColorAnimation { duration: 160 } }
                        ColumnLayout {
                            anchors.fill: parent; anchors.margins: 14; spacing: 8
                            RowLayout {
                                Layout.fillWidth: true
                                Text { text: stationTile.modelData.name; font.pixelSize: 14; font.bold: true; color: "#F8FAFC"; Layout.fillWidth: true; elide: Text.ElideRight }
                                Text {
                                    text: "● " + stationTile.modelData.status
                                    font.pixelSize: 10; font.bold: true
                                    color: stationTile.modelData.status === "Online" ? "#34D399" : "#FBBF24"
                                }
                            }
                            Text { text: stationTile.modelData.id + " · " + stationTile.modelData.location; color: "#8294AB"; font.pixelSize: 11; elide: Text.ElideRight; Layout.fillWidth: true }
                            
                            Text {
                                readonly property var health:
                                    Health.evaluate(
                                        stationTile.modelData,
                                        root.tickets
                                    )

                                text: "HEALTH  " +
                                    health.score + "/100  ·  " +
                                    health.label

                                color: health.color
                                font.pixelSize: 11
                                font.bold: true
                            }

                            Item { Layout.fillHeight: true }
                            Text { text: "CONTAINER LEVELS"; color: "#657B91"; font.pixelSize: 9; font.bold: true }
                            RowLayout {
                                Layout.fillWidth: true; spacing: 5
                                Repeater {
                                    model: ["plastic", "paper", "metal"]
                                    delegate: Rectangle {
                                        required property string modelData
                                        Layout.fillWidth: true; height: 8; radius: 3; color: "#2C3A47"
                                        Rectangle {
                                            anchors.left: parent.left; height: parent.height; radius: 3
                                            width: parent.width * stationTile.modelData.bins[modelData] / 100
                                            color: modelData === "plastic" ? "#10B981" : modelData === "paper" ? "#60A5FA" : "#A78BFA"
                                        }
                                    }
                                }
                            }
                        }
                        HoverHandler { id: tileHover; cursorShape: Qt.PointingHandCursor }
                        TapHandler { onTapped: root.stationRequested(stationTile.modelData.id) }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true; Layout.preferredHeight: 245
                radius: 14; color: "#161F29"; border.color: "#293644"
                ColumnLayout {
                    anchors.fill: parent; anchors.margins: 19; spacing: 12
                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: "Recent Network Activity"; color: "#F8FAFC"; font.pixelSize: 17; font.bold: true }
                        Item { Layout.fillWidth: true }
                        Text { text: root.activity.length + " events"; color: "#94A3B8"; font.pixelSize: 11 }
                        Button {
                            text: "View all  ›"; flat: true
                            onClicked: root.activityRequested()
                            contentItem: Text { text: parent.text; color: "#5EE0AB"; font.pixelSize: 11; font.bold: true }
                        }
                    }
                    Repeater {
                        model: root.activity.slice(0, 3)
                        delegate: Rectangle {
                            required property var modelData
                            Layout.fillWidth: true; Layout.preferredHeight: 44
                            color: "#1D2934"; radius: 8
                            RowLayout {
                                anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 12; spacing: 12
                                Rectangle { width: 8; height: 8; radius: 4; color: modelData.type === "Scan" ? "#34D399" : "#FBBF24" }
                                Text { text: modelData.title; color: "#F1F5F9"; font.pixelSize: 12; Layout.fillWidth: true; elide: Text.ElideRight }
                                Text { text: modelData.stationId; color: "#93A5BB"; font.pixelSize: 11 }
                                Text { text: modelData.type; color: modelData.type === "Scan" ? "#34D399" : "#FBBF24"; font.pixelSize: 11 }
                                Text { text: new Date(modelData.createdAt).toLocaleString(); color: "#768BA1"; font.pixelSize: 10 }
                            }
                        }
                    }
                    Text { visible: root.activity.length === 0; text: "No activity yet. Try a scan, pickup, or service ticket."; color: "#8596A9"; font.pixelSize: 12 }
                    Item { Layout.fillHeight: true }
                }
            }
            Text { Layout.alignment: Qt.AlignHCenter; text: "FUTURERECYCLE · FICTIONAL NETWORK DEMONSTRATION"; color: "#53657A"; font.pixelSize: 10; font.bold: true }
        }
    }
}
