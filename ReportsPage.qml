import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts

Item {
    id: root
    property var stateData: ({})
    property string stationFilter: "all"
    property string period: "30d"
    readonly property var stations: stateData.stations || []
    readonly property var report: {
        // Explicitly depend on stateData so this refreshes after every backend commit.
        var snapshot = root.stateData
        return backend.reportSummary(root.stationFilter, root.period)
    }
    function pct(n, d) { return d > 0 ? Math.round(n * 100 / d) : 0 }

    FileDialog {
        id: exportDialog
        title: "Export FutureRecycle CSV report"
        fileMode: FileDialog.SaveFile
        nameFilters: ["CSV files (*.csv)"]
        defaultSuffix: "csv"
        onAccepted: backend.exportReport(selectedFile.toString(), root.stationFilter, root.period)
    }

    Flickable {
        anchors.fill: parent; clip: true
        contentHeight: pageContent.implicitHeight + 28
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
        ColumnLayout {
            id: pageContent
            width: parent.width - 16
            spacing: 18
            RowLayout {
                Layout.fillWidth: true
                Column {
                    spacing: 5
                    Text { text: "Reports & Sustainability"; font.pixelSize: 24; font.bold: true; color: "#F8FAFC" }
                    Text { text: "Operational summaries, station performance and CSV export"; font.pixelSize: 12; color: "#91A5BA" }
                }
                Item { Layout.fillWidth: true }
                ActionButton { text: "Export CSV"; implicitWidth: 137; onClicked: exportDialog.open() }
            }
            Rectangle {
                Layout.fillWidth: true; Layout.preferredHeight: 73
                radius: 13; color: "#161F29"; border.color: "#293644"
                RowLayout {
                    anchors.fill: parent; anchors.margins: 15; spacing: 12
                    Text { text: "Report scope"; color: "#9FB1C5"; font.pixelSize: 12 }
                    Item { Layout.fillWidth: true }
                    DarkCombo {
                        implicitWidth: 256
                        model: ["All stations"].concat(root.stations.map(function(s) { return s.id + " · " + s.name }))
                        onActivated: function(index) { root.stationFilter = index === 0 ? "all" : root.stations[index - 1].id }
                    }
                    DarkCombo {
                        implicitWidth: 155
                        model: ["Last 7 days", "Last 30 days", "All time"]
                        currentIndex: 1
                        onActivated: function(index) { root.period = ["7d", "30d", "all"][index] }
                    }
                }
            }
            Rectangle {
                Layout.fillWidth: true; Layout.preferredHeight: 84
                color: "#19372F"; border.color: "#266048"; radius: 13
                RowLayout {
                    anchors.fill: parent; anchors.margins: 18; spacing: 16
                    Text { text: "ⓘ"; font.pixelSize: 27; color: "#6EE7B7" }
                    Text {
                        Layout.fillWidth: true
                        text: "LIFETIME COUNTS are cumulative for each station. Period-based figures below count only recent recorded scan / collection / ticket events. Weight and CO₂ are not estimated because this demo has no scales or validated conversion data."
                        color: "#B5D9CA"; font.pixelSize: 11; wrapMode: Text.WordWrap
                    }
                }
            }
            GridLayout {
                Layout.fillWidth: true; columns: 4; columnSpacing: 12
                MetricCard { label: "LIFETIME SORTED"; amount: root.report.lifetimeItems.toLocaleString(); note: "Cumulative station counters"; accent: "#34D399" }
                MetricCard { label: "RECORDED SCANS"; amount: (root.report.sortedScans + root.report.manualReviews).toString(); note: "Selected reporting period"; accent: "#60A5FA" }
                MetricCard { label: "COMPLETED PICKUPS"; amount: root.report.completedPickups.toString(); note: "Selected reporting period"; accent: "#A78BFA" }
                MetricCard { label: "RESOLVED TICKETS"; amount: root.report.resolvedTickets.toString(); note: "Selected reporting period"; accent: "#FBBF24" }
            }
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: Math.max(160, 85 + root.report.rows.length * 62)
                radius: 15; color: "#161F29"; border.color: "#293644"
                ColumnLayout {
                    anchors.fill: parent; anchors.margins: 19; spacing: 11
                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: "Station Performance"; color: "#F8FAFC"; font.pixelSize: 17; font.bold: true }
                        Item { Layout.fillWidth: true }
                        Text { text: root.report.stationCount + " stations"; color: "#8397AA"; font.pixelSize: 11 }
                    }
                    RowLayout {
                        Layout.fillWidth: true; spacing: 8
                        Text { Layout.preferredWidth: 170; text: "STATION"; color: "#7E90A6"; font.pixelSize: 10; font.bold: true }
                        Text { Layout.fillWidth: true; text: "LIFETIME ITEMS"; color: "#7E90A6"; font.pixelSize: 10; font.bold: true; horizontalAlignment: Text.AlignRight }
                        Text { Layout.preferredWidth: 110; text: "PERIOD SCANS"; color: "#7E90A6"; font.pixelSize: 10; font.bold: true; horizontalAlignment: Text.AlignRight }
                        Text { Layout.preferredWidth: 85; text: "PICKUPS"; color: "#7E90A6"; font.pixelSize: 10; font.bold: true; horizontalAlignment: Text.AlignRight }
                        Text { Layout.preferredWidth: 85; text: "TICKETS"; color: "#7E90A6"; font.pixelSize: 10; font.bold: true; horizontalAlignment: Text.AlignRight }
                    }
                    Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: "#2D3D4D" }
                    Repeater {
                        model: root.report.rows
                        delegate: RowLayout {
                            id: reportRow
                            required property var modelData
                            Layout.fillWidth: true; Layout.preferredHeight: 43; spacing: 8
                            ColumnLayout {
                                Layout.preferredWidth: 170; spacing: 2
                                Text { text: reportRow.modelData.name; color: "#EAF2F9"; font.pixelSize: 12; font.bold: true; Layout.fillWidth: true; elide: Text.ElideRight }
                                Text { text: reportRow.modelData.stationId; color: "#71869C"; font.pixelSize: 10 }
                            }
                            Text { Layout.fillWidth: true; text: reportRow.modelData.total.toLocaleString(); color: "#6EE7B7"; font.pixelSize: 13; font.bold: true; horizontalAlignment: Text.AlignRight }
                            Text { Layout.preferredWidth: 110; text: (reportRow.modelData.sortedScans + reportRow.modelData.manualReviews).toString(); color: "#D9E6F0"; font.pixelSize: 12; horizontalAlignment: Text.AlignRight }
                            Text { Layout.preferredWidth: 85; text: reportRow.modelData.completedPickups.toString(); color: "#D9E6F0"; font.pixelSize: 12; horizontalAlignment: Text.AlignRight }
                            Text { Layout.preferredWidth: 85; text: reportRow.modelData.resolvedTickets.toString(); color: "#D9E6F0"; font.pixelSize: 12; horizontalAlignment: Text.AlignRight }
                        }
                    }
                    Item { Layout.fillHeight: true }
                }
            }
            Rectangle {
                Layout.fillWidth: true; Layout.preferredHeight: 130
                radius: 14; color: "#161F29"; border.color: "#293644"
                ColumnLayout {
                    anchors.fill: parent; anchors.margins: 20; spacing: 9
                    Text { text: "What the CSV contains"; color: "#F8FAFC"; font.pixelSize: 16; font.bold: true }
                    Text { Layout.fillWidth: true; wrapMode: Text.WordWrap; text: "One row per selected station: lifetime material counts, current bin levels and period-filtered counts of sorted scans, manual reviews, completed pickups and resolved maintenance tickets."; color: "#9EAFBF"; font.pixelSize: 12 }
                    Text { text: "Everything is fictional demo data. No PDF service, email delivery or live ERP integration."; color: "#71869C"; font.pixelSize: 11 }
                }
            }
            Text { text: "DEMONSTRATION REPORT · NOT A CERTIFIED ENVIRONMENTAL ASSESSMENT"; Layout.alignment: Qt.AlignHCenter; color: "#60768B"; font.pixelSize: 10; font.bold: true }
        }
    }
}
