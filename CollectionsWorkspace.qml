import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    property var stateData: ({})
    property int tabIndex: 0

    function openRequest(stationId, material) {
        tabIndex = 0
        requests.openRequest(stationId, material)
    }
    function openCalendar(jobId) {
        tabIndex = 1
        calendar.focusJob(jobId || "")
    }
    function showRequests() { tabIndex = 0 }
    function showCalendar() { tabIndex = 1 }

    ColumnLayout {
        anchors.fill: parent
        spacing: 12
        WorkspaceTabs {
            tabs: ["Collection Requests", "Pickup Calendar"]
            currentIndex: root.tabIndex
            onSelected: function(index) { root.tabIndex = index }
        }
        StackLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: root.tabIndex
            CollectionsPage {
                id: requests
                stateData: root.stateData
                onCalendarRequested: function(jobId) { root.openCalendar(jobId) }
            }
            CalendarPage {
                id: calendar
                stateData: root.stateData
            }
        }
    }
}
