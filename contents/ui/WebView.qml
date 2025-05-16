import QtCore
import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import QtQuick.LocalStorage 2.0
import QtWebEngine
import Qt.labs.platform 1.1
import org.kde.plasma.components as PlasmaComponents3
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.extras as PlasmaExtras
import org.kde.plasma.plasmoid
import org.kde.notification 1.0
import org.kde.kirigami 2.19 as Kirigami

Item {
    id: webViewRoot

    function goBackToHomePage() {
        webview.url = plasmoid.configuration.url;
    }

    function goBack() {
        webview.goBack();
    }

    function goForward() {
        webview.goForward();
    }

    function reloadPage() {
        webview.reloadAndBypassCache();
    }

    function printPage() {
        webview.runJavaScript("document.title", function(title) {
            let downloadDirectory = plasmoid.configuration.downloadPath ? 
                plasmoid.configuration.downloadPath.toString().replace(/^file:\/\//, '') : 
                StandardPaths.writableLocation(StandardPaths.DownloadLocation);
                
            let timestamp = new Date().toISOString().replace(/[:.]/g, '-');
            let safeName = title.replace(/[^a-z0-9]/gi, '-').toLowerCase();
            let filename = `${downloadDirectory}/${safeName}-${timestamp}.pdf`;

            // Add the PDF as a special type of download
            let pdfIndex = webview.downloads.addDownload(null, `${safeName}-${timestamp}.pdf`, filename, true);
            
            // Store the PDF index for future reference
            let currentPdfIndex = pdfIndex;
            
            webview.printToPdf(filename, WebEngineView.A4, WebEngineView.Portrait);
        });
    }

    function saveMHTML() {
        webview.runJavaScript("document.title", function(title) {
            let downloadDirectory = plasmoid.configuration.downloadPath ? 
                plasmoid.configuration.downloadPath.toString().replace(/^file:\/\//, '') : 
                StandardPaths.writableLocation(StandardPaths.DownloadLocation);
                
            let timestamp = new Date().toISOString().replace(/[:.]/g, '-');
            let safeName = title.replace(/[^a-z0-9]/gi, '-').toLowerCase();
            let filename = `${downloadDirectory}/${safeName}-${timestamp}.mhtml`;
            
            webview.triggerWebAction(WebEngineView.SavePage, filename);
        });
    }


    function getUserAgent() {
        return plasmoid.configuration.url.includes("https://duckduckgo.com") || plasmoid.configuration.url.includes("x.com/i/grok")
            ? "Mozilla/5.0 (Linux; Android 9; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/76.0.3809.111 Mobile Safari/537.36"
            : ""
    }

    Notification {
        id: webNotification
        componentName: "chatai_plasmoid"
        eventId: "notification"
        defaultAction: i18n("Open")
        title: i18n("ChatAI")
        iconName: "dialog-information"
    }

    function showNotification(title, message, icon = "dialog-information") {
        webNotification.title = title || i18n("ChatAI")
        webNotification.text = message
        webNotification.iconName = icon
        webNotification.sendEvent()
    }

    function getProgressPath(path) {
        // For the progress bar, it needs file:///
        return "file:///" + path.replace(/^\/+/, '');
    }

    function getOpenPath(path) {
        // To open the file, it cannot have file://
        return path.replace(/^file:\/+/, '').replace(/^\/+/, '/');
    }

    // Add this helper function before the WebEngineView
    function isDownloadInProgress(fileName) {
        if (!webview || !webview.downloads) return false;
        
        for (let i = 0; i < webview.downloads.count; i++) {
            let item = webview.downloads.get(i);
            if (item && item.state === WebEngineDownloadRequest.DownloadInProgress && 
                item.fileName === fileName) {
                return true;
            }
        }
        return false;
    }

    Layout.fillWidth: true
    Layout.fillHeight: true

    property bool findBarVisible: false

    onFindBarVisibleChanged: {
        if (findBarVisible) {
            findField.forceActiveFocus();
            findField.selectAll();
        } else {
            webview.findText(""); // Clear any existing search
        }
    }

    Shortcut {
        sequence: StandardKey.Find
        onActivated: findBarVisible = true
    }

    PlasmaExtras.Menu {
        id: linkContextMenu

        property string link

        visualParent: webview

        PlasmaExtras.MenuItem {
            text: i18n("Back")
            icon: "go-previous"
            enabled: webview.canGoBack
            onClicked: webview.goBack()
        }

        PlasmaExtras.MenuItem {
            text: i18n("Forward")
            icon: "go-next"
            enabled: webview.canGoForward
            onClicked: webview.goForward()
        }

        PlasmaExtras.MenuItem {
            text: i18n("Reload")
            icon: "view-refresh"
            onClicked: reloadPage()
        }

        PlasmaExtras.MenuItem {
            text: i18n("Save as PDF")
            icon: "document-save-as"
            visible: !linkContextMenu.link
            onClicked: printPage()
        }

        PlasmaExtras.MenuItem {
            text: i18n("Save as MHTML")
            icon: "document-save"
            visible: !linkContextMenu.link
            onClicked: saveMHTML()
        }

        PlasmaExtras.MenuItem {
            text: i18n("Open Link in Browser")
            icon: "internet-web-browser"
            visible: linkContextMenu.link !== ""
            onClicked: Qt.openUrlExternally(linkContextMenu.link)
        }

        PlasmaExtras.MenuItem {
            text: i18n("Copy Link Address")
            icon: "edit-copy"
            visible: linkContextMenu.link !== ""
            onClicked: webview.triggerWebAction(WebEngineView.CopyLinkToClipboard)
        }

    }

    WebEngineView {
        id: webview

        property var downloadCache: ({})

        property var downloads: ListModel {
            function addDownload(downloadItem, fileName, path, isPdf) {
                let downloadId = Date.now().toString();
                let download = {
                    "downloadId": downloadId,
                    "fileName": fileName,
                    "fullPath": path,
                    "progress": 0,
                    "receivedBytes": 0,
                    "totalBytes": downloadItem ? downloadItem.totalBytes : 0,
                    "isPdfExport": isPdf,
                    "state": WebEngineDownloadRequest.DownloadInProgress
                };

                if (downloadItem) {
                    // Store reference in cache
                    webview.downloadCache[downloadId] = downloadItem;
                }

                this.append(download);
                return this.count - 1;
            }

            function removeDownload(index) {
                let item = this.get(index);
                if (item && item.downloadId) {
                    delete webview.downloadCache[item.downloadId];
                }
                this.remove(index);
            }
        }

        function checkAndUpdateFavicon() {
            // Use the last known favicon while loading the new one
            if (Plasmoid.configuration.lastFavIcon)
                Plasmoid.configuration.favIcon = Plasmoid.configuration.lastFavIcon;

            // Parse page HTML for favicon information
            webview.runJavaScript(`
                function findFaviconInHTML() {
                    const icons = [];
                    // 1. Search meta tags first
                    const metas = document.getElementsByTagName('meta');
                    for (let i = 0; i < metas.length; i++) {
                        const property = metas[i].getAttribute('property');
                        if (property === 'og:image') {
                            const content = metas[i].getAttribute('content');
                            if (content) icons.push({ href: content, size: 64 });
                        }
                    }

                    // 2. Search for link tags
                    const links = document.getElementsByTagName('link');
                    for (let i = 0; i < links.length; i++) {
                        const rel = links[i].getAttribute('rel');
                        if (rel && (rel.includes('icon') || rel.includes('shortcut'))) {
                            const href = links[i].getAttribute('href');
                            const sizes = links[i].getAttribute('sizes');
                            if (href) {
                                icons.push({
                                    href: href,
                                    size: sizes ? parseInt(sizes.split('x')[0]) : 32
                                });
                            }
                        }
                    }

                    // 3. Check for default favicon.ico
                    if (icons.length === 0) {
                        icons.push({ href: '/favicon.ico', size: 32 });
                    }

                    // Sort by size
                    icons.sort((a, b) => b.size - a.size);

                    // Get the best icon
                    const bestIcon = icons[0];
                    if (!bestIcon) return null;

                    // Convert to absolute URL
                    const absoluteUrl = bestIcon.href.startsWith('http')
                        ? bestIcon.href
                        : new URL(bestIcon.href, window.location.origin).href;

                    return absoluteUrl;
                }
                findFaviconInHTML();
            `, function(result) {
                if (result) {
                    // Process WebEngine favicon result
                    if (result.startsWith('image://favicon/'))
                        result = result.replace('image://favicon/', '');

                    Plasmoid.configuration.favIcon = result;
                    Plasmoid.configuration.lastFavIcon = result;
                } else if (icon && icon.toString()) {
                    // Use WebEngine icon as fallback
                    let webEngineIcon = icon.toString();
                    if (webEngineIcon.startsWith('image://favicon/'))
                        webEngineIcon = webEngineIcon.replace('image://favicon/', '');

                    Plasmoid.configuration.favIcon = webEngineIcon;
                    Plasmoid.configuration.lastFavIcon = webEngineIcon;
                }
            });
        }

        anchors.fill: parent
        url: plasmoid.configuration.url
        profile: webProfile
        onLinkHovered: (hoveredUrl) => {
            if (hoveredUrl == "") {
                hideStatusText.start();
            } else {
                statusText.text = hoveredUrl;
                statusBubble.visible = true;
                hideStatusText.stop();
            }
            if (hoveredUrl.toString() !== "")
                mouseArea.cursorShape = Qt.PointingHandCursor;
            else
                mouseArea.cursorShape = Qt.ArrowCursor;
        }
        onContextMenuRequested: (request) => {
            // Use default menu for special elements (text fields, selection, etc)
            if (request.isContentEditable || request.selectedText || request.mediaType !== ContextMenuRequest.MediaTypeNone) {
                request.accepted = false;  // Permite que o menu padrão apareça
                return;
            }

            // Update link only if there is a URL
            let hasLink = request.linkUrl.toString() !== "";
            linkContextMenu.link = hasLink ? request.linkUrl.toString() : "";

            // Always show our custom menu when it's not a special element
            linkContextMenu.open(request.position.x, request.position.y);
            request.accepted = true;
        }

        // https://doc.qt.io/qt-6/qml-application-permissions.html
        onPermissionRequested: function(request) {
            if (request.permissionType === WebEnginePermission.Geolocation || request.permissionType === 8) {
                if (plasmoid.configuration.geolocationEnabled) {
                    request.grant();
                } else {
                    request.deny();
                }
                return;
            }
            if (request.permissionType === WebEnginePermission.Notifications) {
                if (plasmoid.configuration.notificationsEnabled) {
                    request.grant();
                } else {
                    request.deny();
                }
                return;
            }
            if (request.permissionType === WebEnginePermission.MediaAudioCapture || request.permissionType === 1 || request.permissionType === WebEnginePermission.MediaVideoCapture || request.permissionType === 2 || request.permissionType === 5) {
                let isMicrophoneRequest = request.permissionType === 1 || request.permissionType === WebEnginePermission.MediaAudioCapture;
                let isWebcamRequest = request.permissionType === 2 || request.permissionType === WebEnginePermission.MediaVideoCapture;
                let isScreenShareRequest = request.permissionType === 5 || request.permissionType === WebEnginePermission.DesktopAudioVideoCapture;
                return ;
            }
            // Even if MediaAudioCapture and MediaVideoCapture are allowed, it is still necessary to allow DesktopAudioVideoCapture
            if ( request.permissionType === WebEnginePermission.DesktopAudioVideoCapture  || request.permissionType === 3) {
                if ( WebEnginePermission.MediaAudioCapture && WebEnginePermission.MediaVideoCapture ) {
                    request.grant();
                } else {
                    request.deny();
                }
            }

            request.grant();
        }
        onLoadingChanged: {
            if (!webview.loading) {
                checkAndUpdateFavicon();
            }

            var isCompatibleModel = ['duckduckgo', 'chatgpt', 'google', 'claude', 'you'].some(site => plasmoid.configuration.url.includes(site));

            if (isCompatibleModel) {
                webview.runJavaScript("
                    document.addEventListener('keydown', function(event) {
                        if (event.key === 'Enter' && !event.shiftKey) {
                            var duckDuckGoButton = document.querySelector('button[type=submit]');
                            var chatGPTButton = document.querySelector('button[data-testid=\"send-button\"]');
                            var googleGeminiButton = document.querySelector('button.send-button');
                            var claudeButton = document.querySelector('button[aria-label=\"Send Message\"]');
                            
                            if (duckDuckGoButton) {
                                event.preventDefault();
                                duckDuckGoButton.click();
                                waitForTextareaEnabledAndFocus();
                            }

                            if (chatGPTButton) {
                                event.preventDefault();
                                chatGPTButton.click();
                                waitForTextareaEnabledAndFocus();
                            }

                            if (googleGeminiButton) {
                                event.preventDefault();
                                googleGeminiButton.click();
                                waitForTextareaEnabledAndFocus();
                            }

                            if (claudeButton) {
                                event.preventDefault();
                                claudeButton.click();
                                waitForTextareaEnabledAndFocus();
                            }
                        }
                    });

                    function waitForTextareaEnabledAndFocus() {
                        var attempts = 0;
                        var interval = 100;

                        var textareaFocusInterval = setInterval(function() {
                            var textarea = document.querySelector('textarea');
                            if (textarea && !textarea.disabled) {
                                clearInterval(textareaFocusInterval);
                                setTimeout(function() {
                                    textarea.focus();
                                }, 100);
                            }
                        }, interval);
                    }

                    waitForTextareaEnabledAndFocus();
                ");
            }
        }
        onFeaturePermissionRequested: function(securityOrigin, feature) {
            if (feature === WebEngineView.MediaAudioCapture)
                grantFeaturePermission(securityOrigin, feature, plasmoid.configuration.microphoneEnabled);
            else if (feature === WebEngineView.MediaVideoCapture)
                grantFeaturePermission(securityOrigin, feature, plasmoid.configuration.webcamEnabled);
            else if (feature === WebEngineView.DesktopAudioVideoCapture)
                grantFeaturePermission(securityOrigin, feature, plasmoid.configuration.screenShareEnabled);
        }

        onPrintRequested: function() {
            webview.triggerWebAction(WebEngineView.Print)
        }

        onPdfPrintingFinished: function(filePath, success) {
            // Find the index of the PDF download
            for (let i = 0; i < downloads.count; i++) {
                if (downloads.get(i).fullPath === filePath) {
                    if (success) {
                        downloads.setProperty(i, "state", WebEngineDownloadRequest.DownloadCompleted);
                    } else {
                        downloads.remove(i);
                    }
                    break;
                }
            }
        }

        // Helper function to check if it's an authentication URL
        function isAuthUrl(url) {
            const authDomains = [
                'accounts.google.com',
                'appleid.apple.com',
                'login.live.com',
                'github.com/login',
                'instagram.com/oauth',
                'facebook.com/oidc'
            ];
            return authDomains.some(domain => url.includes(domain));
        }

        // Add these handlers to intercept new windows and tabs
        onNewWindowRequested: function(request) {
            let url = request.requestedUrl.toString();
            if (isAuthUrl(url)) {
                webview.url = url;
                request.action = WebEngineNewWindowRequest.IgnoreRequest;
            } else {
                Qt.openUrlExternally(request.requestedUrl);
                request.action = WebEngineNewWindowRequest.IgnoreRequest;
            }
        }

        // Intercept links that try to open in new tab/window
        onNavigationRequested: function(request) {
            if (request.navigationType === WebEngineNavigationRequest.NavigationTypeRedirect || 
                request.navigationType === WebEngineNavigationRequest.NavigationTypeLinkClicked) {
                
                // If the link has target="_blank" or similar
                if (request.userInitiated && request.disposition !== WebEngineNavigationRequest.CurrentTabDisposition) {
                    let url = request.url.toString();
                    if (isAuthUrl(url)) {
                        webview.url = url;
                        request.action = WebEngineNavigationRequest.IgnoreRequest;
                    } else {
                        Qt.openUrlExternally(request.url);
                        request.action = WebEngineNavigationRequest.IgnoreRequest;
                    }
                }
            }
        }

        Component.onCompleted: {
            // Ensure the downloads model is initialized
            if (!downloads) {
                downloads = Qt.createQmlObject('import QtQml; ListModel {}', webview);
            }
        }

        WebEngineProfile {
            id: webProfile
            httpUserAgent: getUserAgent()
            storageName: "chat-ai"
            offTheRecord: false
            httpCacheType: WebEngineProfile.DiskHttpCache
            persistentCookiesPolicy: WebEngineProfile.ForcePersistentCookies
            persistentPermissionsPolicy: WebEngineProfile.AskEveryTime
            downloadPath: {
                if (plasmoid.configuration.downloadPath)
                    return plasmoid.configuration.downloadPath.toString().replace(/^file:\/\//, '');

                return StandardPaths.writableLocation(StandardPaths.DownloadLocation);
            }
            onPresentNotification: function(notification) {
                showNotification(notification.title, notification.message)
                notification.show()
            }
            onDownloadRequested: function(download) {
                // Ensure downloads model exists
                if (!webview.downloads) {
                    webview.downloads = Qt.createQmlObject('import QtQml; ListModel {}', webview);
                }

                let downloadDirectory = plasmoid.configuration.downloadPath ? 
                    plasmoid.configuration.downloadPath.toString().replace(/^file:\/\//, '') : 
                    StandardPaths.writableLocation(StandardPaths.DownloadLocation);
                
                if (!plasmoid.configuration.downloadPath) {
                    plasmoid.configuration.downloadPath = downloadDirectory;
                }

                download.downloadDirectory = downloadDirectory;

                // Check for duplicate downloads
                for (let i = 0; i < webview.downloads.count; i++) {
                    let currentDownload = webview.downloads.get(i);
                    if (currentDownload.state === WebEngineDownloadRequest.DownloadInProgress && 
                        currentDownload.fileName === download.downloadFileName &&
                        !currentDownload.isPdfExport) {
                        showNotification(
                            i18n("Download in progress"),
                            i18n("The file '%1' is already being downloaded", download.downloadFileName),
                            "dialog-warning"
                        );
                        download.cancel();
                        return;
                    }
                }

                // Create a unique ID for this download
                let downloadId = Date.now().toString() + Math.random().toString(36).substring(7);
                
                let downloadIndex = webview.downloads.addDownload(
                    download,
                    download.downloadFileName,
                    downloadDirectory + "/" + download.downloadFileName,
                    false
                );

                // Store the index in the download object for reference
                let currentIndex = downloadIndex;

                // Create independent connections for each download
                let bytesConnection = function() {
                    if (currentIndex >= 0 && currentIndex < webview.downloads.count) {
                        let currentProgress = download.receivedBytes / download.totalBytes;
                        webview.downloads.setProperty(currentIndex, "progress", currentProgress);
                        webview.downloads.setProperty(currentIndex, "receivedBytes", download.receivedBytes);
                        webview.downloads.setProperty(currentIndex, "totalBytes", download.totalBytes);
                    }
                }

                let stateConnection = function(state) {
                    if (currentIndex >= 0 && currentIndex < webview.downloads.count) {
                        webview.downloads.setProperty(currentIndex, "state", state);
                        if (state === WebEngineDownloadRequest.DownloadCompleted) {
                            webview.downloads.setProperty(currentIndex, "progress", 1.0);
                        }
                        // Clear connections after completion or cancellation
                        if (state === WebEngineDownloadRequest.DownloadCompleted || 
                            state === WebEngineDownloadRequest.DownloadCancelled) {
                            download.receivedBytesChanged.disconnect(bytesConnection);
                            download.stateChanged.disconnect(stateConnection);
                            delete webview.downloadCache[downloadId];
                        }
                    }
                }

                // Connect signals to the updated functions
                download.receivedBytesChanged.connect(bytesConnection);
                download.stateChanged.connect(stateConnection);

                // Store all relevant information in the cache
                webview.downloadCache[downloadId] = {
                    download: download,
                    index: currentIndex,
                    bytesConnection: bytesConnection,
                    stateConnection: stateConnection
                };

                // Atualizar o modelo com o ID único
                webview.downloads.setProperty(currentIndex, "downloadId", downloadId);

                download.accept();
            }
        }
        // https://doc.qt.io/qt-6/qml-qtwebengine-webenginesettings.html
        settings {
            spatialNavigationEnabled: plasmoid.configuration.spatialNavigationEnabled
            allowWindowActivationFromJavaScript: true
            javascriptCanAccessClipboard: plasmoid.configuration.javascriptCanAccessClipboard
            javascriptCanOpenWindows: plasmoid.configuration.javascriptCanOpenWindows
            javascriptCanPaste: plasmoid.configuration.javascriptCanPaste
            unknownUrlSchemePolicy: plasmoid.configuration.allowUnknownUrlSchemes ? WebEngineSettings.AllowAllUnknownUrlSchemes : WebEngineSettings.DisallowUnknownUrlSchemes
            playbackRequiresUserGesture: plasmoid.configuration.playbackRequiresUserGesture
            focusOnNavigationEnabled: plasmoid.configuration.focusOnNavigationEnabled
            screenCaptureEnabled: true
            pluginsEnabled: true
            forceDarkMode: {
                const hex = PlasmaCore.Theme.backgroundColor.toString().substring(1);
                const r = parseInt(hex.substring(0, 2), 16);
                const g = parseInt(hex.substring(2, 4), 16);
                const b = parseInt(hex.substring(4, 6), 16);
                const luma = 0.2126 * r + 0.7152 * g + 0.0722 * b;
                return luma < 128;
            
            }
        }
}

    MouseArea {
        id: mouseArea

        anchors.fill: parent
        acceptedButtons: Qt.BackButton | Qt.ForwardButton
        onPressed: (mouse) => {
            if (mouse.button === Qt.BackButton)
                webview.goBack();
            else if (mouse.button === Qt.ForwardButton)
                webview.goForward();
        }
    }

    Rectangle {
        id: statusBubble

        property int padding: 8

        color: PlasmaCore.Theme.backgroundColor
        visible: false
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        width: statusText.paintedWidth + padding
        height: statusText.paintedHeight + padding

        Text {
            id: statusText

            anchors.centerIn: statusBubble
            elide: Qt.ElideMiddle
            color: PlasmaCore.Theme.textColor

            Timer {
                id: hideStatusText

                interval: 750
                onTriggered: {
                    statusText.text = "";
                    statusBubble.visible = false;
                }
            }

        }

    }

    Column {
        id: downloadsBar

        visible: webview.downloads.count > 0
        spacing: 4

        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }

        Repeater {
            model: webview.downloads

            delegate: Rectangle {
                width: parent.width
                height: 40
                color: PlasmaCore.Theme.backgroundColor
                opacity: 0.9

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 8

                    PlasmaComponents3.Label {
                        text: {
                            if (model.state === WebEngineDownloadRequest.DownloadCompleted) {
                                return model.fileName + " - Completed";
                            }
                            if (model.isPdfExport) {
                                return model.fileName + " - Saving PDF...";
                            }
                            let progress = Math.round((model.progress || 0) * 100);
                            let size = "";
                            if (model.totalBytes > 0) {
                                let received = (model.receivedBytes / 1024 / 1024).toFixed(1);
                                let total = (model.totalBytes / 1024 / 1024).toFixed(1);
                                size = ` (${received}/${total} MB)`;
                            }
                            return model.fileName + " - " + progress + "%" + size;
                        }
                        Layout.fillWidth: true
                        elide: Text.ElideMiddle
                    }
                    // Progress bar (visible during download)
                    PlasmaComponents3.ProgressBar {
                        Layout.fillWidth: true
                        indeterminate: model.isPdfExport
                        from: 0
                        to: 1
                        value: model.progress || 0
                        visible: model.state === WebEngineDownloadRequest.DownloadInProgress
                    }
                    // Buttons shown after download completion
                    RowLayout {
                        visible: model.state === WebEngineDownloadRequest.DownloadCompleted
                        spacing: 4

                        PlasmaComponents3.Button {
                            icon.name: "document-open"
                            PlasmaComponents3.ToolTip.text: i18n("Open file")
                            PlasmaComponents3.ToolTip.visible: hovered
                            onClicked: {
                                if (model.fullPath) {
                                    let openPath = getOpenPath(model.fullPath);
                                    Qt.openUrlExternally(openPath);
                                }
                            }
                        }

                        PlasmaComponents3.Button {
                            icon.name: "folder-open"
                            PlasmaComponents3.ToolTip.text: i18n("Open folder")
                            PlasmaComponents3.ToolTip.visible: hovered
                            onClicked: {
                                if (model.fullPath) {
                                    let dirPath = model.fullPath.substring(0, model.fullPath.lastIndexOf("/"));
                                    let openPath = getOpenPath(dirPath);
                                    Qt.openUrlExternally(openPath);
                                }
                            }
                        }

                        PlasmaComponents3.Button {
                            icon.name: "dialog-close"
                            PlasmaComponents3.ToolTip.text: i18n("Close")
                            PlasmaComponents3.ToolTip.visible: hovered
                            onClicked: {
                                webview.downloads.remove(model.index);
                            }
                        }

                    }
                    // Cancel button (visible during download)
                    PlasmaComponents3.Button {
                        icon.name: "dialog-cancel"
                        visible: model.state === WebEngineDownloadRequest.DownloadInProgress && !model.isPdfExport
                        PlasmaComponents3.ToolTip.text: i18n("Cancel")
                        PlasmaComponents3.ToolTip.visible: hovered
                        onClicked: {
                            // Get the cached download object using the unique ID
                            let downloadData = webview.downloadCache[model.downloadId];
                            if (downloadData && downloadData.download) {
                                // Disconnect signal handlers before canceling
                                downloadData.download.receivedBytesChanged.disconnect(downloadData.bytesConnection);
                                downloadData.download.stateChanged.disconnect(downloadData.stateConnection);
                                
                                // Cancel the download
                                downloadData.download.cancel();
                                
                                // Clean up cache
                                delete webview.downloadCache[model.downloadId];
                                
                                // Remove from downloads model
                                webview.downloads.remove(index);
                            }
                        }
                    }

                }

            }

        }

    }

    Rectangle {
        id: findBar
        visible: findBarVisible
        height: visible ? findBarRow.height + Kirigami.Units.smallSpacing * 2 : 0
        color: PlasmaCore.Theme.backgroundColor
        z: 5

        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }

        RowLayout {
            id: findBarRow

            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: Kirigami.Units.smallSpacing
            }
            
            spacing: Kirigami.Units.smallSpacing

            PlasmaComponents3.TextField {
                id: findField
                
                Layout.fillWidth: true
                
                placeholderText: i18n("Find in page...")
                onTextChanged: if (text) webview.findText(text)
                onAccepted: webview.findText(text)
                Keys.onEscapePressed: findBarVisible = false

                Component.onCompleted: {
                    if (findBarVisible) {
                        forceActiveFocus()
                    }
                }
            }

            PlasmaComponents3.Button {
                icon.name: "go-up"
                display: PlasmaComponents3.AbstractButton.IconOnly
                onClicked: webview.findText(findField.text, WebEngineView.FindBackward)
                PlasmaComponents3.ToolTip.text: i18n("Find previous")
                PlasmaComponents3.ToolTip.visible: hovered
                enabled: findField.text !== ""
            }

            PlasmaComponents3.Button {
                icon.name: "go-down"
                display: PlasmaComponents3.AbstractButton.IconOnly
                onClicked: webview.findText(findField.text)
                PlasmaComponents3.ToolTip.text: i18n("Find next")
                PlasmaComponents3.ToolTip.visible: hovered
                enabled: findField.text !== ""
            }

            PlasmaComponents3.Button {
                icon.name: "dialog-close"
                display: PlasmaComponents3.AbstractButton.IconOnly
                PlasmaComponents3.ToolTip.text: i18n("Close")
                PlasmaComponents3.ToolTip.visible: hovered
                onClicked: {
                    findBarVisible = false
                    webview.findText("")
                }
            }
        }

        Behavior on height {
            NumberAnimation {
                duration: Kirigami.Units.shortDuration
                easing.type: Easing.InOutQuad
            }
        }
    }

}