import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ApplicationWindow {
    id: appWindow
    visible: true
    width: 1570; height: 950
    minimumWidth: 1160; minimumHeight: 760
    title: "FutureRecycle — Operations & Intelligence · Romania Map"
    color: "#0B0F14"
    font.family: "Noto Sans"

    property int pageIndex: 0
    property var stateData: backend.state
    readonly property var stationList: stateData.stations || []
    readonly property string selectedStationId: stateData.selectedStationId || ""
    readonly property var networkAlerts: stateData.alerts || []
    readonly property int needsAttention: networkAlerts.filter(function(a){return !a.acknowledged}).length

    function goToStation(id) { backend.selectStation(id); pageIndex = 1 }
    function requestCollection(id, material) { pageIndex = 3; collectionPage.openRequest(id, material) }
    function requestMaintenance(id) { pageIndex = 6; maintenancePage.openTicket(id) }
    function goToCalendar(jobId) { pageIndex = 4; calendarPage.focusJob(jobId || "") }

    RowLayout {
        anchors.fill: parent; spacing: 0
        Rectangle {
            Layout.preferredWidth: 244; Layout.fillHeight: true
            color: "#111820"
            ColumnLayout {
                anchors.fill: parent; anchors.margins: 15; spacing: 4
                RowLayout {
                    Layout.fillWidth: true; Layout.topMargin: 10; Layout.bottomMargin: 12; spacing: 10
                    Rectangle {
                        width: 42; height: 42; radius: 12; color: "#10B981"
                        Text { anchors.centerIn: parent; text: "F"; color: "#062217"; font.pixelSize: 27; font.bold: true }
                    }
                    Column {
                        spacing: 4
                        Text { text: "FutureRecycle"; color: "#F8FAFC"; font.pixelSize: 17; font.bold: true }
                        Text { text: "OPERATIONS + INTELLIGENCE"; color: "#72859A"; font.pixelSize: 8; font.letterSpacing: 1.1 }
                    }
                }
                Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: "#263340"; Layout.bottomMargin: 4 }
                Flickable {
                    Layout.fillWidth: true; Layout.fillHeight: true; clip: true
                    contentHeight: navigation.implicitHeight + 12
                    ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
                    ColumnLayout {
                        id: navigation; width: parent.width - 8; spacing: 3
                        Text { text: "WORKSPACE"; color: "#64748B"; font.pixelSize: 10; font.bold: true; font.letterSpacing: 1.6; Layout.leftMargin: 12; Layout.bottomMargin: 5; Layout.topMargin: 6 }
                        NavItem { label: "Overview"; iconName: "overview"; active: appWindow.pageIndex === 0; onActivated: appWindow.pageIndex = 0 }
                        NavItem { label: "Smart Stations"; iconName: "stations"; active: appWindow.pageIndex === 1; onActivated: appWindow.pageIndex = 1 }
                        NavItem { label: "Station Map"; iconName: "map"; active: appWindow.pageIndex === 2; onActivated: appWindow.pageIndex = 2 }
                        NavItem { label: "Collections"; iconName: "collections"; active: appWindow.pageIndex === 3; onActivated: appWindow.pageIndex = 3 }
                        NavItem { label: "Pickup Calendar"; iconName: "calendar"; active: appWindow.pageIndex === 4; onActivated: appWindow.pageIndex = 4 }
                        NavItem { label: "Alerts"; iconName: "alerts"; active: appWindow.pageIndex === 5; alertCount: appWindow.needsAttention; onActivated: appWindow.pageIndex = 5 }
                        NavItem { label: "Maintenance"; iconName: "maintenance"; active: appWindow.pageIndex === 6; onActivated: appWindow.pageIndex = 6 }
                        Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: "#263340"; Layout.topMargin: 9; Layout.bottomMargin: 7 }
                        Text { text: "INSIGHTS"; color: "#64748B"; font.pixelSize: 10; font.bold: true; font.letterSpacing: 1.6; Layout.leftMargin: 12; Layout.bottomMargin: 5 }
                        NavItem { label: "Analytics"; iconName: "analytics"; active: appWindow.pageIndex === 7; onActivated: appWindow.pageIndex = 7 }
                        NavItem { label: "Fill Forecasts"; iconName: "forecast"; active: appWindow.pageIndex === 8; onActivated: appWindow.pageIndex = 8 }
                        NavItem { label: "Reports"; iconName: "reports"; active: appWindow.pageIndex === 9; onActivated: appWindow.pageIndex = 9 }
                        NavItem { label: "Activity History"; iconName: "activity"; active: appWindow.pageIndex === 10; onActivated: appWindow.pageIndex = 10 }
                        NavItem { label: "AI Detection"; iconName: "scan"; active: appWindow.pageIndex === 11; onActivated: appWindow.pageIndex = 11 }
                        NavItem { label: "Settings"; iconName: "settings"; active: appWindow.pageIndex === 12; onActivated: appWindow.pageIndex = 12 }
                    }
                }
                Rectangle {
                    Layout.fillWidth: true; Layout.preferredHeight: 83
                    radius: 12; color: "#1A2831"; border.color: "#263B41"
                    ColumnLayout {
                        anchors.fill: parent; anchors.margins: 12; spacing: 6
                        RowLayout {
                            spacing: 8
                            Rectangle { width: 8; height: 8; radius: 4; color: "#34D399" }
                            Text { text: "Local Simulation"; color: "#E2E8F0"; font.pixelSize: 12; font.bold: true }
                        }
                        Text { text: appWindow.stationList.length + " registered stations"; color: "#A6B5C5"; font.pixelSize: 11 }
                        Text { text: "No physical devices linked"; color: "#718396"; font.pixelSize: 10 }
                    }
                }
                Text { Layout.alignment: Qt.AlignHCenter; Layout.topMargin: 4; text: "FutureRecycle v1.3 · Demo"; color: "#526477"; font.pixelSize: 10 }
            }
        }
        ColumnLayout {
            Layout.fillWidth: true; Layout.fillHeight: true
            Layout.leftMargin: 26; Layout.rightMargin: 26
            Layout.topMargin: 22; Layout.bottomMargin: 18; spacing: 16
            RowLayout {
                Layout.fillWidth: true; spacing: 12
                Column {
                    spacing: 5
                    Text {
                        text: ["Overview", "Smart Stations", "Station Map", "Collections", "Pickup Calendar", "Alerts", "Maintenance", "Analytics", "Fill Forecasts", "Reports", "Activity History", "AI Detection", "Settings"][appWindow.pageIndex]
                        color: "#F8FAFC"; font.pixelSize: 26; font.bold: true
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
                Layout.fillWidth: true; Layout.fillHeight: true
                currentIndex: appWindow.pageIndex
                OverviewPage {
                    stateData: appWindow.stateData
                    onScanRequested: appWindow.pageIndex = 11
                    onStationRequested: function(id) { appWindow.goToStation(id) }
                    onAnalyticsRequested: appWindow.pageIndex = 7
                    onActivityRequested: appWindow.pageIndex = 10
                    onAlertsRequested: appWindow.pageIndex = 5
                    onCollectionsRequested: appWindow.pageIndex = 3
                }
                StationsPage {
                    stateData: appWindow.stateData
                    onCollectionRequested: function(id, material) { appWindow.requestCollection(id, material) }
                    onMaintenanceRequested: function(id) { appWindow.requestMaintenance(id) }
                }
                MapPage {
                    stateData: appWindow.stateData
                    onStationRequested: function(id) { appWindow.goToStation(id) }
                    onCollectionRequested: function(id, material) { appWindow.requestCollection(id,material) }
                }
                CollectionsPage {
                    id: collectionPage; stateData: appWindow.stateData
                    onCalendarRequested: function(jobId) { appWindow.goToCalendar(jobId) }
                }
                CalendarPage { id: calendarPage; stateData: appWindow.stateData }
                AlertsPage {
                    stateData: appWindow.stateData
                    onCollectionRequested: function(id,material) { appWindow.requestCollection(id,material) }
                    onStationRequested: function(id) { appWindow.goToStation(id) }
                    onMaintenanceRequested: appWindow.pageIndex = 6
                }
                MaintenancePage { id: maintenancePage; stateData: appWindow.stateData }
                AnalyticsPage { stateData: appWindow.stateData }
                ForecastsPage {
                    stateData: appWindow.stateData
                    onCollectionRequested: function(id, material) { appWindow.requestCollection(id,material) }
                }
                ReportsPage { stateData: appWindow.stateData }
                ActivityPage { stateData: appWindow.stateData }
                ScannerPage { stateData: appWindow.stateData }
                SettingsPage { stateData: appWindow.stateData }
            }
        }
    }
    Rectangle {
        id: toast
        width: Math.min(appWindow.width - 60, toastText.implicitWidth + 54)
        height: 47; radius: 12
        color: "#20382F"; border.color: "#2E7357"
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom; anchors.bottomMargin: 24
        opacity: 0; visible: opacity > 0; z: 100
        Text { id: toastText; anchors.centerIn: parent; text: ""; color: "#E1F8EC"; font.pixelSize: 12; font.bold: true }
        Behavior on opacity { NumberAnimation { duration: 150 } }
    }
    Timer { id: toastTimer; interval: 3300; onTriggered: toast.opacity = 0 }
    Connections {
        target: backend
        function onNotice(message) { toastText.text = message; toast.opacity = 1; toastTimer.restart() }
    }
}
