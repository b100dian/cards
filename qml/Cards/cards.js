var max = 5,
    connections = 0,
    i = 0,
    allNames=null;

function startQuerying(names, model) {
    allNames = names;
    while(connections < max) {
        nextCard();
    }
}

function cardDone(name, data, done) {
    connections--;
    var more = nextCard();
    if (!more) done();

    return parseCard(data);
}

function nextCard() {
    i++;
    if (i < allNames.length) {
        connections++;
        cardDavClient.getCardAsync(allNames[i]);
        return true;
    } else {
        return false;
    }
}

function parseCard(c) {
    var telreg = /TEL.*:(.*)/g;
    var mailreg = /EMAIL.*:(.*)/g;
    var lines = c.split('\n');
    var r;
    var result = {tels:[], mails:[]};
    for (var l in lines) {
        if (lines[l].indexOf("FN:") === 0) {
            result.fullname = lines[l].slice(3,-1);
        } else if (r = telreg.exec(lines[l])) {
            do {
                result.tel = (result.tel?" ":"") + r[1];
                result.tels.push(r[1]);
            } while (r = telreg.exec(lines[l]));
        } else if (r = mailreg.exec(lines[l])) {
            do {
                result.mail = (result.mail?" ":"") + r[1];
                result.mails.push(r[1]);
            } while (r = mailreg.exec(lines[l]));
        }
    }
    return result;
}
