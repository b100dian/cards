import QtQuick 1.1
import QtMobility.contacts 1.1
import com.nokia.symbian 1.1
import com.nokia.extras 1.1


import "cards.js" as Cards
import "data.js" as Data
Page {
    id: mainPage

    ContactModel {
        id:contactModel;
    }

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
                                 var existingCards = Data.getExistingCards();
                                 for (var i in existingCards){
                                     var item = Cards.parseCard(existingCards[i]);
                                     item.isNew = false;
                                     insertSorted(item);
                                 }

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
        property variant tels;
        property variant mails;
        MenuLayout {
            Repeater {
                model:contactMenu.tels;
                MenuItem {
                    text :"Call " + t
                    onClicked: {
                        Qt.openUrlExternally("tel:" + t);
                        contactMenu.close();
                    }
                }
            }
            Repeater {
                model:contactMenu.mails;
                MenuItem {
                    text : "Mail " + m
                    onClicked: {
                        contactMenu.close();
                        Qt.openUrlExternally("mailto:" + m);
                    }
                }
            }
        }
    }


    Component {
        id: cardDelegate
        ListItem {
            onClicked: {
                contactMenu.tels = tels;
                contactMenu.mails = mails;
                contactMenu.open();
            }

            Column {
                anchors.fill: cardDelegate.padding
                ListItemText {
                    color: isNew?"#1381DD":"lightgray"
                    id: titleText
                    role: "Title"
                    text: fullname
                }
                Flow {
                    ListItemText {
                        id: mailText
                        role: "SubTitle"
                        text: mail?mail:""
                    }
                    ListItemText {
                        id: telText
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
        width: 40
        height: 40
    }

    Connections {
        target:cardDavClient;
        onCardNames:{
            if (!names) {
                banner.text = "Authentication failed";
                banner.open();
                goToSettings();
            } else {
                // Insert new names in a newcards
                var newNames = Data.determineNewNames(names);

                if (newNames.length) {
                    banner.text = "Fetching " + (newNames.length) + " new cards."
                    banner.open();

                    progress.maximumValue = newNames.length;
                    progress.visible = true;

                    Cards.startQuerying(newNames);
                } else {
                    busy.visible = false;
                    console.log("done.");
                }
            }
        }
        onCard:{
            busy.visible = false;
            var itemData = Cards.cardDone(cardName, card, function() {
                                          progress.visible = false;
                                          cardList.activeFocus
                                     });
            // TODO should have passed the etag until here?
            Data.appendNewCard(cardName, itemData);

            var item = Cards.parseCard(itemData);
            item.isNew = true;

            if (!item.fullname) {
                console.log("CARD->\n" + card);
                return;
            }

            insertSorted(item);

            progress.value ++;
        }
        onError:{
            banner.text = "Error: " + message;
            banner.open();
            progress.visible = false;
            busy.visible = false;
        }
    }

    function insertSorted(item) {
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
                    if (item.fullname == existing.fullname) {
                        console.log ("Replacing " + item.fullname + " at pos " + pos);
                        cardModel.set(pos, item);
                    } else {
                        cardModel.insert(pos, item);
                    }
                    break;
                }
            }
        }
    }

}
