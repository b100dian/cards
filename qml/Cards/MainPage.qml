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
        if (status != PageStatus.Active || progress.visible) return;
        if (busy.visible || progress.visible) return;
        Data.initialize();
        Data.haveCredentials(function (user, password){
                                 banner.text = "Using stored username and password";
                                 banner.open();
                                 cardModel.clear();
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

    ContextMenu  {
        id:contactMenu;
        MenuLayout {
            id: menuLayout;
            MenuItem {
                text :"Call"
                onClicked: {
                    Qt.openUrlExternally("tel:"+tels[0]);
                }
            }
            MenuItem {
                text : "Mail"
                onClicked: {
                    Qt.openUrlExternally("mailto:"+mails[0]);
                }
            }
        }
    }


    Component {
        id: cardDelegate
        ListItem {
            onClicked: {
                for (var t = 0; t<tels.length; t++) {
                    var menuComponent = Qt.createComponent("MenuItem.qml");
                    if (menuComponent.status == Component.Ready) {
                        var menuItem = m.createObject(menuLayout);
                        menuItem.text = tels[t];
                    } else {
                        console.log ("CONTEXT component not ready " + t);
                    }
                }

                contactMenu.open();

                //Qt.openUrlExternally("tel:"+tels[0]);
            }

            Column {
                anchors.fill: cardDelegate.padding
                ListItemText {
                    id: titleText
                    mode: cardDelegate.mode
                    role: "Title"
                    text: fullname
                }
                Row {
                    ListItemText {
                        id: mailText
                        mode: cardDelegate.mode
                        role: "SubTitle"
                        text: mail?mail:""
                    }
                    ListItemText {
                        id: telText
                        mode: cardDelegate.mode
                        role: "SubTitle"
                        text: tel?tel:""
                    }
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
        anchors.left: parent.left
        anchors.right: parent.right
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
            var item = Cards.cardDone(cardName, card, function() {
                                          progress.visible = false;
                                          cardList.activeFocus
                                      });
            if (!item.fullname) {
                console.log("CARD->\n" + card);
                return;
            }
            // insert sorted
            var pmax = cardModel.count;
            var pmin = 0;
            var pos;
            while (1) {
                pos = Math.floor((pmax + pmin)/2);
                if (pos >= cardModel.count) {
                    cardModel.append(item);
                    break;
                } else if (pos < 0) {
                    cardModel.insert(0, item);
                    break;
                } else {
                    var existing = cardModel.get(pos);
                    if (existing.fullname < item.fullname) {
                        pmin = pos + 1;
                    } else if (item.fullname < existing.fullname){
                        pmax = pos;
                    } else {
                        pmin = pmax = pos;
                    }

                    if (pmax <= pmin) {
                        pos = pmin;
                        cardModel.insert(pos, item);
                        break;
                    }
                }
            }
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
