import QtQuick
import QtQuick.Layouts
import org.kde.kirigami 2.20 as Kirigami
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid 2.0

// Main plasmoid item that contains all the widget functionality
PlasmoidItem {
    id: root

    // Define the available chat models and their properties
    // This property combines both predefined and custom sites
    property var models: {
        // Define base models with their default properties
        let baseModels = [{
            "id": "t3",
            "url": "https://t3.chat",
            "text": "T3 Chat",
            "prop": "showT3Chat"
        }, {
            "id": "duckduckgo",
            "url": "https://duckduckgo.com/chat",
            "text": "DuckDuckGo Chat",
            "prop": "showDuckDuckGoChat"
        }, {
            "id": "chatgpt",
            "url": "https://chatgpt.com",
            "text": "ChatGPT",
            "prop": "showChatGPT"
        }, {
            "id": "huggingface",
            "url": "https://huggingface.co/chat",
            "text": "HugginChat",
            "prop": "showHugginChat"
        }, {
            "id": "copilot",
            "url": "https://copilot.microsoft.com/",
            "text": "Bing Copilot",
            "prop": "showBingCopilot"
        }, {
            "id": "google",
            "url": "https://gemini.google.com/app",
            "text": "Google Gemini",
            "prop": "showGoogleGemini"
        }, {
            "id": "blackbox",
            "url": "https://www.blackbox.ai",
            "text": "BlackBox AI",
            "prop": "showBlackBox"
        }, {
            "id": "you",
            "url": "https://you.com/?chatMode=default",
            "text": "You",
            "prop": "showYou"
        }, {
            "id": "perplexity",
            "url": "https://www.perplexity.ai",
            "text": "Perplexity",
            "prop": "showPerplexity"
        }, {
            "id": "lobechat",
            "url": "https://lobechat.com/chat",
            "text": "LobeChat",
            "prop": "showLobeChat"
        }, {
            "id": "bigagi",
            "url": "https://get.big-agi.com",
            "text": "Big-AGI",
            "prop": "showBigAGI"
        }, {
            "id": "claude",
            "url": "https://claude.ai/new",
            "text": "Claude",
            "prop": "showClaude"
        }, {
            "id": "deepseek",
            "url": "https://chat.deepseek.com",
            "text": "DeepSeek",
            "prop": "showDeepSeek"
        }, {
            "id": "meta",
            "url": "https://www.meta.ai",
            "text": "Meta AI",
            "prop": "showMetaAI"
        }, {
            "id": "grok",
            "url": "https://x.com/i/grok",
            "text": "Grok",
            "prop": "showGrok"
        }];
        // Add custom sites from configuration to the models list
        let customSites = plasmoid.configuration.customSites || [];
        if (Array.isArray(customSites)) {
            customSites.forEach((site) => {
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

    // Widget appearance when collapsed (icon only)
    compactRepresentation: CompactRepresentation {
        id: compactRep

        models: root.models
        webview: root.webviewRoot ? root.webviewRoot.webview : null
    }

    // Widget appearance when expanded (full view)
    fullRepresentation: ColumnLayout {
        id: mainLayout

        // Expose WebView root for other components
        property alias webviewRoot: webviewLoader.item
        // Update the property to use Types.Location and add the change monitor
        property bool reverseLayout: plasmoid.location === PlasmaCore.Types.TopEdge

        // Function to reorder components
        function reorderComponents() {
            let components = reverseLayout ? [webviewLoader, headerMouseArea, headerRoot] : [headerRoot, headerMouseArea, webviewLoader];
            // Clear and re-add the components in the correct order
            for (let i = children.length - 1; i >= 0; i--) {
                children[i].parent = null;
            }
            components.forEach((component) => {
                component.parent = mainLayout;
            });
            // Update the anchors of headerMouseArea
            if (headerRoot && headerMouseArea) {
                if (reverseLayout) {
                    headerMouseArea.anchors.top = undefined;
                    headerMouseArea.anchors.bottom = parent.bottom;
                } else {
                    headerMouseArea.anchors.bottom = undefined;
                    headerMouseArea.anchors.top = parent.top;
                }
            }
        }

        // Set minimum dimensions for the expanded view
        Layout.minimumWidth: Kirigami.Units.gridUnit * 28
        Layout.minimumHeight: Kirigami.Units.gridUnit * 39
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
            // Callback to close the WebView and collapse the widget
            closeWebViewCallback: function() {
                webviewLoader.active = false;
                root.expanded = false;
            }
            // Handle navigation
            onGoBackToHomePage: webviewRoot.goBackToHomePage()
            onReloadPageRequested: webviewRoot.reloadPage()
            onNavigateBackRequested: webviewRoot.goBack()
            onNavigateForwardRequested: webviewRoot.goForward()
            onPrintPageRequested: webviewRoot.printPage()
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
                    headerMouseArea.anchors.top = undefined;
                    headerMouseArea.anchors.bottom = parent.bottom;
                } else {
                    headerMouseArea.anchors.bottom = undefined;
                    headerMouseArea.anchors.top = parent.top;
                }
            }

            // Timer for hiding
            Timer {
                id: hideTimer

                interval: 2000
                onTriggered: {
                    if (!headerRoot.isInteracting)
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

            // Intercept mouse events
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
                onPressed: {
                    headerRoot.isInteracting = true;
                    mouse.accepted = false;
                }
                onReleased: {
                    headerRoot.isInteracting = false;
                    if (!containsMouse)
                        hideTimer.restart();

                    mouse.accepted = false;
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
            onClicked: mouse.accepted = false
            onPressed: mouse.accepted = false
            onReleased: mouse.accepted = false
            onDoubleClicked: mouse.accepted = false
            onPositionChanged: mouse.accepted = false
            onPressAndHold: mouse.accepted = false

            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
            }

        }

        // WebView loader that manages the web content
        Loader {
            id: webviewLoader

            // Improved the loading of the WebView & Added Error Handling
            active: root.expanded || item !== null || plasmoid.configuration.loadOnStartup
            asynchronous: true
            source: "WebView.qml"
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.topMargin: 0

            // Add status handling
            onStatusChanged: {
                if (status === Loader.Error) {
                    console.error("Failed to load WebView.qml")
                }
            }
        }

        // Monitor plasmoid expansion state
        Connections {
            // Activate WebView when plasmoid is expanded
            function onExpandedChanged() {
                if (root.expanded)
                    webviewLoader.active = true;

            }

            target: root
        }

    }

}
