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
        Row {
            spacing: 10
            Text { text: fullname}
        }
    }

    ListView{
        id: cardList
        anchors.fill: parent
        model: cardModel
        delegate: cardDelegate
    }

    ProgressBar {
        id: progress
        anchors.horizontalCenter: parent
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
            var a = Cards.cardDone(cardName, card);
            cardModel.append({fullname:a});
            progress.value ++;
        }
    }

}
