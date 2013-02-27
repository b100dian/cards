import QtQuick 1.1
import com.nokia.symbian 1.1

import "cards.js" as Cards

Page {
    id: mainPage

    Component.onCompleted:  {
        cardDavClient.getCardNamesAsync();
    }

    ListModel {
        id: cardModel
    }

    Component {
        id: cardDelegate
        ListItem {
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

    ProgressBar {
        id: progress
        anchors.centerIn: parent
        minimumValue: 0
        value: 0
    }

    Connections {
        target:cardDavClient;
        onCardNames:{
            progress.maximumValue = names.length;
            Cards.startQuerying(names);
        }
        onCard:{
            console.log(card);
            var item = Cards.cardDone(cardName, card);
            cardModel.append(item);
            progress.value ++;
        }
    }

}
