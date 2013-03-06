import QtQuick 1.1
import com.nokia.symbian 1.1
import com.nokia.extras 1.1


import "cards.js" as Cards
import "data.js" as Data
Page {
    id: mainPage

    Component.onCompleted:  {
        Data.initialize();
        Data.haveCredentials(function (user, password){
                                 banner.text = "Using stored username and password";
                                 banner.open();
                                 cardDavClient.setUsername(user);
                                 cardDavClient.setPassword(password);
                                 cardDavClient.getCardNamesAsync();
                             }, function () {
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
        anchors.centerIn: parent
        minimumValue: 0
        value: 0
    }

    Connections {
        target:cardDavClient;
        onCardNames:{
            console.log("NAMES" + names);
            if (!names) {
                banner.text = "Authentication failed";
                banner.open();
                goToSettings();
            } else {
                progress.maximumValue = names.length;
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
            console.log("ERROR" + message);
            banner.text = "Error: " + message;
            banner.open();
            goToSettings();
        }
    }

}
