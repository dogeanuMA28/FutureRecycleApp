import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    property var stateData: ({})
    property int tabIndex: 0
    signal collectionRequested(string stationId, string material)
    signal maintenanceRequested(string stationId)

    function openStation(id) {
        if (id) backend.selectStation(id)
        tabIndex = 0
    }
    function openMap() { tabIndex = 1 }
    function openForecasts() { tabIndex = 2 }

    ColumnLayout {
        anchors.fill: parent
        spacing: 12
        WorkspaceTabs {
            tabs: ["Station List", "Romania Map", "Fill Forecasts"]
            currentIndex: root.tabIndex
            onSelected: function(index) { root.tabIndex = index }
        }
        StackLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: root.tabIndex
            StationsPage {
                stateData: root.stateData
                onCollectionRequested: function(id, material) { root.collectionRequested(id, material) }
                onMaintenanceRequested: function(id) { root.maintenanceRequested(id) }
            }
            MapPage {
                stateData: root.stateData
                onStationRequested: function(id) { root.openStation(id) }
                onCollectionRequested: function(id, material) { root.collectionRequested(id, material) }
            }
            ForecastsPage {
                stateData: root.stateData
                onCollectionRequested: function(id, material) { root.collectionRequested(id, material) }
            }
        }
    }
}
