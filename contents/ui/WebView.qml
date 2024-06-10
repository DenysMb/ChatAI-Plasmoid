import QtQuick
import QtWebEngine
import QtQuick.Layouts 1.1
import org.kde.plasma.extras 2.0 as PlasmaExtras
import org.kde.plasma.plasmoid 2.0

Item {
    Layout.fillWidth: true
    Layout.fillHeight: true

    PlasmaExtras.Menu {
        id: linkContextMenu
        visualParent: webview

        property string link

        PlasmaExtras.MenuItem {
            text: i18nc("@action:inmenu", "Open Link in Browser")
            icon:  "internet-web-browser"
            onClicked: Qt.openUrlExternally(linkContextMenu.link)
        }

        PlasmaExtras.MenuItem {
            text: i18nc("@action:inmenu", "Copy Link Address")
            icon: "edit-copy"
            onClicked: webview.triggerWebAction(WebEngineView.CopyLinkToClipboard)
        }
    }

    WebEngineView {
        id: webview
        anchors.fill: parent
        url: plasmoid.configuration.url;

        WebEngineProfile {
            id: webProfile
            httpUserAgent: getUserAgent()
            storageName: "chat-ai"
            offTheRecord: false
            httpCacheType: WebEngineProfile.DiskHttpCache
            persistentCookiesPolicy: WebEngineProfile.ForcePersistentCookies
        }

        profile: webProfile

        onLinkHovered: hoveredUrl => {
            if (hoveredUrl.toString() !== "") {
                mouseArea.cursorShape = Qt.PointingHandCursor;
            } else {
                mouseArea.cursorShape = Qt.ArrowCursor;
            }
        }

        onContextMenuRequested: request => {
            if (request.mediaType === ContextMenuRequest.MediaTypeNone && request.linkUrl.toString() !== "") {
                linkContextMenu.link = request.linkUrl;
                linkContextMenu.open(request.position.x, request.position.y);
                request.accepted = true;
            }
        }

        onNavigationRequested: request => {
            if (request.navigationType == WebEngineNavigationRequest.NavigationTypeLinkClicked) {
                if (request.userInitiated) {
                    Qt.openUrlExternally(request.url);
                    request.action = WebEngineNavigationRequest.IgnoreRequest;
                } else {
                    request.action = WebEngineNavigationRequest.CancelRequest;
                }
            }
        }

        onIconChanged: {
            if (loading && icon == "") {
                return;
            }

            Plasmoid.configuration.favIcon = icon.toString().slice(16);
        }
    }

    MouseArea {
        id: mouseArea

        anchors.fill: parent

        acceptedButtons: Qt.BackButton | Qt.ForwardButton

        onPressed: mouse => {
            if (mouse.button === Qt.BackButton) {
                webview.goBack();
            } else if (mouse.button === Qt.ForwardButton) {
                webview.goForward();
            }
        }
    }

    function goBackToHomePage() {
        webview.url = plasmoid.configuration.url;
    }

    function getUserAgent() {
        return plasmoid.configuration.url.includes("https://duckduckgo.com")
            ? "Mozilla/5.0 (Linux; Android 9; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/76.0.3809.111 Mobile Safari/537.36"
            : "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/89.0.4389.90 Safari/537.36"
    }
}