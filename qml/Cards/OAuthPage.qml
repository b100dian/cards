import com.nokia.symbian 1.1
import QtQuick 1.1
import QtWebKit 1.0

import "cards.js" as Cards

Page {
    id:settingsPage
    tools:toolBarLayout

    Flickable {
        id: flickable
        width: parent.width
        contentWidth: Math.max(parent.width,loginView.width)
        contentHeight: Math.max(parent.height,loginView.height)
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        WebView {
            id: loginView
            url: "https://accounts.google.com/o/oauth2/auth?scope=email+" +
                 "https%3A%2F%2Fwww.google.com%2Fm8%2Ffeeds" +
                 //"https%3A%2F%2Fwww.googleapis.com%2Fauth%2Fuserinfo.email" +
                 //%20https%3A%2F%2Fwww.googleapis.com%2Fauth%2Fuserinfo.profile" +
                 "&redirect_uri=urn:ietf:wg:oauth:2.0:oob&response_type=code&client_id=" + window.client_id
            onTitleChanged: {
                console.log("new title:" + title);
                // detecting 4/blabasdfasdf
                var slashPos = title.indexOf("/");
                if (slashPos > 1 && title[slashPos - 1]<='9' && title[slashPos - 1] >= '0') {
                    Cards.getAccessToken(title.substring(slashPos - 1), function (accessToken) {
                        cardDavClient.setToken(accessToken);
                        window.pageStack.depth <= 1 ? window.goToMainPage() : window.pageStack.pop();
                                         });
                    console.log ("waiting for access token.");
                }
            }
            settings.localStorageDatabaseEnabled: true
            settings.offlineStorageDatabaseEnabled: true
            focus: true
            onAlert: console.log(message)

            function doZoom(zoom,centerX,centerY)
            {
                if (centerX) {
                    var sc = zoom*contentsScale;
                    scaleAnim.to = sc;
                    flickVX.from = flickable.contentX
                    flickVX.to = Math.max(0,Math.min(centerX-flickable.width/2,loginView.width*sc-flickable.width))
                    finalX.value = flickVX.to
                    flickVY.from = flickable.contentY
                    flickVY.to = Math.max(0,Math.min(centerY-flickable.height/2,loginView.height*sc-flickable.height))
                    finalY.value = flickVY.to
                    quickZoom.start()
                }
            }
            preferredWidth: flickable.width
            preferredHeight: flickable.height
            contentsScale: 1
            onContentsSizeChanged: {
                // zoom out
                contentsScale = Math.min(1,flickable.width / contentsSize.width)
            }
            onUrlChanged: {
                // got to topleft
                flickable.contentX = 0
                flickable.contentY = 0
                console.log("URL:"+url+":")
            }
            onDoubleClick: {
                            if (!heuristicZoom(clickX,clickY,2.5)) {
                                var zf = flickable.width / contentsSize.width
                                if (zf >= contentsScale)
                                    zf = 2.0*contentsScale // zoom in (else zooming out)
                                doZoom(zf,clickX*zf,clickY*zf)
                             }
                           }
            SequentialAnimation {
                id: quickZoom

                PropertyAction {
                    target: loginView
                    property: "renderingEnabled"
                    value: false
                }
                ParallelAnimation {
                    NumberAnimation {
                        id: scaleAnim
                        target: loginView
                        property: "contentsScale"
                        // the to property is set before calling
                        easing.type: Easing.Linear
                        duration: 200
                    }
                    NumberAnimation {
                        id: flickVX
                        target: flickable
                        property: "contentX"
                        easing.type: Easing.Linear
                        duration: 200
                        from: 0 // set before calling
                        to: 0 // set before calling
                    }
                    NumberAnimation {
                        id: flickVY
                        target: flickable
                        property: "contentY"
                        easing.type: Easing.Linear
                        duration: 200
                        from: 0 // set before calling
                        to: 0 // set before calling
                    }
                }
                // Have to set the contentXY, since the above 2
                // size changes may have started a correction if
                // contentsScale < 1.0.
                PropertyAction {
                    id: finalX
                    target: flickable
                    property: "contentX"
                    value: 0 // set before calling
                }
                PropertyAction {
                    id: finalY
                    target: flickable
                    property: "contentY"
                    value: 0 // set before calling
                }
                PropertyAction {
                    target: loginView
                    property: "renderingEnabled"
                    value: true
                }
            }
            onZoomTo: doZoom(zoom,centerX,centerY)
        }
    }

    ToolBarLayout {
        id: toolBarLayout
        ToolButton {
            flat: true
            iconSource: "toolbar-back"
            onClicked: window.pageStack.depth <= 1 ? Qt.quit() : window.pageStack.pop()
        }
    }
}
