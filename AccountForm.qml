import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    id: form
    property bool creating: false
    property string submitLabel: creating ? "Create account" : "Sign in"
    signal accepted()
    spacing: 10

    function reset() {
        username.clear()
        password.clear()
        confirmation.clear()
        error.text = ""
    }

    function focusUsername() {
        username.forceActiveFocus()
    }

    function submit() {
        const message = creating
            ? session.createAccount(username.text, password.text, confirmation.text)
            : session.signIn(username.text, password.text)
        if (message) {
            error.text = message
        } else {
            reset()
            accepted()
        }
    }

    Label { text: "Username"; color: "#CBD5E1" }
    TextField {
        id: username
        Layout.fillWidth: true
        Accessible.name: "Username"
        selectByMouse: true
        onAccepted: password.forceActiveFocus()
    }
    Label { text: "Password"; color: "#CBD5E1" }
    TextField {
        id: password
        Layout.fillWidth: true
        Accessible.name: "Password"
        echoMode: TextInput.Password
        onAccepted: form.creating ? confirmation.forceActiveFocus() : form.submit()
    }
    Label { text: "Confirm password"; color: "#CBD5E1"; visible: form.creating }
    TextField {
        id: confirmation
        Layout.fillWidth: true
        Accessible.name: "Confirm password"
        echoMode: TextInput.Password
        visible: form.creating
        onAccepted: form.submit()
    }
    Label {
        id: error
        Layout.fillWidth: true
        color: "#FDA4AF"
        wrapMode: Text.WordWrap
        visible: text.length > 0
    }
    ActionButton {
        Layout.fillWidth: true
        text: form.submitLabel
        onClicked: form.submit()
    }
}
