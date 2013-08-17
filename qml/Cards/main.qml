import QtQuick 1.1
import com.nokia.symbian 1.1
import com.nokia.extras 1.1

PageStackWindow {
    id: window
    initialPage: MainPage {tools: toolBarLayout}
    showStatusBar: true
    showToolBar: true

    property string client_id: "244047469353.apps.googleusercontent.com"
    property string client_secret: "P3OTFvRVwLWacPAQKbAZgG57"
    property bool useOAuth: true

    SettingsPage { id:settingsPage }

    OAuthPage { id:oAuthPage }

    InfoBanner { id:banner; timeout:4000 }

    ToolBarLayout {
        id: toolBarLayout
        ToolButton {
            flat: true
            iconSource: "toolbar-back"
            onClicked: window.pageStack.depth <= 1 ? Qt.quit() : window.pageStack.pop()
        }
/*        ToolButton {
            flat: true
            iconSource: "toolbar-search"
            onClicked: { banner.text = "Not yet implemented."; banner.open();}
        }
        ToolButton {
            flat: true
            iconSource: "toolbar-refresh"
            onClicked: { banner.text = "Not yet implemented."; banner.open();}
        }
*/        ToolButton {
            flat: true
            iconSource: "toolbar-settings"
            onClicked: window.pageStack.push(settingsPage);
        }
    }


    function goToOAuth() {
        window.pageStack.push(oAuthPage);
    }

    function goToSettings() {
        window.pageStack.push(settingsPage);
    }

    function goToMainPage() {
        window.pageStack.push(window.initialPage);
    }


}
