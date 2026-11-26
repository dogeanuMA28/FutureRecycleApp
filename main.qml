import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ApplicationWindow {
    id: appWindow
    visible: true
    width: 1570
    height: 950
    minimumWidth: 1160
    minimumHeight: 760
    title: "FutureRecycle — Customer Operations Dashboard"
    color: "#0B0F14"
    font.family: "Noto Sans"

    // Eight primary tabs; related functions live in sub-tabs.
    // 0 Overview, 1 Stations, 2 Collections, 3 Alerts, 4 Maintenance,
    // 5 Analytics & Reports, 6 AI Detection, 7 Settings
    property int pageIndex: 0
    property var stateData: backend.state
    readonly property var stationList: stateData.stations || []
    readonly property string selectedStationId: stateData.selectedStationId || ""
    readonly property var networkAlerts: stateData.alerts || []
    readonly property int needsAttention: networkAlerts.filter(function(a) { return !a.acknowledged }).length

    function goToStation(id) {
        stationsWorkspace.openStation(id)
        pageIndex = 1
    }
    function requestCollection(id, material) {
        collectionsWorkspace.openRequest(id, material)
        pageIndex = 2
    }
    function requestMaintenance(id) {
        pageIndex = 4
        maintenancePage.openTicket(id)
    }
    function goToCalendar(jobId) {
        collectionsWorkspace.openCalendar(jobId || "")
        pageIndex = 2
    }
    function goToAnalytics() {
        insightsWorkspace.showAnalytics()
        pageIndex = 5
    }
    function goToActivity() {
        insightsWorkspace.showActivity()
        pageIndex = 5
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0
        Rectangle {
            Layout.preferredWidth: 244
            Layout.fillHeight: true
            color: "#111820"
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 15
                spacing: 4
                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: 10
                    Layout.bottomMargin: 12
                    spacing: 10
                    Rectangle {
                        width: 42; height: 42; radius: 12; color: "#10B981"
                        Text { anchors.centerIn: parent; text: "F"; color: "#062217"; font.pixelSize: 27; font.bold: true }
                    }
                    Column {
                        spacing: 4
                        Text { text: "FutureRecycle"; color: "#F8FAFC"; font.pixelSize: 17; font.bold: true }
                        Text { text: "CUSTOMER OPERATIONS"; color: "#72859A"; font.pixelSize: 9; font.letterSpacing: 1.1 }
                    }
                }
                Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: "#263340"; Layout.bottomMargin: 4 }
                Flickable {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    contentHeight: navigation.implicitHeight + 12
                    ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
                    ColumnLayout {
                        id: navigation
                        width: parent.width - 8
                        spacing: 3
                        Text { text: "WORKSPACE"; color: "#64748B"; font.pixelSize: 10; font.bold: true; font.letterSpacing: 1.6; Layout.leftMargin: 12; Layout.bottomMargin: 5; Layout.topMargin: 6 }
                        NavItem { label: "Overview"; iconName: "overview"; active: appWindow.pageIndex === 0; onActivated: appWindow.pageIndex = 0 }
                        NavItem { label: "Stations"; iconName: "stations"; active: appWindow.pageIndex === 1; onActivated: appWindow.pageIndex = 1 }
                        NavItem { label: "Collections"; iconName: "collections"; active: appWindow.pageIndex === 2; onActivated: appWindow.pageIndex = 2 }
                        NavItem { label: "Alerts"; iconName: "alerts"; active: appWindow.pageIndex === 3; alertCount: appWindow.needsAttention; onActivated: appWindow.pageIndex = 3 }
                        NavItem { label: "Maintenance"; iconName: "maintenance"; active: appWindow.pageIndex === 4; onActivated: appWindow.pageIndex = 4 }
                        Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: "#263340"; Layout.topMargin: 9; Layout.bottomMargin: 7 }
                        Text { text: "INSIGHTS & TOOLS"; color: "#64748B"; font.pixelSize: 10; font.bold: true; font.letterSpacing: 1.6; Layout.leftMargin: 12; Layout.bottomMargin: 5 }
                        NavItem { label: "Analytics & Reports"; iconName: "analytics"; active: appWindow.pageIndex === 5; onActivated: appWindow.pageIndex = 5 }
                        NavItem { label: "AI Detection"; iconName: "scan"; active: appWindow.pageIndex === 6; onActivated: appWindow.pageIndex = 6 }
                        NavItem { label: "Settings"; iconName: "settings"; active: appWindow.pageIndex === 7; onActivated: appWindow.pageIndex = 7 }
                    }
                }
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 83
                    radius: 12
                    color: "#1A2831"
                    border.color: "#263B41"
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 6
                        RowLayout {
                            spacing: 8
                            Rectangle { width: 8; height: 8; radius: 4; color: "#34D399" }
                            Text { text: "Local Simulation"; color: "#E2E8F0"; font.pixelSize: 12; font.bold: true }
                        }
                        Text { text: appWindow.stationList.length + " registered stations"; color: "#A6B5C5"; font.pixelSize: 11 }
                        Text { text: "No physical devices linked"; color: "#718396"; font.pixelSize: 10 }
                    }
                }
                Text { Layout.alignment: Qt.AlignHCenter; Layout.topMargin: 4; text: "FutureRecycle v1.4 · Demo"; color: "#526477"; font.pixelSize: 10 }
            }
        }
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.leftMargin: 26
            Layout.rightMargin: 26
            Layout.topMargin: 22
            Layout.bottomMargin: 18
            spacing: 16
            RowLayout {
                Layout.fillWidth: true
                spacing: 12
                Column {
                    spacing: 5
                    Text {
                        text: ["Overview", "Stations", "Collections", "Alerts", "Maintenance", "Analytics & Reports", "AI Detection · Demo", "Settings"][appWindow.pageIndex]
                        color: "#F8FAFC"
                        font.pixelSize: 26
                        font.bold: true
                    }
                    Text { text: "Smart recycling · Station operations · Customer workspace"; color: "#94A3B8"; font.pixelSize: 12 }
                }
                Item { Layout.fillWidth: true }
                Rectangle {
                    width: 112; height: 31; radius: 16; color: "#173B30"
                    Text { anchors.centerIn: parent; text: "● DEMO DATA"; color: "#62DDAE"; font.pixelSize: 10; font.bold: true }
                }
                Rectangle { width: 1; height: 25; color: "#273543" }
                Text { text: appWindow.selectedStationId; color: "#A6B6C9"; font.pixelSize: 12; font.bold: true }
            }
            StackLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                currentIndex: appWindow.pageIndex
                OverviewPage {
                    stateData: appWindow.stateData
                    onScanRequested: appWindow.pageIndex = 6
                    onStationRequested: function(id) { appWindow.goToStation(id) }
                    onAnalyticsRequested: appWindow.goToAnalytics()
                    onActivityRequested: appWindow.goToActivity()
                    onAlertsRequested: appWindow.pageIndex = 3
                    onCollectionsRequested: appWindow.pageIndex = 2
                }
                StationsWorkspace {
                    id: stationsWorkspace
                    stateData: appWindow.stateData
                    onCollectionRequested: function(id, material) { appWindow.requestCollection(id, material) }
                    onMaintenanceRequested: function(id) { appWindow.requestMaintenance(id) }
                }
                CollectionsWorkspace { id: collectionsWorkspace; stateData: appWindow.stateData }
                AlertsPage {
                    stateData: appWindow.stateData
                    onCollectionRequested: function(id, material) { appWindow.requestCollection(id, material) }
                    onStationRequested: function(id) { appWindow.goToStation(id) }
                    onMaintenanceRequested: appWindow.pageIndex = 4
                }
                MaintenancePage { id: maintenancePage; stateData: appWindow.stateData }
                InsightsWorkspace { id: insightsWorkspace; stateData: appWindow.stateData }
                ScannerPage { stateData: appWindow.stateData }
                SettingsPage { stateData: appWindow.stateData }
            }
        }
    }
    Rectangle {
        id: toast
        width: Math.min(appWindow.width - 60, toastText.implicitWidth + 54)
        height: 47
        radius: 12
        color: "#20382F"
        border.color: "#2E7357"
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 24
        opacity: 0
        visible: opacity > 0
        z: 100
        Text { id: toastText; anchors.centerIn: parent; text: ""; color: "#E1F8EC"; font.pixelSize: 12; font.bold: true }
        Behavior on opacity { NumberAnimation { duration: 150 } }
    }
    Timer { id: toastTimer; interval: 3300; onTriggered: toast.opacity = 0 }
    Connections {
        target: backend
        function onNotice(message) {
            toastText.text = message
            toast.opacity = 1
            toastTimer.restart()
        }
    }
}
