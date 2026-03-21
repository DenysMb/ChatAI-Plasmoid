import QtCore
import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import QtWebEngine
import org.kde.plasma.components as PlasmaComponents3
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid
import org.kde.notification 1.0
import org.kde.kirigami as Kirigami

Item {
    id: webViewRoot
    readonly property string effectiveProfileName: plasmoid.configuration.webEngineProfileName && plasmoid.configuration.webEngineProfileName.length ? plasmoid.configuration.webEngineProfileName : "chat-ai"
    readonly property string effectiveDownloadPath: {
        if (plasmoid.configuration.downloadPath)
            return plasmoid.configuration.downloadPath.toString().replace(/^file:\/\//, '');
        return StandardPaths.writableLocation(StandardPaths.DownloadLocation);
    }

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
        webview.runJavaScript("document.title", function (title) {
            let downloadDirectory = webViewRoot.effectiveDownloadPath;

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
        webview.runJavaScript("document.title", function (title) {
            let downloadDirectory = webViewRoot.effectiveDownloadPath;

            let timestamp = new Date().toISOString().replace(/[:.]/g, '-');
            let safeName = title.replace(/[^a-z0-9]/gi, '-').toLowerCase();
            let filename = `${downloadDirectory}/${safeName}-${timestamp}.mhtml`;

            webview.triggerWebAction(WebEngineView.SavePage, filename);
        });
    }

    readonly property string chromeDesktopUA: "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0.0.0 Safari/537.36"
    readonly property string chromeMobileUA: "Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0.0.0 Mobile Safari/537.36"

    function getUserAgent() {
        var needsMobile = plasmoid.configuration.url.includes("duckduckgo.com") || plasmoid.configuration.url.includes("x.com/i/grok");
        if (needsMobile)
            return chromeMobileUA;
        if (plasmoid.configuration.spoofChromeBrowser)
            return chromeDesktopUA;
        return "";
    }

    // Spoof browser identity so auth pages (Google, Claude, etc.) work
    function injectBrowserSpoof() {
        if (!plasmoid.configuration.spoofChromeBrowser)
            return;

        webview.runJavaScript("
            if (!window._chatAISpoofed) {
                window._chatAISpoofed = true;

                // Spoof navigator properties
                Object.defineProperty(navigator, 'vendor', { get: function() { return 'Google Inc.'; } });
                Object.defineProperty(navigator, 'platform', { get: function() { return 'Linux x86_64'; } });
                Object.defineProperty(navigator, 'webdriver', { get: function() { return false; } });
                Object.defineProperty(navigator, 'languages', { get: function() { return ['en-US', 'en']; } });

                // Spoof window.chrome
                if (!window.chrome) {
                    window.chrome = {
                        runtime: {},
                        loadTimes: function() { return {}; },
                        csi: function() { return {}; },
                        app: { isInstalled: false }
                    };
                }

                // Spoof plugins (Chrome has PDF viewer)
                Object.defineProperty(navigator, 'plugins', {
                    get: function() {
                        return [
                            { name: 'Chrome PDF Viewer', filename: 'internal-pdf-viewer', description: 'Portable Document Format' },
                            { name: 'Chromium PDF Viewer', filename: 'internal-pdf-viewer', description: '' }
                        ];
                    }
                });

                // Hide webdriver/automation hints
                delete navigator.__proto__.webdriver;

                // Spoof permissions API behavior
                if (navigator.permissions) {
                    var origQuery = navigator.permissions.query;
                    navigator.permissions.query = function(params) {
                        if (params.name === 'notifications')
                            return Promise.resolve({ state: Notification.permission });
                        return origQuery.call(navigator.permissions, params);
                    };
                }
            }
        ");
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
        webNotification.title = title || i18n("ChatAI");
        webNotification.text = message;
        webNotification.iconName = icon;
        webNotification.sendEvent();
    }

    function getProgressPath(path) {
        // For the progress bar, it needs file:///
        return "file:///" + path.replace(/^\/+/, '');
    }

    // Add this helper function before the WebEngineView
    function isDownloadInProgress(fileName) {
        if (!webview || !webview.downloads)
            return false;

        for (let i = 0; i < webview.downloads.count; i++) {
            let item = webview.downloads.get(i);
            if (item && item.state === WebEngineDownloadRequest.DownloadInProgress && item.fileName === fileName) {
                return true;
            }
        }
        return false;
    }

    Layout.fillWidth: true
    Layout.fillHeight: true

    property bool findBarVisible: false

    // Re-inject transparency CSS when settings change live
    Connections {
        target: plasmoid.configuration
        function onEnableTransparencyChanged() { if (webview.url.toString()) webview.injectTransparencyCSS(); }
        function onBackgroundTransparencyChanged() { if (webview.url.toString()) webview.injectTransparencyCSS(); }
    }

    onFindBarVisibleChanged: {
        if (findBarVisible) {
            findBarComponent.focusField();
        } else {
            webview.findText(""); // Clear any existing search
        }
    }

    Shortcut {
        sequence: StandardKey.Find
        onActivated: findBarVisible = true
    }

    PlasmaComponents3.Menu {
        id: linkContextMenu

        property string link: ""

        PlasmaComponents3.MenuItem {
            text: i18n("Back")
            icon.name: "go-previous"
            enabled: webview.canGoBack
            onTriggered: webview.goBack()
        }

        PlasmaComponents3.MenuItem {
            text: i18n("Forward")
            icon.name: "go-next"
            enabled: webview.canGoForward
            onTriggered: webview.goForward()
        }

        PlasmaComponents3.MenuItem {
            text: i18n("Reload")
            icon.name: "view-refresh"
            onTriggered: reloadPage()
        }

        PlasmaComponents3.MenuItem {
            text: i18n("Save as PDF")
            icon.name: "document-save-as"
            visible: !linkContextMenu.link
            onTriggered: printPage()
        }

        PlasmaComponents3.MenuItem {
            text: i18n("Save as MHTML")
            icon.name: "document-save"
            visible: !linkContextMenu.link
            onTriggered: saveMHTML()
        }

        PlasmaComponents3.MenuItem {
            text: i18n("Open Link in Browser")
            icon.name: "internet-web-browser"
            visible: linkContextMenu.link !== ""
            onTriggered: Qt.openUrlExternally(linkContextMenu.link)
        }

        PlasmaComponents3.MenuItem {
            text: i18n("Copy Link Address")
            icon.name: "edit-copy"
            visible: linkContextMenu.link !== ""
            onTriggered: webview.triggerWebAction(WebEngineView.CopyLinkToClipboard)
        }
    }

    WebEngineView {
        id: webview

        // Opacity follows load progress: 0% → 0.3, 100% → 1.0
        opacity: loading ? 0.3 + (loadProgress / 100) * 0.7 : 1.0
        Behavior on opacity {
            enabled: plasmoid.configuration.enableAnimations
            NumberAnimation { duration: 150; easing.type: Easing.OutQuad }
        }

        // Transparent WebEngine background when transparency is enabled
        backgroundColor: plasmoid.configuration.enableTransparency ? "transparent" : Kirigami.Theme.backgroundColor

        // Inject CSS to make the website background semi-transparent
        function injectTransparencyCSS() {
            if (!plasmoid.configuration.enableTransparency) {
                webview.runJavaScript("
                    var el = document.getElementById('_chatai_transparency');
                    if (el) el.remove();
                ");
                return;
            }

            var opacity = plasmoid.configuration.backgroundTransparency;
            webview.runJavaScript("
                (function() {
                    var styleId = '_chatai_transparency';
                    var existing = document.getElementById(styleId);
                    if (existing) existing.remove();

                    // Grab computed bg colors and make them semi-transparent
                    var targets = document.querySelectorAll(
                        'html, body, body > *:first-child, body > div:first-of-type, ' +
                        'main, #__next, #root, #app, .app, ' +
                        '[class*=\"layout\"], [class*=\"Layout\"], ' +
                        '[class*=\"container\"], [class*=\"Container\"], ' +
                        '[class*=\"wrapper\"], [class*=\"Wrapper\"]'
                    );

                    var css = 'html, body { background-color: transparent !important; }\\n';

                    targets.forEach(function(el) {
                        var bg = getComputedStyle(el).backgroundColor;
                        if (bg && bg !== 'rgba(0, 0, 0, 0)' && bg !== 'transparent') {
                            // Parse rgb/rgba and apply opacity
                            var match = bg.match(/rgba?\\((\\d+),\\s*(\\d+),\\s*(\\d+)/);
                            if (match) {
                                var r = match[1], g = match[2], b = match[3];
                                var selector = el.id ? '#' + el.id :
                                    el.tagName.toLowerCase() + (el.className ? '.' + el.className.split(' ')[0] : '');
                                css += selector + ' { background-color: rgba(' + r + ',' + g + ',' + b + ',' + " + opacity + " + ') !important; }\\n';
                            }
                        }
                    });

                    var style = document.createElement('style');
                    style.id = styleId;
                    style.textContent = css;
                    document.head.appendChild(style);
                })();
            ");
        }

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
            `, function (result) {
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
        onLinkHovered: hoveredUrl => {
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
        onContextMenuRequested: request => {
            // Use default menu for special elements (text fields, selection, etc)
            if (request.isContentEditable || request.selectedText || request.mediaType !== ContextMenuRequest.MediaTypeNone) {
                request.accepted = false;  // Let the default menu appear
                return;
            }

            // Update link only if there is a URL
            let hasLink = request.linkUrl.toString() !== "";
            linkContextMenu.link = hasLink ? request.linkUrl.toString() : "";

            // Always show our custom menu when it's not a special element
            linkContextMenu.popup(request.position.x, request.position.y);
            request.accepted = true;
        }

        // https://doc.qt.io/qt-6/qml-application-permissions.html
        onPermissionRequested: function (request) {
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
            if (request.permissionType === WebEnginePermission.MediaAudioCapture) {
                plasmoid.configuration.microphoneEnabled ? request.grant() : request.deny();
                return;
            }
            if (request.permissionType === WebEnginePermission.MediaVideoCapture) {
                plasmoid.configuration.webcamEnabled ? request.grant() : request.deny();
                return;
            }
            if (request.permissionType === WebEnginePermission.DesktopAudioVideoCapture) {
                plasmoid.configuration.screenShareEnabled ? request.grant() : request.deny();
                return;
            }

            request.grant();
        }
        // CSS backdrop blur follows load progress — blurs background only, text stays sharp
        function updateBlurForProgress(progress) {
            var blurPx = Math.round(12 * (1 - progress / 100));
            var overlayAlpha = (1 - progress / 100) * 0.3; // 0.3 at 0% → 0 at 100%
            var subtle = plasmoid.configuration.enableTransparency ? 0.5 : 0;

            webview.runJavaScript("
                (function() {
                    var s = document.getElementById('_chatai_blur');
                    if (!s) {
                        s = document.createElement('style');
                        s.id = '_chatai_blur';
                        document.head.appendChild(s);
                    }

                    var blur = " + blurPx + ";
                    var alpha = " + overlayAlpha.toFixed(3) + ";
                    var subtle = " + subtle + ";

                    if (blur <= 0 && subtle <= 0) {
                        s.textContent = '#_chatai_blur_overlay { display: none; }';
                        return;
                    }

                    var finalBlur = blur > 0 ? blur : subtle;
                    var finalAlpha = blur > 0 ? alpha : 0;

                    s.textContent = `
                        #_chatai_blur_overlay {
                            position: fixed;
                            inset: 0;
                            z-index: 99999;
                            pointer-events: none;
                            backdrop-filter: blur(${finalBlur}px);
                            -webkit-backdrop-filter: blur(${finalBlur}px);
                            background: rgba(0,0,0,${finalAlpha});
                            transition: backdrop-filter 0.15s ease-out, background 0.15s ease-out,
                                        -webkit-backdrop-filter 0.15s ease-out;
                        }
                    `;

                    // Create overlay element if needed
                    if (!document.getElementById('_chatai_blur_overlay')) {
                        var div = document.createElement('div');
                        div.id = '_chatai_blur_overlay';
                        document.documentElement.appendChild(div);
                    }
                })();
            ");
        }

        onLoadProgressChanged: {
            if (loading)
                updateBlurForProgress(loadProgress);
        }

        onLoadingChanged: {
            injectBrowserSpoof();

            if (loading) {
                updateBlurForProgress(0);
            } else {
                updateBlurForProgress(100);
                checkAndUpdateFavicon();
                injectTransparencyCSS();
            }

            var isCompatibleModel = ['duckduckgo', 'chatgpt', 'google', 'claude', 'you'].some(site => plasmoid.configuration.url.includes(site));

            if (isCompatibleModel && !webview.loading) {
                webview.runJavaScript("
                    if (!window._chatAIInjected) {
                        window._chatAIInjected = true;

                        document.addEventListener('keydown', function(event) {
                            if (event.key === 'Enter' && !event.shiftKey) {
                                var duckDuckGoButton = document.querySelector('button[aria-label=\"Send\"]');
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
                    }
                ");
            }
        }
        onPrintRequested: function () {
            webview.triggerWebAction(WebEngineView.Print);
        }

        onPdfPrintingFinished: function (filePath, success) {
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
            const authDomains = ['accounts.google.com', 'appleid.apple.com', 'login.live.com', 'github.com/login', 'instagram.com/oauth', 'facebook.com/oidc'];
            return authDomains.some(domain => url.includes(domain));
        }

        // Add these handlers to intercept new windows and tabs
        onNewWindowRequested: function (request) {
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
        onNavigationRequested: function (request) {
            if (request.navigationType === WebEngineNavigationRequest.NavigationTypeRedirect || request.navigationType === WebEngineNavigationRequest.NavigationTypeLinkClicked) {

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
            storageName: webViewRoot.effectiveProfileName
            offTheRecord: false
            httpCacheType: WebEngineProfile.DiskHttpCache
            persistentCookiesPolicy: WebEngineProfile.ForcePersistentCookies
            persistentPermissionsPolicy: WebEngineProfile.AskEveryTime
            downloadPath: webViewRoot.effectiveDownloadPath
            onPresentNotification: function (notification) {
                showNotification(notification.title, notification.message);
                notification.show();
            }
            onDownloadRequested: function (download) {
                // Ensure downloads model exists
                if (!webview.downloads) {
                    webview.downloads = Qt.createQmlObject('import QtQml; ListModel {}', webview);
                }

                let downloadDirectory = webViewRoot.effectiveDownloadPath;

                if (!plasmoid.configuration.downloadPath) {
                    plasmoid.configuration.downloadPath = downloadDirectory;
                }

                download.downloadDirectory = downloadDirectory;

                // Check for duplicate downloads
                for (let i = 0; i < webview.downloads.count; i++) {
                    let currentDownload = webview.downloads.get(i);
                    if (currentDownload.state === WebEngineDownloadRequest.DownloadInProgress && currentDownload.fileName === download.downloadFileName && !currentDownload.isPdfExport) {
                        showNotification(i18n("Download in progress"), i18n("The file '%1' is already being downloaded", download.downloadFileName), "dialog-warning");
                        download.cancel();
                        return;
                    }
                }

                // Create a unique ID for this download
                let downloadId = Date.now().toString() + Math.random().toString(36).substring(7);

                let downloadIndex = webview.downloads.addDownload(download, download.downloadFileName, downloadDirectory + "/" + download.downloadFileName, false);

                // Store the index in the download object for reference
                let currentIndex = downloadIndex;

                // Create independent connections for each download
                let bytesConnection = function () {
                    if (currentIndex >= 0 && currentIndex < webview.downloads.count) {
                        let currentProgress = download.receivedBytes / download.totalBytes;
                        webview.downloads.setProperty(currentIndex, "progress", currentProgress);
                        webview.downloads.setProperty(currentIndex, "receivedBytes", download.receivedBytes);
                        webview.downloads.setProperty(currentIndex, "totalBytes", download.totalBytes);
                    }
                };

                let stateConnection = function (state) {
                    if (currentIndex >= 0 && currentIndex < webview.downloads.count) {
                        webview.downloads.setProperty(currentIndex, "state", state);
                        if (state === WebEngineDownloadRequest.DownloadCompleted) {
                            webview.downloads.setProperty(currentIndex, "progress", 1.0);
                        }
                        // Clear connections after completion or cancellation
                        if (state === WebEngineDownloadRequest.DownloadCompleted || state === WebEngineDownloadRequest.DownloadCancelled) {
                            download.receivedBytesChanged.disconnect(bytesConnection);
                            download.stateChanged.disconnect(stateConnection);
                            delete webview.downloadCache[downloadId];
                        }
                    }
                };

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
                const color = Kirigami.Theme.backgroundColor;
                const luma = 0.2126 * color.r + 0.7152 * color.g + 0.0722 * color.b;
                return luma < 0.5;
            }
        }
    }

    // Loading spinner (content blur is handled via CSS injection)
    PlasmaComponents3.BusyIndicator {
        anchors.centerIn: parent
        z: 3
        running: webview.loading
        visible: running
        implicitWidth: Kirigami.Units.gridUnit * 3
        implicitHeight: implicitWidth
    }

    MouseArea {
        id: mouseArea

        anchors.fill: parent
        acceptedButtons: Qt.BackButton | Qt.ForwardButton
        onPressed: mouse => {
            if (mouse.button === Qt.BackButton)
                webview.goBack();
            else if (mouse.button === Qt.ForwardButton)
                webview.goForward();
        }
    }

    Rectangle {
        id: statusBubble

        property int padding: 8

        visible: false
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.margins: Kirigami.Units.smallSpacing
        width: statusText.paintedWidth + padding * 2
        height: statusText.paintedHeight + padding
        z: 5
        color: Kirigami.Theme.backgroundColor
        opacity: plasmoid.configuration.overlayOpacity
        radius: Kirigami.Units.smallSpacing

        Text {
            id: statusText

            anchors.centerIn: parent
            elide: Qt.ElideMiddle
            color: Kirigami.Theme.textColor

            Timer {
                id: hideStatusText

                interval: 750
                onTriggered: {
                    statusText.text = "";
                    statusBubble.visible = false;
                }
            }
        }

        Behavior on opacity {
            enabled: plasmoid.configuration.enableAnimations
            NumberAnimation { duration: 200 }
        }
    }

    DownloadBar {
        id: downloadsBar

        downloadsModel: webview.downloads
        downloadCacheRef: webview.downloadCache

        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
    }

    FindBar {
        id: findBarComponent

        barVisible: findBarVisible

        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }

        onFindRequested: text => webview.findText(text)
        onFindPreviousRequested: text => webview.findText(text, WebEngineView.FindBackward)
        onClosed: {
            findBarVisible = false;
            webview.findText("");
        }
    }
}
