import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    property var stateData: ({})
    property int tabIndex: 0

    function showAnalytics() { tabIndex = 0 }
    function showReports() { tabIndex = 1 }
    function showActivity() { tabIndex = 2 }

    ColumnLayout {
        anchors.fill: parent
        spacing: 12
        WorkspaceTabs {
            tabs: ["Analytics", "Reports & Export", "Activity History"]
            currentIndex: root.tabIndex
            onSelected: function(index) { root.tabIndex = index }
        }
        StackLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: root.tabIndex
            AnalyticsPage { stateData: root.stateData }
            ReportsPage { stateData: root.stateData }
            ActivityPage { stateData: root.stateData }
        }
    }
}
