import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts

Item {
    id: root
    property var stateData: ({})
    property url selectedImage: ""
    property bool scanning: false
    property bool hasResult: false
    property var result: ({})
    property string scanStationId: ""

    readonly property var stations: stateData.stations || []
    readonly property var chosenStation: {
        for (var i = 0; i < stations.length; i++)
            if (stations[i].id === stateData.selectedStationId) return stations[i]
        return null
    }
    readonly property bool ready: chosenStation !== null && chosenStation.status === "Online"

    FileDialog {
        id: imageDialog
        title: "Choose an image of waste"
        fileMode: FileDialog.OpenFile
        nameFilters: ["Image files (*.png *.jpg *.jpeg *.webp *.bmp)"]
        onAccepted: {
            root.selectedImage = selectedFile
            root.hasResult = false
            root.result = ({})
        }
    }

    Timer {
        id: scanTimer
        interval: root.stateData.settings ? root.stateData.settings.scanDuration : 2000
        repeat: false
        onTriggered: {
            root.scanning = false
            root.result = backend.scanFileAtStation(root.selectedImage.toString(), root.scanStationId)
            root.hasResult = true
        }
    }

    Flickable {
        anchors.fill: parent
        clip: true
        contentHeight: pageContent.implicitHeight + 32
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

        ColumnLayout {
            id: pageContent
            width: parent.width - 16
            spacing: 18

            RowLayout {
                Layout.fillWidth: true
                Column {
                    spacing: 6
                    Text { text: "Intelligent Waste Scanner"; color: "#F8FAFC"; font.pixelSize: 24; font.bold: true }
                    Text { text: "Upload an image and simulate classification at a selected station"; color: "#9BACBF"; font.pixelSize: 12 }
                }
                Item { Layout.fillWidth: true }
                Rectangle {
                    width: 143; height: 34; radius: 17
                    color: "#173B30"
                    Text { anchors.centerIn: parent; text: "● SIMULATED AI"; color: "#6EE7B7"; font.pixelSize: 10; font.bold: true }
                }
            }

            Rectangle {
                Layout.fillWidth: true; Layout.preferredHeight: 74
                radius: 13; color: "#161F29"; border.color: "#293644"
                RowLayout {
                    anchors.fill: parent; anchors.margins: 15; spacing: 16
                    Column {
                        spacing: 5
                        Text { text: "TARGET STATION"; color: "#8FA2B6"; font.pixelSize: 10; font.bold: true }
                        Text { text: "Scans update this station only"; color: "#657A8D"; font.pixelSize: 11 }
                    }
                    Item { Layout.fillWidth: true }
                    ComboBox {
                        id: stationCombo
                        enabled: !root.scanning && root.stations.length > 0
                        implicitWidth: 265; implicitHeight: 42
                        model: root.stations.map(function(s) { return s.id + "  ·  " + s.name })
                        currentIndex: {
                            for (var i = 0; i < root.stations.length; i++)
                                if (root.stations[i].id === root.stateData.selectedStationId) return i
                            return -1
                        }
                        onActivated: function(index) { backend.selectStation(root.stations[index].id); root.hasResult = false }
                        background: Rectangle { color: "#22313F"; border.color: "#42546A"; radius: 9 }
                        contentItem: Text {
                            leftPadding: 14; rightPadding: 22
                            text: stationCombo.displayText
                            color: "#F1F5F9"; font.pixelSize: 12
                            verticalAlignment: Text.AlignVCenter
                            elide: Text.ElideRight
                        }
                    }
                }
            }

            Rectangle {
                id: previewFrame
                Layout.fillWidth: true; Layout.preferredHeight: 330
                radius: 15; color: "#111820"
                border.color: root.scanning ? "#34D399" : "#304052"
                clip: true

                Image {
                    id: previewImage
                    anchors.fill: parent
                    anchors.margins: 14
                    source: root.selectedImage
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                    visible: root.selectedImage.toString() !== ""
                }
                Column {
                    anchors.centerIn: parent
                    spacing: 12
                    visible: root.selectedImage.toString() === ""
                    Text { text: "◎"; font.pixelSize: 67; color: "#34D399"; anchors.horizontalCenter: parent.horizontalCenter }
                    Text { text: "No image selected"; font.pixelSize: 19; font.bold: true; color: "#F8FAFC"; anchors.horizontalCenter: parent.horizontalCenter }
                    Text { text: "Upload a bottle, a paper sheet or an aluminum can"; font.pixelSize: 12; color: "#879AAF"; anchors.horizontalCenter: parent.horizontalCenter }
                }
                Rectangle {
                    x: 17; y: 17; width: 141; height: 30
                    radius: 7; color: "#E3111820"
                    visible: root.selectedImage.toString() !== ""
                    Text {
                        anchors.centerIn: parent
                        text: root.scanning ? "● SCANNING" : root.hasResult ? "● SCAN COMPLETE" : "● IMAGE READY"
                        color: root.scanning ? "#6EE7B7" : "#CEDAE5"
                        font.pixelSize: 10; font.bold: true
                    }
                }
                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width * 0.52
                    height: parent.height * 0.68
                    color: "transparent"; radius: 6
                    border.color: root.result.material === "Paper" ? "#60A5FA" : root.result.material === "Metal" ? "#A78BFA" : "#10B981"
                    border.width: 2
                    visible: root.hasResult && root.result.status === "Sorted"
                    Rectangle {
                        anchors.left: parent.left
                        anchors.bottom: parent.top
                        anchors.bottomMargin: 6
                        width: simulatedLabel.implicitWidth + 20; height: 25; radius: 5
                        color: "#10B981"
                        Text { id: simulatedLabel; anchors.centerIn: parent; text: "DEMO REGION · " + (root.result.object || ""); color: "#072117"; font.pixelSize: 10; font.bold: true }
                    }
                }
                Rectangle {
                    id: scanLine
                    x: 12; y: 14; width: parent.width - 24; height: 3; radius: 1
                    color: "#34D399"
                    visible: root.scanning
                    SequentialAnimation on y {
                        running: root.scanning
                        loops: Animation.Infinite
                        NumberAnimation { from: 14; to: previewFrame.height - 16; duration: 840; easing.type: Easing.InOutSine }
                        NumberAnimation { from: previewFrame.height - 16; to: 14; duration: 840; easing.type: Easing.InOutSine }
                    }
                }
                Rectangle {
                    anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.right: parent.right
                    height: 43; color: "#EA111820"; visible: root.scanning
                    Text { anchors.centerIn: parent; text: "SIMULATING IMAGE ANALYSIS..."; color: "#6EE7B7"; font.pixelSize: 12; font.bold: true; font.letterSpacing: 1.1 }
                }
            }

            RowLayout {
                Layout.fillWidth: true; spacing: 13
                Button {
                    Layout.fillWidth: true; implicitHeight: 49
                    text: root.selectedImage.toString() ? "Change Image" : "Upload Image"
                    enabled: !root.scanning
                    onClicked: imageDialog.open()
                    background: Rectangle { radius: 9; color: parent.hovered ? "#2A3B4D" : "#202D3A"; border.color: "#40536A" }
                    contentItem: Text { text: parent.text; color: "#E2E8F0"; font.pixelSize: 13; font.bold: true; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                }
                Button {
                    Layout.fillWidth: true; implicitHeight: 49
                    text: root.scanning ? "Scanning..." : "Start Detection"
                    enabled: !root.scanning && root.ready && root.selectedImage.toString() !== ""
                    onClicked: {
                        root.result = ({})
                        root.hasResult = false
                        root.scanning = true
                        root.scanStationId = root.stateData.selectedStationId
                        scanTimer.start()
                    }
                    background: Rectangle { radius: 9; color: parent.enabled ? (parent.hovered ? "#34D399" : "#10B981") : "#305647" }
                    contentItem: Text { text: parent.text; color: "#072117"; font.pixelSize: 13; font.bold: true; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                }
            }

            Text {
                visible: !root.ready
                text: "⚠ This station is offline or in maintenance. Select an online station to scan."
                color: "#FBBF24"; font.pixelSize: 12; wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }

            Rectangle {
                Layout.fillWidth: true; Layout.preferredHeight: 195
                color: "#161F29"; border.color: "#304052"; radius: 14
                visible: root.hasResult
                ColumnLayout {
                    anchors.fill: parent; anchors.margins: 19; spacing: 12
                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: "DETECTION RESULT"; color: "#93A6B9"; font.pixelSize: 11; font.bold: true; font.letterSpacing: 1 }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: root.result.status === "Sorted" ? "● SORTED" : "● " + (root.result.status || "REVIEW").toUpperCase()
                            color: root.result.status === "Sorted" ? "#34D399" : "#FBBF24"
                            font.pixelSize: 11; font.bold: true
                        }
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: root.result.object || ""; color: "#F8FAFC"; font.pixelSize: 22; font.bold: true; Layout.fillWidth: true; elide: Text.ElideRight }
                        Text { text: root.result.confidence > 0 ? root.result.confidence.toFixed(1) + "%" : "N/A"; color: "#71E7B0"; font.pixelSize: 17; font.bold: true }
                    }
                    Rectangle {
                        Layout.fillWidth: true; Layout.preferredHeight: 8; radius: 4; color: "#2A3847"
                        Rectangle { height: parent.height; width: parent.width * (root.result.confidence || 0) / 100; radius: 4; color: "#10B981"; Behavior on width { NumberAnimation { duration: 500 } } }
                    }
                    Rectangle {
                        Layout.fillWidth: true; Layout.preferredHeight: 47; radius: 8; color: "#202D3A"
                        RowLayout {
                            anchors.fill: parent; anchors.margins: 12
                            Text { text: "Sorting destination"; color: "#91A2B5"; font.pixelSize: 12 }
                            Item { Layout.fillWidth: true }
                            Text { text: root.result.destination || ""; color: root.result.status === "Sorted" ? "#6EE7B7" : "#FBBF24"; font.pixelSize: 12; font.bold: true }
                        }
                    }
                }
            }
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "DEMO ONLY · FILENAME KEYWORDS · NO IMAGE CONTENT ANALYSIS · BOX IS DECORATIVE"
                color: "#6C8095"; font.pixelSize: 10; font.bold: true
            }
        }
    }
}
