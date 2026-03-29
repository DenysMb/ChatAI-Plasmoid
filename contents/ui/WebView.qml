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

    function toggleBlur() {
        plasmoid.configuration.enableBlur = !plasmoid.configuration.enableBlur;
    }

    function goBackToHomePage() {
        plasmoid.configuration.lastVisitedUrl = "";
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

    // Re-inject CSS when settings change live
    Connections {
        target: plasmoid.configuration
        function onEnableBlurChanged() { if (webview.url.toString()) webview.injectTransparencyCSS(); }
        function onFocusModeChanged() { if (webview.url.toString()) webview.injectFocusMode(); }
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

        property bool _forceOpaque: false
        backgroundColor: (!plasmoid.configuration.enableBlur || _forceOpaque) ? Kirigami.Theme.backgroundColor : "transparent"

        // Brief opacity flip to force WebEngine compositing reset
        Timer {
            id: bgFlipTimer
            interval: 50
            onTriggered: webview._forceOpaque = false
        }
        function kickTransparency() {
            _forceOpaque = true;
            bgFlipTimer.start();
        }

        // Background-only transparency: inline styles on html/body and
        // top-level wrapper elements, leaving all content areas intact
        readonly property string _jsRemoveBlur: `
            (function() { try {
                if (window._chatai_resizeHandler) {
                    window.removeEventListener('resize', window._chatai_resizeHandler);
                    window._chatai_resizeHandler = null;
                }
                document.documentElement.style.removeProperty('background-color');
                document.body.style.removeProperty('background-color');
                document.body.querySelectorAll('body > *, body > * > *').forEach(function(el) {
                    el.style.removeProperty('background-color');
                    el.style.removeProperty('backdrop-filter');
                    el.style.removeProperty('-webkit-backdrop-filter');
                });
            } catch(e) {} })();`

        readonly property string _jsApplyBlur: `
            (function() { try {
                window._chatai_applyBlur = function() {
                    var a = 0.5, b = 8;
                    var minW = window.innerWidth * 0.3;
                    document.documentElement.style.setProperty('background-color', 'transparent', 'important');
                    document.body.style.setProperty('background-color', 'transparent', 'important');
                    var els = document.body.querySelectorAll('body > *, body > * > *');
                    var targets = [];
                    for (var i = 0; i < els.length; i++) {
                        var r = els[i].getBoundingClientRect();
                        if (r.width < minW) continue;
                        var bg = getComputedStyle(els[i]).backgroundColor;
                        if (!bg || bg === 'rgba(0, 0, 0, 0)' || bg === 'transparent') continue;
                        var m = bg.match(/rgba?\\((\\d+),\\s*(\\d+),\\s*(\\d+)/);
                        if (m) targets.push({ el: els[i], r: m[1], g: m[2], b: m[3] });
                    }
                    for (var j = 0; j < targets.length; j++) {
                        var t = targets[j];
                        t.el.style.setProperty('background-color', 'rgba(' + t.r + ',' + t.g + ',' + t.b + ',' + a + ')', 'important');
                        t.el.style.setProperty('backdrop-filter', 'blur(' + b + 'px)', 'important');
                        t.el.style.setProperty('-webkit-backdrop-filter', 'blur(' + b + 'px)', 'important');
                    }
                };
                window._chatai_applyBlur();
                if (!window._chatai_resizeHandler) {
                    var timer = null;
                    window._chatai_resizeHandler = function() {
                        clearTimeout(timer);
                        timer = setTimeout(window._chatai_applyBlur, 300);
                    };
                    window.addEventListener('resize', window._chatai_resizeHandler);
                }
            } catch(e) {} })();`

        function injectTransparencyCSS() {
            if (!plasmoid.configuration.enableBlur) {
                webview.runJavaScript(webview._jsRemoveBlur);
                return;
            }
            webview.runJavaScript(webview._jsApplyBlur);
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
        url: plasmoid.configuration.lastVisitedUrl || plasmoid.configuration.url
        profile: webProfile

        // Save current URL so it persists across WebView unload/reload
        onUrlChanged: {
            var u = url.toString();
            if (u && u !== "about:blank" && u !== plasmoid.configuration.lastVisitedUrl)
                plasmoid.configuration.lastVisitedUrl = u;
        }
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
        // Focus mode: hide sidebars, headers, and non-essential UI per service
        function injectFocusMode() {
            if (!plasmoid.configuration.focusMode) {
                webview.runJavaScript("var el = document.getElementById('_chatai_focus'); if (el) el.remove();");
                return;
            }

            var url = webview.url.toString();
            var css = "";

            if (url.includes("chatgpt.com")) {
                css = `
                    /* ChatGPT: hide sidebar, top nav */
                    nav, div[class*="sidebar"], div[class*="Sidebar"],
                    div[class*="drawer"], header:has(button[aria-label]) {
                        display: none !important;
                    }
                    main { margin-left: 0 !important; }
                    div[class*="thread"] { max-width: 100% !important; }
                `;
            } else if (url.includes("claude.ai")) {
                css = `
                    /* Claude: hide sidebar */
                    div[class*="sidebar"], div[class*="Sidebar"],
                    nav, aside, div[data-testid="sidebar"],
                    div[class*="ConversationList"], div[class*="conversation-list"] {
                        display: none !important;
                    }
                    main, div[class*="main"], div[class*="Main"] {
                        margin-left: 0 !important;
                        max-width: 100% !important;
                    }
                `;
            } else if (url.includes("duckduckgo.com")) {
                css = `
                    /* DuckDuckGo: hide header, side panels */
                    header, div[class*="header"], div[class*="Header"],
                    div[class*="sidebar"], aside {
                        display: none !important;
                    }
                    main { margin: 0 auto !important; max-width: 100% !important; }
                `;
            } else if (url.includes("gemini.google.com")) {
                css = `
                    /* Gemini: hide side nav, top bar */
                    mat-sidenav, side-navigation, side-navigation-v2,
                    header, .header-bar, mat-toolbar,
                    c-wiz > header, div[class*="side-nav"] {
                        display: none !important;
                    }
                    mat-sidenav-content, .main-container {
                        margin-left: 0 !important;
                        max-width: 100% !important;
                    }
                `;
            } else if (url.includes("chat.deepseek.com")) {
                css = `
                    /* DeepSeek: hide sidebar */
                    div[class*="sidebar"], div[class*="Sidebar"],
                    nav, aside {
                        display: none !important;
                    }
                    main, div[class*="main"] {
                        margin-left: 0 !important;
                        max-width: 100% !important;
                    }
                `;
            } else if (url.includes("copilot.microsoft.com")) {
                css = `
                    /* Copilot: hide side elements */
                    aside, nav, div[class*="sidebar"], div[class*="Sidebar"] {
                        display: none !important;
                    }
                    main { margin: 0 !important; max-width: 100% !important; }
                `;
            }

            // Inject known CSS or run heuristic fallback
            webview.runJavaScript("
                (function() {
                    var s = document.getElementById('_chatai_focus');
                    if (s) s.remove();
                    s = document.createElement('style');
                    s.id = '_chatai_focus';

                    var knownCSS = `" + css + "`;

                    if (knownCSS.trim()) {
                        s.textContent = knownCSS;
                    } else {
                        // Heuristic: analyze DOM and hide non-essential elements
                        var viewW = window.innerWidth;
                        var hidden = [];

                        // 1. Hide semantic nav/aside/header elements
                        document.querySelectorAll('nav, aside, [role=\"navigation\"], [role=\"banner\"], [role=\"complementary\"]').forEach(function(el) {
                            var rect = el.getBoundingClientRect();
                            // Skip if it's the main content area or tiny
                            if (rect.width > viewW * 0.6 || rect.height < 20) return;
                            hidden.push(el);
                        });

                        // 2. Hide fixed/absolute sidebars (narrow elements pinned to sides)
                        //    Only check direct children of body and their direct children to avoid scanning thousands of elements
                        document.querySelectorAll('body > div, body > section, body > div > div, body > div > section').forEach(function(el) {
                            var style = getComputedStyle(el);
                            if (style.position !== 'fixed' && style.position !== 'absolute' && style.position !== 'sticky') return;
                            var rect = el.getBoundingClientRect();
                            if (rect.width > viewW * 0.35) return; // too wide to be sidebar
                            if (rect.height < viewW * 0.3) return; // too short to be sidebar
                            // Likely a sidebar or panel
                            hidden.push(el);
                        });

                        // 3. Hide top headers (full-width, short, at top)
                        document.querySelectorAll('header, [role=\"banner\"]').forEach(function(el) {
                            var rect = el.getBoundingClientRect();
                            if (rect.top < 10 && rect.height < 80 && rect.width > viewW * 0.5) {
                                hidden.push(el);
                            }
                        });

                        // Build CSS from detected elements
                        var css = '';
                        hidden.forEach(function(el) {
                            // Tag unique selectors for each element
                            if (!el.dataset.chataiHidden) {
                                el.dataset.chataiHidden = '1';
                            }
                        });
                        css = '[data-chatai-hidden=\"1\"] { display: none !important; }\\n';
                        css += 'main, [role=\"main\"] { margin-left: 0 !important; margin-right: 0 !important; max-width: 100% !important; width: 100% !important; }';

                        s.textContent = css;
                    }

                    document.head.appendChild(s);
                })();
            ");
        }

        // Pre-built keyboard shortcut + textarea focus JS (uses MutationObserver instead of setInterval)
        readonly property string _jsKeyboardShortcuts: `
            if (!window._chatAIInjected) {
                window._chatAIInjected = true;

                document.addEventListener('keydown', function(event) {
                    if (event.key === 'Enter' && !event.shiftKey) {
                        var btn = document.querySelector('button[aria-label="Send"]')
                            || document.querySelector('button[data-testid="send-button"]')
                            || document.querySelector('button.send-button')
                            || document.querySelector('button[aria-label="Send Message"]');
                        if (btn) {
                            event.preventDefault();
                            btn.click();
                            window._chatAIWaitForTextarea();
                        }
                    }
                });

                window._chatAIWaitForTextarea = function() {
                    var textarea = document.querySelector('textarea');
                    if (textarea && !textarea.disabled) {
                        setTimeout(function() { textarea.focus(); }, 100);
                        return;
                    }
                    var observer = new MutationObserver(function(mutations, obs) {
                        var ta = document.querySelector('textarea');
                        if (ta && !ta.disabled) {
                            obs.disconnect();
                            setTimeout(function() { ta.focus(); }, 100);
                        }
                    });
                    observer.observe(document.body, { childList: true, subtree: true, attributes: true, attributeFilter: ['disabled'] });
                    setTimeout(function() { observer.disconnect(); }, 5000);
                };

                window._chatAIWaitForTextarea();
            }`

        // Compatible sites for keyboard shortcut injection
        readonly property var _compatibleSites: ['duckduckgo', 'chatgpt', 'google', 'claude', 'you']

        onLoadingChanged: {
            injectBrowserSpoof();

            if (!webview.loading) {
                checkAndUpdateFavicon();
                webview.kickTransparency();
                injectTransparencyCSS();
                injectFocusMode();

                // Check actual page URL (not configured home URL) for keyboard shortcuts
                var currentUrl = webview.url.toString();
                if (_compatibleSites.some(function(site) { return currentUrl.includes(site); })) {
                    webview.runJavaScript(webview._jsKeyboardShortcuts);
                }
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

        Component.onDestruction: {
            // Disconnect all active download signal connections to prevent leaks
            for (var id in downloadCache) {
                var entry = downloadCache[id];
                if (entry && entry.download && entry.bytesConnection) {
                    try {
                        entry.download.receivedBytesChanged.disconnect(entry.bytesConnection);
                        entry.download.stateChanged.disconnect(entry.stateConnection);
                    } catch(e) {}
                }
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
