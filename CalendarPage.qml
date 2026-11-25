import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    property var stateData: ({})
    readonly property var stations: stateData.stations || []
    readonly property var jobs: stateData.collections || []
    property date displayedMonth: new Date(new Date().getFullYear(), new Date().getMonth(), 1)
    property string selectedDay: Qt.formatDate(new Date(), "yyyy-MM-dd")
    function focusJob(jobId) {
        if (!jobId) return
        for (var i=0; i<schedulableJobs.length; i++) {
            if (schedulableJobs[i].id === jobId) {
                requestCombo.currentIndex = i
                var scheduled = schedulableJobs[i].scheduledFor
                if (scheduled && scheduled >= iso(new Date())) {
                    var parts = scheduled.split("-")
                    displayedMonth = new Date(Number(parts[0]), Number(parts[1])-1, 1)
                    selectedDay = scheduled
                }
                return
            }
        }
    }
    readonly property var schedulableJobs: jobs.filter(function(j){ return j.status === "Requested" || j.status === "Scheduled" })
    readonly property var selectedDayJobs: jobs.filter(function(j){ return j.scheduledFor === root.selectedDay && j.status === "Scheduled" })
    readonly property var upcomingJobs: jobs.filter(function(j){ return j.status === "Scheduled" && j.scheduledFor }).sort(function(a,b){ return a.scheduledFor.localeCompare(b.scheduledFor) })
    readonly property var calendarCells: root.makeCells()

    function stationName(sid) {
        for (var i=0;i<stations.length;i++) if (stations[i].id === sid) return stations[i].name
        return sid
    }
    function iso(d) { return Qt.formatDate(d, "yyyy-MM-dd") }
    function makeCells() {
        var first = new Date(displayedMonth.getFullYear(), displayedMonth.getMonth(), 1)
        var startOffset = (first.getDay() + 6) % 7
        var start = new Date(first.getFullYear(), first.getMonth(), 1 - startOffset)
        var today = iso(new Date())
        var result = []
        for (var i=0;i<42;i++) {
            var d = new Date(start.getFullYear(), start.getMonth(), start.getDate() + i)
            var key = iso(d)
            var matching = jobs.filter(function(j){return j.status === "Scheduled" && j.scheduledFor === key}).length
            result.push({ day:d.getDate(), date:key, thisMonth:d.getMonth() === displayedMonth.getMonth(), past:key < today, pickups:matching })
        }
        return result
    }
    function switchMonth(delta) { displayedMonth = new Date(displayedMonth.getFullYear(), displayedMonth.getMonth() + delta, 1) }
    function chooseToday() { displayedMonth = new Date(new Date().getFullYear(), new Date().getMonth(), 1); selectedDay = iso(new Date()) }

    Flickable {
        anchors.fill: parent; clip: true
        contentHeight: content.implicitHeight + 26
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
        ColumnLayout {
            id: content; width: parent.width - 16; spacing: 18
            RowLayout {
                Layout.fillWidth: true
                Column {
                    spacing: 5
                    Text { text: "Collection Calendar"; color: "#F8FAFC"; font.pixelSize: 24; font.bold: true }
                    Text { text: "Plan and manage pickup dates and service windows"; color: "#94A3B8"; font.pixelSize: 12 }
                }
                Item { Layout.fillWidth: true }
                ActionButton { text: "Today"; tone: "neutral"; onClicked: root.chooseToday() }
            }
            RowLayout {
                Layout.fillWidth: true; spacing: 16
                Rectangle {
                    Layout.fillWidth: true; Layout.preferredHeight: 537; radius: 15
                    color: "#161F29"; border.color: "#293644"
                    ColumnLayout {
                        anchors.fill: parent; anchors.margins: 19; spacing: 12
                        RowLayout {
                            Layout.fillWidth: true
                            Text { text: Qt.formatDate(root.displayedMonth,"MMMM yyyy"); font.pixelSize: 19; font.bold: true; color: "#F8FAFC" }
                            Item { Layout.fillWidth: true }
                            ActionButton { text: "‹"; implicitWidth: 41; tone: "neutral"; onClicked: root.switchMonth(-1) }
                            ActionButton { text: "›"; implicitWidth: 41; tone: "neutral"; onClicked: root.switchMonth(1) }
                        }
                        GridLayout {
                            Layout.fillWidth: true; columns: 7; columnSpacing: 7; rowSpacing: 7
                            Repeater {
                                model: ["MON", "TUE", "WED", "THU", "FRI", "SAT", "SUN"]
                                delegate: Rectangle {
                                    required property string modelData
                                    Layout.fillWidth: true; Layout.preferredHeight: 25; color: "transparent"
                                    Text { anchors.centerIn: parent; text: modelData; font.pixelSize: 10; font.bold: true; color: "#879CAF" }
                                }
                            }
                            Repeater {
                                model: root.calendarCells
                                delegate: Rectangle {
                                    id: dayCard
                                    required property var modelData
                                    Layout.fillWidth: true; Layout.preferredHeight: 59; radius: 9
                                    color: root.selectedDay === modelData.date ? "#185A45" : dayHover.hovered && modelData.thisMonth && !modelData.past ? "#253949" : "#202D38"
                                    border.color: root.selectedDay === modelData.date ? "#38D9A4" : "#2C4050"
                                    opacity: modelData.thisMonth ? 1 : .38
                                    Column {
                                        anchors.centerIn: parent; spacing: 5
                                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: dayCard.modelData.day; font.pixelSize: 13; font.bold: true; color: dayCard.modelData.past ? "#708499" : "#EAF3F8" }
                                        Rectangle {
                                            anchors.horizontalCenter: parent.horizontalCenter; radius: 6
                                            width: 17; height: 17
                                            visible: dayCard.modelData.pickups > 0
                                            color: "#416B57"
                                            Text { anchors.centerIn: parent; text: dayCard.modelData.pickups; color: "#B7F7D6"; font.pixelSize: 10; font.bold: true }
                                        }
                                    }
                                    HoverHandler { id: dayHover; cursorShape: modelData.thisMonth && !modelData.past ? Qt.PointingHandCursor : Qt.ArrowCursor }
                                    TapHandler { onTapped: if (dayCard.modelData.thisMonth && !dayCard.modelData.past) root.selectedDay = dayCard.modelData.date }
                                }
                            }
                        }
                        Text { text: "Green numbers indicate scheduled pickups on that date."; font.pixelSize: 11; color: "#8297AA" }
                        Item { Layout.fillHeight: true }
                    }
                }
                Rectangle {
                    Layout.preferredWidth: 296; Layout.preferredHeight: 537; radius: 15
                    color: "#161F29"; border.color: "#293644"
                    ColumnLayout {
                        anchors.fill: parent; anchors.margins: 18; spacing: 14
                        RowLayout {
                            Layout.fillWidth: true

                            Text {
                                text: "Plan a Pickup"
                                font.pixelSize: 19
                                font.bold: true
                                color: "#F8FAFC"
                            }

                            Item {
                                Layout.fillWidth: true
                            }

                            ActionButton {
                                text: "+ Request"
                                implicitWidth: 104
                                implicitHeight: 36

                                onClicked: pickupPopup.open()
                            }
                        }
                        Text { text: "Choose a calendar date, then assign an active request to that day."; color: "#93A9BB"; font.pixelSize: 12; wrapMode: Text.WordWrap; Layout.fillWidth: true }
                        Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: "#354452" }
                        Text { text: "SELECTED DATE"; color: "#8297AB"; font.pixelSize: 10; font.bold: true }
                        Text { text: root.selectedDay; color: "#34D399"; font.pixelSize: 20; font.bold: true }
                        Text { text: "PICKUP REQUEST"; color: "#8297AB"; font.pixelSize: 10; font.bold: true }
                        DarkCombo {
                            id: requestCombo; Layout.fillWidth: true
                            model: root.schedulableJobs.map(function(j){return j.id + " · " + j.stationId + " · " + j.material})
                        }
                        Text { text: "TIME WINDOW"; color: "#8297AB"; font.pixelSize: 10; font.bold: true }
                        DarkCombo { id: timeCombo; Layout.fillWidth: true; model: ["Morning", "Afternoon", "Evening"] }
                        ActionButton {
                            Layout.fillWidth: true; implicitHeight: 45; text: "Schedule Pickup"; enabled: root.schedulableJobs.length > 0
                            onClicked: {
                                if (requestCombo.currentIndex < 0 || requestCombo.currentIndex >= root.schedulableJobs.length) return
                                backend.scheduleCollection(root.schedulableJobs[requestCombo.currentIndex].id, root.selectedDay, timeCombo.currentText)
                            }
                        }
                        Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: "#354452" }
                        Text { text: "PICKUPS ON " + root.selectedDay; font.pixelSize: 10; font.bold: true; color: "#91A5BA" }
                        Repeater {
                            model: root.selectedDayJobs
                            delegate: Rectangle {
                                required property var modelData
                                Layout.fillWidth: true; Layout.preferredHeight: 45; radius: 8; color: "#213746"
                                Column {
                                    anchors.centerIn: parent; spacing: 3
                                    Text { text: modelData.id + " · " + modelData.material; font.bold: true; font.pixelSize: 11; color: "#EAF4FA" }
                                    Text { text: modelData.scheduledSlot + " · " + modelData.stationId; font.pixelSize: 10; color: "#91AABB" }
                                }
                            }
                        }
                        Text { visible: root.selectedDayJobs.length === 0; text: "No pickups scheduled for this day."; font.pixelSize: 11; color: "#8297AB"; wrapMode: Text.WordWrap; Layout.fillWidth: true }
                        Item { Layout.fillHeight: true }
                    }
                }
            }
            RowLayout {
                Layout.fillWidth: true
                Text { text: "Upcoming Scheduled Collections"; font.pixelSize: 18; font.bold: true; color: "#F8FAFC" }
                Item { Layout.fillWidth: true }
                Text { text: root.upcomingJobs.length + " active appointments"; color: "#8EA2B5"; font.pixelSize: 11 }
            }
            Repeater {
                model: root.upcomingJobs.slice(0, 10)
                delegate: Rectangle {
                    id: appointment; required property var modelData
                    Layout.fillWidth: true; Layout.preferredHeight: 74; radius: 11; color: "#161F29"; border.color: "#293644"
                    RowLayout {
                        anchors.fill: parent; anchors.margins: 14; spacing: 13
                        Rectangle {
                            width: 49; height: 44; radius: 9; color: "#183E34"
                            Text { anchors.centerIn: parent; text: appointment.modelData.scheduledFor.slice(8); font.pixelSize: 18; font.bold: true; color: "#6EE7B7" }
                        }
                        Column {
                            spacing: 5
                            Text { text: appointment.modelData.stationId + " · " + root.stationName(appointment.modelData.stationId); color: "#F1F5F9"; font.pixelSize: 13; font.bold: true }
                            Text { text: appointment.modelData.material.toUpperCase() + " · " + appointment.modelData.scheduledFor + " · " + appointment.modelData.scheduledSlot; color: "#92A8B9"; font.pixelSize: 11 }
                        }
                        Item { Layout.fillWidth: true }
                        Text { text: appointment.modelData.id; color: "#71879B"; font.pixelSize: 11 }
                        ActionButton { text: "Complete"; implicitWidth: 100; onClicked: { completion.jobId = appointment.modelData.id; completion.open() } }
                    }
                }
            }
            Text { visible: root.upcomingJobs.length === 0; text: "No upcoming pickups. Create a collection request, then schedule it above."; color: "#92A6BA"; font.pixelSize: 12 }
            Text { text: "DEMO CALENDAR · APPOINTMENTS ARE NOT SENT TO A REAL COLLECTION TEAM"; font.pixelSize: 10; color: "#657B90"; Layout.alignment: Qt.AlignHCenter }
        }
    }
    Dialog {
        id: completion; property string jobId: ""; anchors.centerIn: parent; modal: true
        title: "Confirm simulated collection"; standardButtons: Dialog.Yes | Dialog.No
        onAccepted: backend.setCollectionStatus(jobId,"Completed")
        contentItem: Text { width: 330; text: "Record this scheduled pickup as completed? The selected container will be emptied."; wrapMode: Text.WordWrap; color: "#E8F1F8" }
        background: Rectangle { radius: 12; color: "#21313F"; border.color: "#42566A" }
    }

    // CREATE PICKUP DIRECTLY FROM CALENDAR
    Popup {
        id: pickupPopup

        anchors.centerIn: parent
        width: Math.min(460, root.width - 30)
        height: 370

        modal: true
        focus: true

        closePolicy: Popup.CloseOnEscape |
                     Popup.CloseOnPressOutside

        background: Rectangle {
            radius: 15
            color: "#1C2936"
            border.color: "#405467"
        }

        contentItem: ColumnLayout {
            spacing: 12

            Text {
                text: "Request a Pickup"
                color: "#F8FAFC"
                font.pixelSize: 20
                font.bold: true
            }

            Text {
                text: "Create and schedule a collection for " +
                      root.selectedDay
                color: "#94A3B8"
                font.pixelSize: 12
            }

            Text {
                text: "RECYCLING STATION"
                color: "#94A3B8"
                font.pixelSize: 10
                font.bold: true
            }

            DarkCombo {
                id: pickupStationCombo
                Layout.fillWidth: true

                model: root.stations.map(function(s) {
                    return s.id + " · " + s.name
                })
            }

            Text {
                text: "WASTE MATERIAL"
                color: "#94A3B8"
                font.pixelSize: 10
                font.bold: true
            }

            DarkCombo {
                id: pickupMaterialCombo
                Layout.fillWidth: true

                model: [
                    "plastic",
                    "paper",
                    "metal"
                ]
            }

            TextField {
                id: pickupNote
                Layout.fillWidth: true
                implicitHeight: 40
                maximumLength: 200

                placeholderText: "Optional instructions"
                color: "#F8FAFC"
                placeholderTextColor: "#94A3B8"

                background: Rectangle {
                    radius: 8
                    color: "#263746"
                    border.color: "#42576A"
                }
            }

            Item {
                Layout.fillHeight: true
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                ActionButton {
                    Layout.fillWidth: true
                    text: "Cancel"
                    tone: "neutral"

                    onClicked: pickupPopup.close()
                }

                ActionButton {
                    Layout.fillWidth: true
                    text: "Create & Schedule"

                    enabled: pickupStationCombo.currentIndex >= 0 &&
                             root.selectedDay >= root.iso(new Date())

                    onClicked: {
                        var index = pickupStationCombo.currentIndex

                        if (index < 0 ||
                            index >= root.stations.length) {
                            return
                        }

                        var stationId = root.stations[index].id

                        var material =
                            pickupMaterialCombo.currentText

                        // Step 1: Create collection request
                        var jobId = backend.requestCollection(
                            stationId,
                            material,
                            pickupNote.text
                        )

                        // Creation may fail if a container is
                        // empty or already has an active pickup.
                        if (!jobId) {
                            return
                        }

                        // Step 2: Schedule the new request
                        var success = backend.scheduleCollection(
                            jobId,
                            root.selectedDay,
                            timeCombo.currentText
                        )

                        if (success) {
                            pickupNote.text = ""
                            pickupPopup.close()
                        }
                    }
                }
            }
        }
    }

}
