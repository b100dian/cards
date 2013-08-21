var max = 5,
    connections = 0,
    i = 0,
    allNames=null;

function startQuerying(names, model) {
    allNames = names;
    while(connections < max) {
        if (!nextCard()) break; //less cards than max connections
    }
}

function cardDone(name, data, done) {
    connections--;
    var more = nextCard();
    if (!more) {
        done();
    }

    return data;
}

function nextCard() {
    if (i < allNames.length) {
        connections++;
        cardDavClient.getCardAsync(allNames[i]);
        i++;
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
    var result = {tels:[], mails:[], tel:"", mail:""};
    for (var l in lines) {
        if (lines[l].indexOf("FN:") === 0) {
            result.fullname = lines[l].slice(3,-1);
        } else if (r = telreg.exec(lines[l])) {
            do {
                result.tel += (result.tel.length?",":"") + r[1];
                result.tels.push({t:r[1]});
            } while (r = telreg.exec(lines[l]));
        } else if (r = mailreg.exec(lines[l])) {
            do {
                result.mail += r[1]+",";
                result.mails.push({m:r[1]});
            } while (r = mailreg.exec(lines[l]));
        }
    }
    return result;
}

function getAccessToken(code, success, error) {
    var xhr = new XMLHttpRequest();
    xhr.open("POST", "https://accounts.google.com/o/oauth2/token", true);
    xhr.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
    var params = {
        code:code,
        client_id:window.client_id,
        client_secret:window.client_secret,
        redirect_uri:"urn:ietf:wg:oauth:2.0:oob",
        grant_type:"authorization_code"
    };
    var paramsStr = Object.keys(params).map(
            function(k){return k+"="+encodeURIComponent(params[k]);}
            ).join("&");

    xhr.onreadystatechange = function (e) {
        if (xhr.readyState == 4) {
            if (xhr.status == 200) {
                var response = JSON.parse(xhr.responseText);
                success(response);
            } else {
                console.log("XHR Error:" + xhr.statusText);
            }
        }
    }

    xhr.onerror = function (e) {
        console.log("XHR Error:" + xhr.statusText);
    }

    xhr.send(paramsStr);
}
