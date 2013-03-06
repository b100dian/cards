function getDatabase() {
    return openDatabaseSync("Cards", "1.0", "Contacts", 100000);
}

function initialize() {
    var db = getDatabase();
    db.transaction(function(tx) {
                       tx.executeSql('CREATE TABLE IF NOT EXISTS settings(setting TEXT UNIQUE, \"value\" TEXT)');
                       tx.executeSql('CREATE TABLE IF NOT EXISTS contacts(id TEXT UNIQUE, name TEXT, card TEXT)');
                   });
}

function haveCredentials(callback, error) {
    var db = getDatabase();

    function selectCredentials(tx) {
        var result = tx.executeSql("SELECT setting, \"value\" FROM settings WHERE setting = 'user' OR setting = 'password' ORDER BY setting DESC",
                                   []);

        if (result.rows.length !== 2){
            error();
        } else {
            console.log ("ROWs"+JSON.stringify(result.rows));
            var user = result.rows[0].value;
            var password = result.rows[1].value;
            callback(user, password);
        }
    };

    db.transaction(selectCredentials);
}

function storeCredentials(username, password) {
    var db = getDatabase();

    function insertCredentials(tx) {
        tx.executeSql("INSERT OR REPLACE INTO settings (setting, value) VALUES ('user', ?) , ('password', ?)", [username, password]);
    }
}
