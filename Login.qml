import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ApplicationWindow {
    width: 520
    height: 550
    minimumWidth: 380
    minimumHeight: 525
    visible: true
    title: "FutureRecycle"
    color: "#0B0F14"
    font.family: "Noto Sans"

    onVisibleChanged: {
        if (visible)
            accountForm.focusUsername()
    }

    Rectangle {
        anchors.centerIn: parent
        width: Math.min(parent.width - 40, 400)
        height: content.implicitHeight + 56
        radius: 16
        color: "#111820"
        border.color: "#263340"

        ColumnLayout {
            id: content
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 28
            spacing: 14

            Text {
                text: "FutureRecycle"
                color: "#34D399"
                font.pixelSize: 18
                font.bold: true
            }
            Text {
                text: session.needsSetup ? "Create your first account" : "Sign in"
                color: "#F8FAFC"
                font.pixelSize: 24
                font.bold: true
            }
            Text {
                Layout.fillWidth: true
                text: session.needsSetup
                      ? "Create a local account to open the dashboard."
                      : "Use your local account to open the dashboard."
                color: "#94A3B8"
                wrapMode: Text.WordWrap
            }
            AccountForm {
                id: accountForm
                Layout.fillWidth: true
                creating: session.needsSetup
            }
        }
    }
}
