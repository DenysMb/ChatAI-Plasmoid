import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid

// Main plasmoid item that contains all the widget functionality
PlasmoidItem {
    id: root

    // Translucent background lets compositor blur the desktop behind the popup
    Plasmoid.backgroundHints: plasmoid.configuration.enableTransparency
        ? PlasmaCore.Types.TranslucentBackground
        : PlasmaCore.Types.DefaultBackground

    // Define the available chat models and their properties
    // This property combines both predefined and custom sites
    property var models: {
        // Define base models with their default properties
        let baseModels = [
            {
                "id": "t3",
                "url": "https://t3.chat",
                "text": "T3 Chat",
                "prop": "showT3Chat"
            },
            {
                "id": "duckduckgo",
                "url": "https://duckduckgo.com/chat",
                "text": "DuckDuckGo Chat",
                "prop": "showDuckDuckGoChat"
            },
            {
                "id": "chatgpt",
                "url": "https://chatgpt.com",
                "text": "ChatGPT",
                "prop": "showChatGPT"
            },
            {
                "id": "huggingface",
                "url": "https://huggingface.co/chat",
                "text": "HugginChat",
                "prop": "showHugginChat"
            },
            {
                "id": "copilot",
                "url": "https://copilot.microsoft.com/",
                "text": "Bing Copilot",
                "prop": "showBingCopilot"
            },
            {
                "id": "google",
                "url": "https://gemini.google.com/app",
                "text": "Google Gemini",
                "prop": "showGoogleGemini"
            },
            {
                "id": "blackbox",
                "url": "https://www.blackbox.ai",
                "text": "BlackBox AI",
                "prop": "showBlackBox"
            },
            {
                "id": "you",
                "url": "https://you.com/?chatMode=default",
                "text": "You",
                "prop": "showYou"
            },
            {
                "id": "perplexity",
                "url": "https://www.perplexity.ai",
                "text": "Perplexity",
                "prop": "showPerplexity"
            },
            {
                "id": "lobechat",
                "url": "https://lobechat.com/chat",
                "text": "LobeChat",
                "prop": "showLobeChat"
            },
            {
                "id": "bigagi",
                "url": "https://get.big-agi.com",
                "text": "Big-AGI",
                "prop": "showBigAGI"
            },
            {
                "id": "claude",
                "url": "https://claude.ai/new",
                "text": "Claude",
                "prop": "showClaude"
            },
            {
                "id": "deepseek",
                "url": "https://chat.deepseek.com",
                "text": "DeepSeek",
                "prop": "showDeepSeek"
            },
            {
                "id": "meta",
                "url": "https://www.meta.ai",
                "text": "Meta AI",
                "prop": "showMetaAI"
            },
            {
                "id": "grok",
                "url": "https://x.com/i/grok",
                "text": "Grok",
                "prop": "showGrok"
            }
        ];
        // Add custom sites from configuration to the models list
        let customSites = plasmoid.configuration.customSites || [];
        if (Array.isArray(customSites)) {
            customSites.forEach(site => {
                if (site && typeof site === 'string' && site.includes('|')) {
                    const [name, url] = site.split('|');
                    if (name && url)
                        baseModels.push({
                            "id": name.toLowerCase().replace(/\s+/g, '-'),
                            "url": url,
                            "text": name,
                            "prop": "showCustom_" + name.toLowerCase().replace(/\s+/g, '_')
                        });
                }
            });
        }
        return baseModels;
    }

    // Initialize the plasmoid and check if it should load on startup
    Component.onCompleted: {
        // If loadOnStartup is enabled in configuration
        if (plasmoid.configuration.loadOnStartup) {
            webviewLoader.active = true; // Activate the WebView loader
            root.expanded = true; // Expand the plasmoid
        }
    }

    // Hide popup when clicking outside (unless pinned)
    Binding {
        target: root
        property: "hideOnWindowDeactivate"
        value: !plasmoid.configuration.keepOpen
        restoreMode: Binding.RestoreBinding
    }

    // Widget appearance when collapsed (icon only)
    compactRepresentation: CompactRepresentation {
        id: compactRep

        models: root.models
        webview: root.webviewRoot ? root.webviewRoot.webview : null
    }

    // Widget appearance when expanded (full view)
    fullRepresentation: Item {
        id: fullRep

        // Expose WebView root for other components
        property alias webviewRoot: webviewLoader.item

        Layout.minimumWidth: Kirigami.Units.gridUnit * 28
        Layout.minimumHeight: Kirigami.Units.gridUnit * 39

        // Accent glow around the widget
        Rectangle {
            id: glowOuter
            anchors.fill: parent
            anchors.margins: -6
            color: "transparent"
            radius: Kirigami.Units.largeSpacing
            visible: plasmoid.configuration.accentBorder
            z: -1

            Rectangle {
                anchors.fill: parent
                radius: parent.radius
                color: "transparent"
                border.width: 6
                border.color: Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.25)
            }
            Rectangle {
                anchors.fill: parent
                anchors.margins: 2
                radius: parent.radius - 2
                color: "transparent"
                border.width: 4
                border.color: Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.4)
            }
            Rectangle {
                anchors.fill: parent
                anchors.margins: 4
                radius: parent.radius - 4
                color: "transparent"
                border.width: 2
                border.color: Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.6)
            }
        }

        // Rounded clip container
        Rectangle {
            id: clipContainer
            anchors.fill: parent
            anchors.margins: Kirigami.Units.smallSpacing
            radius: Kirigami.Units.largeSpacing
            color: "transparent"
            clip: true

        ColumnLayout {
            id: mainLayout
            anchors.fill: parent
        // Update the property to use Types.Location and add the change monitor
        property bool reverseLayout: plasmoid.location === PlasmaCore.Types.TopEdge

        // Function to reorder components
        function reorderComponents() {
            let components = reverseLayout ? [webviewLoader, headerMouseArea, headerRoot] : [headerRoot, headerMouseArea, webviewLoader];
            // Clear and re-add the components in the correct order
            for (let i = children.length - 1; i >= 0; i--) {
                children[i].parent = null;
            }
            components.forEach(component => {
                component.parent = mainLayout;
            });
            // Update the anchors of headerMouseArea
            if (headerRoot && headerMouseArea) {
                if (reverseLayout) {
                    headerMouseArea.Layout.alignment = Qt.AlignBottom;
                } else {
                    headerMouseArea.Layout.alignment = Qt.AlignTop;
                }
            }
        }

        Component.onCompleted: {
            reorderComponents();
        }
        spacing: 0

        // Add monitor for plasmoid location change
        Connections {
            function onLocationChanged() {
                mainLayout.reverseLayout = plasmoid.location === PlasmaCore.Types.TopEdge;
                reorderComponents();
            }

            target: plasmoid
        }

        // Header component with auto-hide behavior
        Header {
            id: headerRoot

            property bool headerVisible: false
            property bool isInteracting: false
            property bool shouldBeVisible: {
                if (plasmoid.configuration.hideHeader)
                    return false;

                if (!plasmoid.configuration.autoHideHeader)
                    return true;

                return headerVisible || isInteracting || headerMouseArea.containsMouse;
            }

            models: root.models
            Layout.fillWidth: true
            z: 2 // Increase the z-index to ensure it is above the MouseArea
            // Callback to close/collapse the widget
            closeWebViewCallback: function () {
                if (!plasmoid.configuration.keepWebEngineAlive)
                    unloadTimer.restart();
                root.expanded = false;
            }
            // Handle navigation
            onGoBackToHomePage: webviewRoot.goBackToHomePage()
            onReloadPageRequested: webviewRoot.reloadPage()
            onNavigateBackRequested: webviewRoot.goBack()
            onNavigateForwardRequested: webviewRoot.goForward()
            onPrintPageRequested: webviewRoot.printPage()
            onToggleSearchRequested: {
                if (webviewRoot && webviewRoot.findBarVisible !== undefined) {
                    webviewRoot.findBarVisible = !webviewRoot.findBarVisible;
                }
            }
            Layout.preferredHeight: shouldBeVisible ? implicitHeight : 0
            Layout.maximumHeight: Layout.preferredHeight
            Layout.minimumHeight: 0
            Layout.bottomMargin: shouldBeVisible ? Kirigami.Units.smallSpacing : 0
            visible: Layout.preferredHeight > 0
            opacity: Layout.preferredHeight > 0 ? 1 : 0
            clip: true
            // Adjust the anchors of headerMouseArea based on the panel position
            Component.onCompleted: {
                if (mainLayout.reverseLayout) {
                    headerMouseArea.Layout.alignment = Qt.AlignBottom;
                } else {
                    headerMouseArea.Layout.alignment = Qt.AlignTop;
                }
            }

            // Timer for hiding — only hides if mouse is away AND no interaction
            Timer {
                id: hideTimer

                interval: 4000
                onTriggered: {
                    if (!headerRoot.isInteracting && !headerMouseArea.containsMouse)
                        headerRoot.headerVisible = false;
                }
            }

            // Timer to check interactions
            Timer {
                id: interactionTimer

                interval: 500
                repeat: true
                running: headerRoot.isInteracting
                onTriggered: {
                    // Check if there is still interaction with any component
                    let stillInteracting = false;
                    for (let i = 0; i < headerRoot.children.length; i++) {
                        let child = headerRoot.children[i];
                        if (child.activeFocus || (child.hasOwnProperty("pressed") && child.pressed)) {
                            stillInteracting = true;
                            break;
                        }
                    }
                    headerRoot.isInteracting = stillInteracting;
                    if (!stillInteracting && !headerMouseArea.containsMouse)
                        hideTimer.restart();
                }
            }

            // Connections to monitor interactions
            Connections {
                function onActiveFocusChanged() {
                    if (target.activeFocus) {
                        headerRoot.isInteracting = true;
                        hideTimer.stop();
                    }
                }

                target: headerRoot
            }

            // Intercept mouse events on the header
            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                propagateComposedEvents: true
                onEntered: {
                    headerRoot.headerVisible = true;
                    hideTimer.stop();
                }
                onExited: {
                    if (!headerRoot.isInteracting)
                        hideTimer.restart();
                }
                onPressed: event => {
                    headerRoot.isInteracting = true;
                    event.accepted = false;
                }
                onReleased: event => {
                    headerRoot.isInteracting = false;
                    if (!containsMouse)
                        hideTimer.restart();
                    event.accepted = false;
                }
            }

            // Animations
            Behavior on Layout.preferredHeight {
                NumberAnimation {
                    duration: 400
                    easing.type: Easing.InOutCubic
                }
            }

            Behavior on opacity {
                NumberAnimation {
                    duration: 400
                    easing.type: Easing.InOutQuad
                }
            }
        }

        // Mouse detection area
        MouseArea {
            id: headerMouseArea

            height: 2
            hoverEnabled: true
            z: 1 // Place below the header
            propagateComposedEvents: true
            onEntered: {
                headerRoot.headerVisible = true;
                hideTimer.stop();
            }
            onExited: {
                if (!headerRoot.isInteracting)
                    hideTimer.restart();
            }
            // Pass mouse events to child components
            onClicked: event => event.accepted = false
            onPressed: event => event.accepted = false
            onReleased: event => event.accepted = false
            onDoubleClicked: event => event.accepted = false
            onPositionChanged: event => event.accepted = false
            onPressAndHold: event => event.accepted = false

            Layout.fillWidth: true
            Layout.alignment: Qt.AlignTop
        }

        // WebView loader
        Loader {
            id: webviewLoader

            active: false
            source: "WebView.qml"
            Layout.fillWidth: true
            Layout.fillHeight: true

            onStatusChanged: {
                if (status === Loader.Error)
                    console.error("Failed to load WebView.qml");
            }
        }

        // Unload WebEngine after 5 min of inactivity (when keepWebEngineAlive is off)
        Timer {
            id: unloadTimer
            interval: 5 * 60 * 1000
            onTriggered: {
                if (!root.expanded)
                    webviewLoader.active = false;
            }
        }

        Connections {
            function onExpandedChanged() {
                if (root.expanded) {
                    unloadTimer.stop();
                    if (!webviewLoader.active)
                        webviewLoader.active = true;
                }
            }

            target: root
        }
        } // ColumnLayout
        } // clipContainer
    } // Item fullRep
}
