import QtQuick 1.1
import com.nokia.symbian 1.1
import "data.js" as Data

Page {
    id:settingsPage
    tools:toolBarLayout
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
                //text:cardDavClient.username
                text:"b100dian"
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
                //text: cardDavClient.password
                text:"hmmtybkyzcbtlcjo"
            }
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
                    cardDavClient.setUsername(userField.text)
                    cardDavClient.setPassword(passwordField.text);
                    Data.storeCredentials(cardDavClient.username, cardDavClient.password);
                    window.pageStack.depth <= 1 ? window.goToMainPage() : window.pageStack.pop();
                }
            }
        }
    }
}
