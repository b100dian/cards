var max = 10,
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
    var result = {};
    for (var l in lines) {
        if (lines[l].indexOf("FN:") === 0) {
            result.fullname = lines[l].slice(3,-1);
        } else if (lines[l].indexOf("TEL;TYPE=CELL:") === 0) {
            result.cell = lines[l].slice(14,-1);
        }

    }
    return result;
}
