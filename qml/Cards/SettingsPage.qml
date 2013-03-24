import QtQuick 1.1
import com.nokia.symbian 1.1
import "data.js" as Data

Page {
    id:settingsPage
    tools:toolBarLayout
    onStatusChanged: {
        console.log ("SettingsPage status " + status)
        if (status == PageStatus.Active) {
            userField.text = cardDavClient.username;
            passwordField.text = cardDavClient.password;
        }
    }
    Column {
        anchors.left: parent.left
        anchors.right: parent.right

        Row {
            anchors.left: parent.left
            anchors.right: parent.right
            Label {
                text: "Username:"
                width:100
                anchors.verticalCenter: parent.verticalCenter
            }

            TextField {
                id:userField
                anchors.verticalCenter: parent.verticalCenter
                anchors.right:parent.right
                width:200
            }
        }
        Row {
            anchors.left: parent.left
            anchors.right: parent.right
            Label {
                text: "Password:"
                width:100
                anchors.verticalCenter: parent.verticalCenter
            }

            TextField {
                echoMode: TextInput.Password
                id:passwordField;
                width:200
                anchors.right:parent.right
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    Column {
        anchors.bottom: parent.bottom
        Label {
            text:"(c) 2013 Vlad Grecescu\nn85blog.wordpress.com\nb100dian@gmail.com"
        }
    }


    ToolBarLayout {
        id: toolBarLayout
        ToolButton {
            flat: true
            iconSource: "toolbar-back"
            onClicked: window.pageStack.depth <= 1 ? Qt.quit() : window.pageStack.pop()
        }
        ToolButton {
            flat: true
            iconSource: "gfx/icon-m-toolbar-done-white.png"
            onClicked: {
                if (!userField.text || !passwordField.text) {
                    banner.text = "User and password both required";
                    banner.open();
                } else {
                    Data.storeCredentials(userField.text, passwordField.text);
                    return window.pageStack.depth <= 1 ? window.goToMainPage() : window.pageStack.pop();
                }
            }
        }
    }
}
