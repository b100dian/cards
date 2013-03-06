import QtQuick 1.1
import com.nokia.symbian 1.1
import com.nokia.extras 1.1

PageStackWindow {
    id: window
    initialPage: MainPage {tools: toolBarLayout}
    showStatusBar: true
    showToolBar: true

    property string username;
    property string password;

    SettingsPage {
        id:settingsPage
    }

    InfoBanner {
        id:banner
        timeout:4000
    }

    ToolBarLayout {
        id: toolBarLayout
        ToolButton {
            flat: true
            iconSource: "toolbar-back"
            onClicked: window.pageStack.depth <= 1 ? Qt.quit() : window.pageStack.pop()
        }
        ToolButton {
            flat: true
            iconSource: "toolbar-search"
        }
        ToolButton {
            flat: true
            iconSource: "toolbar-refresh"
            checkable: true
            onCheckedChanged: {
                if (checked) {
                    cardDavClient.getCardNamesAsync();
                } else {

                }

            }
        }
        ToolButton {
            flat: true
            iconSource: "toolbar-settings"
            onClicked: window.pageStack.push(settingsPage);
        }
    }


    function goToSettings() {
        window.pageStack.push(settingsPage);
    }

    function goToMainPage() {
        window.pageStack.push(window.initialPage);
    }


}
