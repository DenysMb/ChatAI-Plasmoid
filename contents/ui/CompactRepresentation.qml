import QtQuick
import org.kde.kirigami 2.20 as Kirigami
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.0 as PlasmaCore

Item {
    id: compactRoot
    
    property var models
    property var webview
    property string fallbackIcon: "help-about"

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        onClicked: root.expanded = !root.expanded
    }

    Kirigami.Icon {
        anchors.fill: parent
        source: Qt.resolvedUrl(getIcon())
    }

    // WebView connection handlers
    // Monitor and respond to webview state changes
    Connections {
        // Parent webview connection
        target: parent && parent.webviewRoot && parent.webviewRoot.webview
                  ? parent.webviewRoot.webview
                  : null
        enabled: target ? true : false
    }

    // Direct webview connection for loading state changes
    Connections {
        target: webview
        enabled: webview !== null
        function onLoadingChanged(loadingInfo) {
            if (loadingInfo?.status === WebEngineLoadRequest.LoadSucceededStatus) {
                // Handle successful load
            }
        }
    }

    // Helper Functions
    // Determines and returns the appropriate chat model icon based on:
    // - Current chat service
    // - System theme (light/dark)
    // - User icon style preferences
    function getChatModelIcon() {
        const currentModel = models.find(model => Plasmoid.configuration.url.includes(model.url))
        const colorContrast = getBackgroundColorContrast()
        const hasOnlyColorfulIcon = !Plasmoid.configuration.useColorfulChatIcon && 
                                  ["lobechat", "bigagi"].includes(currentModel?.id)

        if (!currentModel || currentModel?.id === "blackbox" || hasOnlyColorfulIcon) {
            return `assets/logo-${colorContrast}.svg`
        }

        // Add custom icon mapping, For CustomModels & New Models when added
        if (currentModel.useIcon) {
            const style = Plasmoid.configuration.useFilledChatIcon ? "filled" : "outlined"
            return `assets/${style}/${currentModel.useIcon}-${colorContrast}.svg`
        }

        if (Plasmoid.configuration.useColorfulChatIcon) {
            return `assets/colorful/${currentModel.id}.svg`
        }

        const style = Plasmoid.configuration.useFilledChatIcon ? "filled" : "outlined"
        return `assets/${style}/${currentModel.id}-${colorContrast}.svg`
    }

    // Main icon selection function that determines which icon to display:
    // 1. Website favicon (if enabled)
    // 2. Chat model specific icon (if enabled)
    // 3. Default icon based on theme
    function getIcon() {
        if (Plasmoid.configuration.useFavicon) {
            const faviconUrl = Plasmoid.configuration.favIcon || Plasmoid.configuration.lastFavIcon
            if (faviconUrl) {
                return faviconUrl.replace("image://favicon/", "")
            }
        }

        if (Plasmoid.configuration.useFilledChatIcon || 
            Plasmoid.configuration.useOutlinedChatIcon || 
            Plasmoid.configuration.useColorfulChatIcon) {
            return getChatModelIcon() || fallbackIcon
        }

        const contrast = getBackgroundColorContrast()
        return Plasmoid.configuration.useDefaultDarkIcon ? "assets/logo-dark.svg" :
               Plasmoid.configuration.useDefaultLightIcon ? "assets/logo-light.svg" :
               `assets/logo-${contrast}.svg`
    }

    // Calculates whether to use light or dark icons based on
    // the system background color using luminance formula
    // Returns: "dark" or "light" based on background contrast
    function getBackgroundColorContrast() {
        const hex = `${PlasmaCore.Theme.backgroundColor}`.substring(1)
        const [r, g, b] = [
            parseInt(hex.substring(0, 2), 16),
            parseInt(hex.substring(2, 4), 16),
            parseInt(hex.substring(4, 6), 16)
        ]
        const luma = 0.2126 * r + 0.7152 * g + 0.0722 * b
        return luma > 128 ? "dark" : "light"
    }
}
