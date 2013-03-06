import QtQuick 1.1
import com.nokia.symbian 1.1

Page {
    id:settingsPage
    tools:toolBarLayout
    Column {
        Row {
            Label {
                text: "Username:"
            }

            TextField {
                id:userField;
            }
        }
        Row {
            Label {
                text: "Password:"
            }

            TextField {
                id:passwordField;
            }
        }
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
            iconSource: "gfx/icon-m-toolbar-done-white.png"
            onClicked: window.pageStack.depth <= 1 ? Qt.quit() : window.pageStack.pop()
        }
    }
}
