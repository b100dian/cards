var max = 3,
    connections = 0,
    i = 0,
    allNames=null;

function startQuerying(names, model) {
    allNames = names;
    while(connections < max) {
        nextCard();
    }
}

function cardDone(name, data) {
    connections--;
    nextCard();

    return parseCard(data);
}

function nextCard() {
    i++;
    if (i < allNames.length) {
        connections++;
        cardDavClient.getCardAsync(allNames[i]);
    } else {
        //done
    }
}

function parseCard(c) {
    var lines = c.split('\n');
    for (var l in lines) {
        if (lines[l].indexOf("FN:") == 0) {
            return lines[l].slice(3,-1);
        }
    }
    return "unknown";
}
