import QtQuick 1.1
import com.nokia.symbian 1.1
import com.nokia.extras 1.1


import "cards.js" as Cards
import "data.js" as Data
Page {
    id: mainPage

    Component.onCompleted:  {
    }

    onStatusChanged: {
        console.log ("MainPage status " + status)
        if (status != PageStatus.Active || progress.visible) return;
        if (busy.visible || progress.visible) return;
        Data.initialize();
        Data.haveCredentials(function (user, password){
                                 banner.text = "Using stored username and password";
                                 banner.open();
                                 cardDavClient.setUsername(user);
                                 cardDavClient.setPassword(password);
                                 cardDavClient.getCardNamesAsync();
                                 busy.visible = true;
                             }, function () {
                                 banner.text = "No user or password stored";
                                 banner.open();
                                 window.goToSettings();
                             });
    }

    ListModel {
        id: cardModel
    }

    Component {
        id: cardDelegate
        ListItem {
            onClicked: {
                Qt.openUrlExternally("tel:"+cell);
            }

            Column {
                anchors.fill: cardDelegate.padding
                ListItemText {
                    id: titleText
                    mode: cardDelegate.mode
                    role: "Title"
                    text: fullname
                }
                ListItemText {
                    id: subtitleText
                    mode: cardDelegate.mode
                    role: "SubTitle"
                    text: cell
                }
            }
        }
    }

    ListView {
        id: cardList
        anchors.fill: parent
        model: cardModel
        delegate: cardDelegate
    }

    ScrollDecorator {
        id: scrolldecorator
        flickableItem: cardList
    }

    ProgressBar {
        id: progress
        anchors.bottom: parent.bottom
        minimumValue: 0
        value: 0
        visible: false
    }

    BusyIndicator {
        id: busy
        visible: false
        running: visible
        anchors.centerIn: parent
    }

    Connections {
        target:cardDavClient;
        onCardNames:{
            busy.visible = false;
            console.log("NAMES" + names);
            if (!names) {
                banner.text = "Authentication failed";
                banner.open();
                goToSettings();
            } else {
                progress.maximumValue = names.length;
                progress.visible = true;
                Cards.startQuerying(names);
            }
        }
        onCard:{
            console.log("CARD->\n" + card);
            var item = Cards.cardDone(cardName, card, function() {
                                          progress.visible = false;
                                      });
            cardModel.append(item);
            progress.value ++;
        }
        onError:{
            banner.text = "Error: " + message;
            banner.open();
            progress.visible = false;
            busy.visible = false;
        }
    }

}
