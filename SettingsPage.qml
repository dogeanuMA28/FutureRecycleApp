import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    property var stateData: ({})
    property string pendingScenario: "Normal"
    function chooseScenario(name) { pendingScenario = name; scenarioConfirm.open() }
    readonly property var settings: stateData.settings || ({scanDuration: 2000, confidenceThreshold: 95})

    Flickable {
        anchors.fill: parent
        clip: true
        contentHeight: pageContent.implicitHeight + 30
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
        ColumnLayout {
            id: pageContent
            width: parent.width - 16
            spacing: 18

            RowLayout {
                Layout.fillWidth: true
                Column {
                    spacing: 6
                    Text { text: "System Settings"; color: "#F8FAFC"; font.pixelSize: 24; font.bold: true }
                    Text { text: "Configure the local demonstration and presentation data"; color: "#91A5BA"; font.pixelSize: 12 }
                }
                Item { Layout.fillWidth: true }
                Rectangle {
                    width: 105; height: 33; radius: 17; color: "#173B30"
                    Text { anchors.centerIn: parent; text: "● DEMO"; color: "#6EE7B7"; font.pixelSize: 10; font.bold: true }
                }
            }

            Rectangle {
                Layout.fillWidth: true; Layout.preferredHeight: 280
                radius: 15; color: "#161F29"; border.color: "#293644"
                ColumnLayout {
                    anchors.fill: parent; anchors.margins: 24; spacing: 17
                    Text { text: "Detection Engine"; color: "#F8FAFC"; font.pixelSize: 19; font.bold: true }
                    Text { text: "Filename-based simulated recognition · not computer vision"; color: "#91A5BA"; font.pixelSize: 12 }
                    Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: "#334155" }
                    RowLayout {
                        Layout.fillWidth: true
                        Column {
                            spacing: 5
                            Text { text: "Scan Animation Speed"; color: "#E4ECF4"; font.pixelSize: 14; font.bold: true }
                            Text { text: "Controls how long the simulated scan takes"; color: "#91A3B7"; font.pixelSize: 11 }
                        }
                        Item { Layout.fillWidth: true }
                        ComboBox {
                            id: speedChoice
                            implicitWidth: 210; implicitHeight: 40
                            model: ["Fast (0.8s)", "Normal (2s)", "Presentation (3.5s)"]
                            currentIndex: Math.max(0, [800, 2000, 3500].indexOf(root.settings.scanDuration))
                            onActivated: function(index) { backend.setScanDuration([800, 2000, 3500][index]) }
                            background: Rectangle { color: "#263746"; radius: 9; border.color: "#45596B" }
                            contentItem: Text { text: speedChoice.displayText; leftPadding: 13; color: "#EAF2FA"; font.pixelSize: 12; verticalAlignment: Text.AlignVCenter }
                        }
                    }
                    Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: "#334155" }
                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: "Confidence Threshold"; color: "#E4ECF4"; font.pixelSize: 14; font.bold: true }
                        Item { Layout.fillWidth: true }
                        Text { text: root.settings.confidenceThreshold + "%"; color: "#6EE7B7"; font.pixelSize: 17; font.bold: true }
                    }
                    Slider {
                        Layout.fillWidth: true; from: 90; to: 99; stepSize: 1
                        value: root.settings.confidenceThreshold
                        onMoved: backend.setConfidenceThreshold(Math.round(value))
                    }
                    Text {
                        Layout.fillWidth: true
                        text: "Low-confidence results are sent to Manual Review instead of increasing station counters."
                        color: "#91A3B7"; font.pixelSize: 11; wrapMode: Text.WordWrap
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true; Layout.preferredHeight: 168
                radius: 15; color: "#161F29"; border.color: "#293644"
                ColumnLayout {
                    anchors.fill: parent; anchors.margins: 24; spacing: 15
                    Text { text: "Station Maintenance"; color: "#F8FAFC"; font.pixelSize: 19; font.bold: true }
                    Text { text: "Empty every virtual container across all registered stations."; color: "#91A5BA"; font.pixelSize: 12 }
                    Button {
                        implicitWidth: 225; implicitHeight: 43
                        text: "Empty All Containers"
                        onClicked: backend.emptyAllStations()
                        background: Rectangle { color: parent.hovered ? "#31465A" : "#243545"; radius: 9; border.color: "#475C70" }
                        contentItem: Text { text: parent.text; color: "#F0F4FA"; font.pixelSize: 12; font.bold: true; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true; Layout.preferredHeight: 253
                radius: 15; color: "#161F29"; border.color: "#293644"
                ColumnLayout {
                    anchors.fill: parent; anchors.margins: 23; spacing: 13
                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: "Presentation Scenarios"; color: "#F8FAFC"; font.pixelSize: 19; font.bold: true }
                        Item { Layout.fillWidth: true }
                        Text { text: "LAST APPLIED: " + (root.stateData.lastScenario || "Starter Dataset").toUpperCase(); color: "#34D399"; font.pixelSize: 10; font.bold: true }
                    }
                    Text {
                        Layout.fillWidth: true
                        text: "Demonstrate a station network changing from normal operations to capacity problems, a critical outage, or service recovery."
                        color: "#97ADBF"; font.pixelSize: 12; wrapMode: Text.WordWrap
                    }
                    GridLayout {
                        Layout.fillWidth: true; columns: 2; rowSpacing: 11; columnSpacing: 11
                        ActionButton { Layout.fillWidth: true; implicitHeight: 40; text: "✓ Normal Operation"; tone: "neutral"; onClicked: root.chooseScenario("Normal") }
                        ActionButton { Layout.fillWidth: true; implicitHeight: 40; text: "◉ Busy Day"; tone: "warning"; onClicked: root.chooseScenario("Busy") }
                        ActionButton { Layout.fillWidth: true; implicitHeight: 40; text: "! Critical Incident"; tone: "danger"; onClicked: root.chooseScenario("Critical") }
                        ActionButton { Layout.fillWidth: true; implicitHeight: 40; text: "↻ Service Recovery"; onClicked: root.chooseScenario("Recovery") }
                    }
                    Text {
                        Layout.fillWidth: true
                        text: "Scenario presets replace simulated fill levels and availability; they may close pending jobs and tickets. Existing station locations and lifetime counts stay intact."
                        color: "#71869B"; font.pixelSize: 11; wrapMode: Text.WordWrap
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true; Layout.preferredHeight: 216
                radius: 15; color: "#161F29"; border.color: "#293644"
                ColumnLayout {
                    anchors.fill: parent; anchors.margins: 24; spacing: 15
                    Text { text: "Presentation Data"; color: "#F8FAFC"; font.pixelSize: 19; font.bold: true }
                    Text { text: "Reset your counts or restore the three fictional sample stations."; color: "#91A5BA"; font.pixelSize: 12 }
                    RowLayout {
                        Layout.fillWidth: true; spacing: 12
                        Button {
                            Layout.fillWidth: true; implicitHeight: 46
                            text: "Restore Demo Network"
                            onClicked: demoDialog.open()
                            background: Rectangle { color: parent.hovered ? "#205D46" : "#174333"; radius: 9; border.color: "#10B981" }
                            contentItem: Text { text: parent.text; color: "#6EE7B7"; font.pixelSize: 13; font.bold: true; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                        }
                        Button {
                            Layout.fillWidth: true; implicitHeight: 46
                            text: "Reset Statistics"
                            onClicked: resetDialog.open()
                            background: Rectangle { color: parent.hovered ? "#553039" : "#36262D"; radius: 9; border.color: "#9B4C60" }
                            contentItem: Text { text: parent.text; color: "#FDA4AF"; font.pixelSize: 13; font.bold: true; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                        }
                    }
                    Text { text: "All changes are automatically saved to your local JSON state file."; color: "#72869B"; font.pixelSize: 11 }
                }
            }

            Rectangle {
                Layout.fillWidth: true; Layout.preferredHeight: 123
                radius: 15; color: "#161F29"; border.color: "#293644"
                ColumnLayout {
                    anchors.fill: parent; anchors.margins: 22; spacing: 10
                    Text { text: "About FutureRecycle"; color: "#F8FAFC"; font.pixelSize: 18; font.bold: true }
                    Text { text: "FutureRecycle Control Center · University Demo v1.2"; color: "#C6D5E4"; font.pixelSize: 12 }
                    Text { text: "No real AI model, live sensors or production services are connected."; color: "#91A5BA"; font.pixelSize: 12 }
                }
            }
        }
    }

    Dialog {
        id: scenarioConfirm
        anchors.centerIn: parent; modal: true
        title: "Apply " + root.pendingScenario + " scenario?"
        standardButtons: Dialog.Yes | Dialog.No
        onAccepted: backend.applyScenario(root.pendingScenario)
        contentItem: Text {
            width: 360
            text: "This changes simulated station levels, status, and possibly existing open jobs/tickets. It does not affect real equipment. The change is saved to the local demo data file."
            color: "#E2EBF4"; wrapMode: Text.WordWrap
        }
        background: Rectangle { color: "#1A2B38"; radius: 14; border.color: "#42586B" }
    }
    Dialog {
        id: resetDialog
        anchors.centerIn: parent
        modal: true
        title: "Reset all statistics?"
        standardButtons: Dialog.Yes | Dialog.No
        onAccepted: backend.resetStatistics()
        contentItem: Text {
            width: 350
            text: "Clears station counts, bins, scan history, collection requests, maintenance tickets, alerts and the activity log. Stations remain registered."
            color: "#E2EBF4"; wrapMode: Text.WordWrap
        }
        background: Rectangle { color: "#1A2B38"; radius: 14; border.color: "#42586B" }
    }
    Dialog {
        id: demoDialog
        anchors.centerIn: parent
        modal: true
        title: "Restore the demo network?"
        standardButtons: Dialog.Yes | Dialog.No
        onAccepted: backend.restoreDemo()
        contentItem: Text {
            width: 350
            text: "Replaces the entire network, operations records and history with three sample stations, collection jobs and tickets. Simulation settings stay unchanged."
            color: "#E2EBF4"; wrapMode: Text.WordWrap
        }
        background: Rectangle { color: "#1A2B38"; radius: 14; border.color: "#42586B" }
    }
}
