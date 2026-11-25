import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    property var stateData: ({})
    readonly property var stations: stateData.stations || []
    readonly property var history: stateData.history || []
    readonly property var totals: {
        var r = {plastic: 0, paper: 0, metal: 0, all: 0}
        for (var i = 0; i < stations.length; i++) {
            r.plastic += stations[i].counts.plastic
            r.paper += stations[i].counts.paper
            r.metal += stations[i].counts.metal
        }
        r.all = r.plastic + r.paper + r.metal
        return r
    }
    readonly property var activeHistory: history.filter(function(h) { return !h.demo })

    Flickable {
        anchors.fill: parent
        contentHeight: pageContent.implicitHeight + 28
        clip: true
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

        ColumnLayout {
            id: pageContent
            width: parent.width - 14
            spacing: 17

            RowLayout {
                Layout.fillWidth: true
                Column {
                    spacing: 6
                    Text { text: "Waste Analytics"; color: "#F8FAFC"; font.pixelSize: 24; font.bold: true }
                    Text { text: "Combined network statistics and recent sorting events"; color: "#92A5BA"; font.pixelSize: 12 }
                }
                Item { Layout.fillWidth: true }
                Rectangle {
                    width: 114; height: 32; radius: 16; color: "#173B30"
                    Text { anchors.centerIn: parent; text: "● LIVE DEMO"; color: "#6EE7B7"; font.pixelSize: 10; font.bold: true }
                }
            }

            GridLayout {
                Layout.fillWidth: true; columns: 4; columnSpacing: 12
                MetricCard { label: "TOTAL SORTED"; amount: root.totals.all.toLocaleString(); note: "All stations combined"; accent: "#34D399" }
                MetricCard { label: "PLASTIC"; amount: root.totals.plastic.toLocaleString(); note: "Successfully sorted"; accent: "#10B981" }
                MetricCard { label: "PAPER"; amount: root.totals.paper.toLocaleString(); note: "Successfully sorted"; accent: "#60A5FA" }
                MetricCard { label: "METAL"; amount: root.totals.metal.toLocaleString(); note: "Successfully sorted"; accent: "#A78BFA" }
            }

            RowLayout {
                Layout.fillWidth: true; spacing: 15
                Rectangle {
                    Layout.fillWidth: true; Layout.preferredHeight: 320
                    radius: 14; color: "#161F29"; border.color: "#293644"
                    ColumnLayout {
                        anchors.fill: parent; anchors.margins: 20; spacing: 7
                        Text { text: "Material Distribution"; color: "#F8FAFC"; font.pixelSize: 17; font.bold: true }
                        Text { text: "All sorted materials"; color: "#91A4B9"; font.pixelSize: 11 }
                        Item {
                            Layout.fillWidth: true; Layout.fillHeight: true
                            Canvas {
                                id: donut
                                width: Math.min(210, parent.width - 10, parent.height - 5)
                                height: width
                                anchors.centerIn: parent
                                onPaint: {
                                    var ctx = getContext("2d")
                                    ctx.clearRect(0, 0, width, height)
                                    var values = [root.totals.plastic, root.totals.paper, root.totals.metal]
                                    var colors = ["#10B981", "#60A5FA", "#A78BFA"]
                                    var sum = root.totals.all
                                    var angle = -Math.PI / 2
                                    var x = width / 2, y = height / 2, radius = width * 0.38
                                    ctx.lineWidth = 24
                                    if (!sum) {
                                        ctx.beginPath()
                                        ctx.strokeStyle = "#334155"
                                        ctx.arc(x, y, radius, 0, Math.PI * 2)
                                        ctx.stroke()
                                    } else {
                                        for (var i = 0; i < values.length; i++) {
                                            if (!values[i]) continue
                                            var arc = values[i] * 2 * Math.PI / sum
                                            ctx.beginPath()
                                            ctx.strokeStyle = colors[i]
                                            ctx.arc(x, y, radius, angle, angle + arc)
                                            ctx.stroke()
                                            angle += arc
                                        }
                                    }
                                }
                                Column {
                                    anchors.centerIn: parent; spacing: 4
                                    Text { text: root.totals.all.toLocaleString(); color: "#F8FAFC"; font.pixelSize: 27; font.bold: true; anchors.horizontalCenter: parent.horizontalCenter }
                                    Text { text: "TOTAL ITEMS"; color: "#8CA0B5"; font.pixelSize: 10; anchors.horizontalCenter: parent.horizontalCenter }
                                }
                                Connections { target: backend; function onStateChanged() { donut.requestPaint() } }
                                onWidthChanged: requestPaint()
                            }
                        }
                    }
                }
                Rectangle {
                    Layout.fillWidth: true; Layout.preferredHeight: 320
                    radius: 14; color: "#161F29"; border.color: "#293644"
                    ColumnLayout {
                        anchors.fill: parent; anchors.margins: 20; spacing: 17
                        Text { text: "Material Breakdown"; color: "#F8FAFC"; font.pixelSize: 17; font.bold: true }
                        Text { text: "Share of total processed waste"; color: "#91A4B9"; font.pixelSize: 11 }
                        Item { Layout.preferredHeight: 10 }
                        MaterialBar { Layout.fillWidth: true; label: "Plastic"; percent: root.totals.all ? root.totals.plastic / root.totals.all * 100 : 0; accent: "#10B981" }
                        MaterialBar { Layout.fillWidth: true; label: "Paper"; percent: root.totals.all ? root.totals.paper / root.totals.all * 100 : 0; accent: "#60A5FA" }
                        MaterialBar { Layout.fillWidth: true; label: "Metal"; percent: root.totals.all ? root.totals.metal / root.totals.all * 100 : 0; accent: "#A78BFA" }
                        Item { Layout.fillHeight: true }
                        Text { text: root.stations.length + " stations in the network"; color: "#7F92A8"; font.pixelSize: 11 }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true; Layout.preferredHeight: Math.max(160, root.stations.length * 48 + 95)
                radius: 14; color: "#161F29"; border.color: "#293644"
                ColumnLayout {
                    anchors.fill: parent; anchors.margins: 19; spacing: 11
                    Text { text: "Performance by Station"; color: "#F8FAFC"; font.pixelSize: 17; font.bold: true }
                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: "STATION"; Layout.fillWidth: true; color: "#71869B"; font.pixelSize: 10; font.bold: true }
                        Text { text: "PLASTIC"; Layout.preferredWidth: 88; color: "#71869B"; font.pixelSize: 10; font.bold: true }
                        Text { text: "PAPER"; Layout.preferredWidth: 78; color: "#71869B"; font.pixelSize: 10; font.bold: true }
                        Text { text: "METAL"; Layout.preferredWidth: 75; color: "#71869B"; font.pixelSize: 10; font.bold: true }
                        Text { text: "TOTAL"; Layout.preferredWidth: 75; color: "#71869B"; font.pixelSize: 10; font.bold: true }
                    }
                    Repeater {
                        model: root.stations
                        delegate: Rectangle {
                            required property var modelData
                            Layout.fillWidth: true; Layout.preferredHeight: 39
                            radius: 7; color: "#1D2934"
                            RowLayout {
                                anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 10; spacing: 10
                                Text { text: modelData.id + "  ·  " + modelData.name; Layout.fillWidth: true; color: "#E8F0F8"; font.pixelSize: 11; elide: Text.ElideRight }
                                Text { text: modelData.counts.plastic; Layout.preferredWidth: 77; color: "#6EE7B7"; font.pixelSize: 11 }
                                Text { text: modelData.counts.paper; Layout.preferredWidth: 67; color: "#93C5FD"; font.pixelSize: 11 }
                                Text { text: modelData.counts.metal; Layout.preferredWidth: 65; color: "#C4B5FD"; font.pixelSize: 11 }
                                Text { text: modelData.counts.plastic + modelData.counts.paper + modelData.counts.metal; Layout.preferredWidth: 65; color: "#F1F5F9"; font.pixelSize: 11; font.bold: true }
                            }
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true; Layout.preferredHeight: 365
                radius: 14; color: "#161F29"; border.color: "#293644"
                ColumnLayout {
                    anchors.fill: parent; anchors.margins: 19; spacing: 12
                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: "Recent Detections"; color: "#F8FAFC"; font.pixelSize: 17; font.bold: true }
                        Item { Layout.fillWidth: true }
                        Text { text: root.history.length + " records · last 40 retained"; color: "#91A4B9"; font.pixelSize: 11 }
                    }
                    RowLayout {
                        Layout.fillWidth: true; spacing: 10
                        Text { text: "OBJECT"; Layout.fillWidth: true; color: "#72879B"; font.pixelSize: 10; font.bold: true }
                        Text { text: "STATION"; Layout.preferredWidth: 83; color: "#72879B"; font.pixelSize: 10; font.bold: true }
                        Text { text: "CATEGORY"; Layout.preferredWidth: 87; color: "#72879B"; font.pixelSize: 10; font.bold: true }
                        Text { text: "STATUS"; Layout.preferredWidth: 97; color: "#72879B"; font.pixelSize: 10; font.bold: true }
                        Text { text: "TIME"; Layout.preferredWidth: 110; color: "#72879B"; font.pixelSize: 10; font.bold: true }
                    }
                    ListView {
                        Layout.fillWidth: true; Layout.fillHeight: true
                        clip: true; spacing: 5
                        model: root.history
                        delegate: Rectangle {
                            required property var modelData
                            required property int index
                            width: ListView.view ? ListView.view.width : 700
                            height: 40; radius: 7
                            color: index % 2 === 0 ? "#1D2934" : "#18232D"
                            RowLayout {
                                anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 10; spacing: 10
                                Text { text: modelData.object; color: "#EAF2FA"; font.pixelSize: 11; Layout.fillWidth: true; elide: Text.ElideRight }
                                Text { text: modelData.stationId; color: "#94A8BD"; font.pixelSize: 11; width: 83 }
                                Text { text: modelData.material; color: "#B3C2D1"; font.pixelSize: 11; width: 87 }
                                Text { text: modelData.status; color: modelData.status === "Sorted" ? "#34D399" : "#FBBF24"; font.pixelSize: 11; width: 97 }
                                Text { text: modelData.time; color: "#8398AC"; font.pixelSize: 10; width: 110 }
                            }
                        }
                    }
                    Text { visible: root.history.length === 0; Layout.alignment: Qt.AlignHCenter; text: "No detections yet. Try the scanner."; color: "#8CA0B3"; font.pixelSize: 12 }
                }
            }
            Text { text: "SIMULATED STATISTICS · SEE SETTINGS TO RESET OR RESTORE DEMO DATA"; Layout.alignment: Qt.AlignHCenter; color: "#657A8F"; font.pixelSize: 10; font.bold: true }
        }
    }
}
