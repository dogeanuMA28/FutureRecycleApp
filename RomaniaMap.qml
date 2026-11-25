
import QtQuick
import QtQuick.Controls
import QtLocation
import QtPositioning

// FutureRecycle — Interactive Romania Map
// OpenStreetMap tiles, no API key required.

Item {
    id: root

    property var stations: []
    property string selectedId: ""
    property bool placing: false

    signal stationClicked(string stationId)
    signal coordinateChosen(real latitude, real longitude)

    function resetView() {
        liveMap.center = QtPositioning.coordinate(
            45.9432, 24.9668
        )
        liveMap.zoomLevel = 6.15
    }

    function focusSelected() {
        for (var i = 0; i < stations.length; i++) {
            if (stations[i].id === selectedId) {
                liveMap.center = QtPositioning.coordinate(
                    Number(stations[i].latitude),
                    Number(stations[i].longitude)
                )
                liveMap.zoomLevel = 11
                return
            }
        }
    }

    // OPENSTREETMAP CONFIGURATION

    Plugin {
        id: osmPlugin
        name: "osm"

        // Disable the provider catalog so Qt doesn't
        // select a tile provider requiring an API key.
        PluginParameter {
            name: "osm.mapping.providersrepository.disabled"
            value: true
        }

        PluginParameter {
            name: "osm.mapping.custom.host"
            value: "https://tile.openstreetmap.org/"
        }

        PluginParameter {
            name: "osm.mapping.custom.mapcopyright"
            value: "© OpenStreetMap contributors"
        }

        PluginParameter {
            name: "osm.mapping.custom.datacopyright"
            value: "© OpenStreetMap contributors"
        }

        PluginParameter {
            name: "osm.useragent"
            value: "FutureRecycleUniversityDemo/1.3"
        }
    }

    // INTERACTIVE MAP

    Map {
        id: liveMap

        anchors.fill: parent

        color: "#243240"

        center: QtPositioning.coordinate(
            45.9432, 24.9668
        )

        zoomLevel: 6.15
        minimumZoomLevel: 4.5
        maximumZoomLevel: 18

        plugin: osmPlugin

        // Select the custom OpenStreetMap tile layer.
        function selectPublicTiles() {
            if (supportedMapTypes.length > 0) {
                activeMapType =
                    supportedMapTypes[supportedMapTypes.length - 1]
            }
        }

        onSupportedMapTypesChanged: selectPublicTiles()

        Component.onCompleted: selectPublicTiles()

        // LEFT-CLICK DRAGGING

        DragHandler {
            id: mapDrag

            target: null
            enabled: !root.placing

            onTranslationChanged: function(delta) {
                liveMap.pan(
                    -delta.x,
                    -delta.y
                )
            }
        }

        // MOUSE-WHEEL ZOOM

        WheelHandler {
            id: zoomWheel

            enabled: !root.placing

            acceptedDevices:
                PointerDevice.Mouse |
                PointerDevice.TouchPad

            property: "zoomLevel"
            rotationScale: 1 / 120
        }

        // TOUCHPAD / TOUCHSCREEN PINCH

        PinchHandler {
            id: pinch

            target: null
            enabled: !root.placing

            property geoCoordinate startingCenter

            onActiveChanged: {
                if (active) {
                    startingCenter = liveMap.toCoordinate(
                        pinch.centroid.position,
                        false
                    )
                }
            }

            onScaleChanged: function(delta) {
                liveMap.zoomLevel += Math.log2(delta)

                liveMap.alignCoordinateToPoint(
                    startingCenter,
                    pinch.centroid.position
                )
            }

            grabPermissions:
                PointerHandler.TakeOverForbidden
        }

        // STATION MARKERS

        MapItemView {
            model: root.stations

            delegate: MapQuickItem {
                id: mapPin

                required property var modelData

                coordinate: QtPositioning.coordinate(
                    Number(modelData.latitude),
                    Number(modelData.longitude)
                )

                anchorPoint.x: bubble.width / 2
                anchorPoint.y: bubble.height + 10

                zoomLevel: 0

                z: mapPin.modelData.id === root.selectedId
                   ? 10
                   : 2

                sourceItem: Item {
                    id: bubble

                    width: 142
                    height: 65

                    // Marker pointer

                    Rectangle {
                        anchors.horizontalCenter:
                            parent.horizontalCenter

                        y: 49

                        width: 13
                        height: 13

                        rotation: 45
                        radius: 2

                        color:
                            mapPin.modelData.status === "Online"
                            ? "#10B981"
                            : mapPin.modelData.status === "Offline"
                              ? "#FB7185"
                              : "#FBBF24"
                    }

                    // Marker card

                    Rectangle {
                        width: parent.width
                        height: 52

                        radius: 10

                        color:
                            mapPin.modelData.id === root.selectedId
                            ? "#173E33"
                            : "#16242F"

                        border.color:
                            mapPin.modelData.id === root.selectedId
                            ? "#34D399"
                            : mapPin.modelData.status === "Online"
                              ? "#10B981"
                              : mapPin.modelData.status === "Offline"
                                ? "#FB7185"
                                : "#FBBF24"

                        border.width:
                            mapPin.modelData.id === root.selectedId
                            ? 2
                            : 1

                        Column {
                            anchors.centerIn: parent
                            spacing: 4

                            Text {
                                anchors.horizontalCenter:
                                    parent.horizontalCenter

                                text: "●  " + mapPin.modelData.id

                                color:
                                    mapPin.modelData.status === "Online"
                                    ? "#34D399"
                                    : mapPin.modelData.status === "Offline"
                                      ? "#FB7185"
                                      : "#FBBF24"

                                font.pixelSize: 11
                                font.bold: true
                            }

                            Text {
                                width: 126

                                elide: Text.ElideRight
                                horizontalAlignment: Text.AlignHCenter

                                text: mapPin.modelData.name

                                color: "#F8FAFC"
                                font.pixelSize: 10
                            }
                        }
                    }

                    // Click station marker

                    MouseArea {
                        anchors.fill: parent

                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor

                        onClicked: {
                            root.stationClicked(
                                mapPin.modelData.id
                            )
                        }
                    }
                }
            }
        }
    }

    // STATION PLACEMENT MODE

    MouseArea {
        anchors.fill: parent

        enabled: root.placing
        visible: root.placing

        cursorShape: Qt.CrossCursor

        onClicked: function(mouse) {
            var geo = liveMap.toCoordinate(
                Qt.point(mouse.x, mouse.y),
                false
            )

            if (geo.isValid) {
                root.coordinateChosen(
                    geo.latitude,
                    geo.longitude
                )
            }
        }
    }

    // TOP-LEFT MAP LABEL

    Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.margins: 15

        width: 158
        height: 47

        radius: 9
        color: "#EC13212C"

        Column {
            anchors.centerIn: parent
            spacing: 3

            Text {
                text: "ROMANIA / LIVE MAP"
                color: "#F8FAFC"
                font.pixelSize: 11
                font.bold: true
            }

            Text {
                text: "OpenStreetMap streets & cities"
                color: "#A4B8C5"
                font.pixelSize: 9
            }
        }
    }

    // ZOOM CONTROLS

    Rectangle {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 15

        width: 36
        height: 79

        radius: 9
        color: "#EE16232E"

        Column {
            anchors.centerIn: parent
            spacing: 3

            Button {
                width: 32
                height: 33

                text: "+"

                onClicked: {
                    liveMap.zoomLevel = Math.min(
                        18,
                        liveMap.zoomLevel + 1
                    )
                }

                background: Rectangle {
                    radius: 6

                    color: parent.hovered
                           ? "#345366"
                           : "transparent"
                }

                contentItem: Text {
                    text: parent.text

                    color: "#F8FAFC"
                    font.pixelSize: 20

                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }

            Rectangle {
                width: 27
                height: 1

                color: "#334C5D"

                anchors.horizontalCenter:
                    parent.horizontalCenter
            }

            Button {
                width: 32
                height: 33

                text: "−"

                onClicked: {
                    liveMap.zoomLevel = Math.max(
                        4.5,
                        liveMap.zoomLevel - 1
                    )
                }

                background: Rectangle {
                    radius: 6

                    color: parent.hovered
                           ? "#345366"
                           : "transparent"
                }

                contentItem: Text {
                    text: parent.text

                    color: "#F8FAFC"
                    font.pixelSize: 20

                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }
    }

    // BOTTOM INFORMATION BAR

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom

        height: root.placing ? 47 : 35

        color: "#E8152530"

        Text {
            anchors.centerIn: parent

            width: parent.width - 26

            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight

            text: root.placing
                  ? "Click on the map to place the selected station"
                  : "© OpenStreetMap contributors · Internet connection required"

            font.pixelSize: 10

            color: root.placing
                   ? "#6EE7B7"
                   : "#D8E3EC"
        }
    }
}
