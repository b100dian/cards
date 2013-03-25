var accountId = 1;
var accountUrl = 'https://google.com/.well-known/carddav';

function getDatabase() {
    return openDatabaseSync("Cards", "1.0", "Contacts", 100000);
}

function initialize() {
    var db = getDatabase();
    var createTables = function(tx) {
        // migration from 0.1 to 0.2
        tx.executeSql('DROP TABLE IF EXISTS contacts');

        // settings
        tx.executeSql('CREATE TABLE IF NOT EXISTS settings(setting TEXT UNIQUE, value TEXT)');

        // accounts
        tx.executeSql('CREATE TABLE IF NOT EXISTS accounts(accountId INTEGER PRIMARY KEY, url TEXT, username TEXT, password TEXT)')

        // raw remote cards
        tx.executeSql('CREATE TABLE IF NOT EXISTS cards(accountId INTEGER, cardid TEXT, etag TEXT, card TEXT)');

        // remote cards parsed details
        // TODO detailId?
        //tx.executeSql('CREATE TABLE IF NOT EXISTS card_details(accountId INTEGER, cardid TEXT UNIQUE, detailname TEXT, detailvalue TEXT)');

        // new raw remote cards list, for updating diff only
        tx.executeSql('CREATE TABLE IF NOT EXISTS newcards(accountId INTEGER, cardid TEXT, etag TEXT)');

        // TODO local contacts

    }

    db.transaction(createTables);
}

function haveCredentials(callback, error) {
    var db = getDatabase();

    function selectCredentials(tx) {
        // query new location
        var result = tx.executeSql("SELECT username, password FROM accounts WHERE accountId = ?", [accountId]);

        if (result.rows.length === 1) {
            callback(result.rows.item(0).username, result.rows.item(0).password);
        } else {
            console.log ("What, you again!?");
            // query old location
            result = tx.executeSql("SELECT setting, value FROM settings WHERE setting = 'user' OR setting = 'password' ORDER BY setting DESC",
                                   []);
            if (result.rows.length !== 2){
                error();
            } else {
                var user = result.rows.item(0).value;
                var password = result.rows.item(1).value;

                // migrate them to new location
                tx.executeSql("INSERT OR REPLACE INTO accounts (accountId, url, username, password) VALUES (?,?,?,?)",
                              [accountId, accountUrl, user, password]);
                tx.executeSql("DELETE FROM settings WHERE setting = 'user' OR setting='password'");

                callback(user, password);
            }
        }
    };

    db.transaction(selectCredentials);
}

function storeCredentials(username, password) {
    var db = getDatabase();

    function insertCredentials(tx) {
        var inserted = tx.executeSql("INSERT OR REPLACE INTO accounts (accountId, url, username, password) VALUES (?, ?, ?, ?)",
                                     [accountId, accountUrl, username, password])
            .rowsAffected;
        console.log("INSERTED:" + inserted);
    }

    db.transaction(insertCredentials);
}

/** returns the displaNames to query further */
function determineNewNames(names) {
    var db = getDatabase();

    var toInsertOrUpdate = [];

    function determine(tx) {
        tx.executeSql("DELETE FROM newcards WHERE accountId = ?", accountId);
        var name, etag;
        for (var i in names) {


            var split = names[i].split('`');
            name = split[0];
            etag = split[1];

            if (name == 'default') continue; // sorry Mr. Default, but thats some weird cardID

            tx.executeSql("INSERT INTO newcards (accountId, cardid, etag) VALUES (?,?,?)",
                          [accountId, name, etag]);
        }

        var result = tx.executeSql("SELECT newcards.cardid FROM newcards LEFT JOIN cards " +
                                   "ON newcards.cardid = cards.cardid AND newcards.etag = cards.etag " +
                                   "AND newcards.accountId = cards.accountId " +
                                   "WHERE newcards.accountID = ? AND cards.cardid IS NULL",
                                   [accountId]);
        console.log("Join returned " + result.rows.length + " new from " + names.length + " total.");
        for (var j = 0, length = result.rows.length; j<length; j++) {
            toInsertOrUpdate.push(result.rows.item(j).cardid);
        }
    }
    db.transaction(determine);
    return toInsertOrUpdate;
}

function appendNewCard(name, card) {
    var db = getDatabase();
    function append(tx) {
        var result = tx.executeSql("INSERT OR REPLACE INTO cards (accountid, cardid, etag, card) " +
                                   "SELECT accountid, cardid, etag, ? FROM newcards WHERE " +
                                   "cardid = ? AND accountid = ?",
                                   [card, name, accountId]);
        console.log("Inserted " + result.rowsAffected);
    }

    db.transaction(append);
}

function getExistingCards() {
    var db = getDatabase();
    var existing = [];
    function get(tx) {
        var result = tx.executeSql("SELECT card FROM cards WHERE accountId = ?", [accountId]);
        for (var i = 0, length = result.rows.length; i<length; i++) {
            existing.push(result.rows.item(i).card);
        }
    }
    db.transaction(get);
    return existing;
}
