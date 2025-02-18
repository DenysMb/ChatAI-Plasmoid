import QtQuick
import QtQuick.Dialogs
import QtQuick.Layouts
import org.kde.plasma.components 3.0 as PlasmaComponents3
import org.kde.kirigami 2.20 as Kirigami
import org.kde.plasma.plasmoid 2.0
import Qt.labs.platform 1.1
import QtWebEngine

RowLayout {
    Layout.fillWidth: true

    // Signals for communication with parent components
    signal goBackToHomePage()
    signal closeWebViewRequested()
    signal reloadPageRequested()
    signal navigateBackRequested()
    signal navigateForwardRequested()
    signal printPageRequested()

    // Properties for managing component state
    property var closeWebViewCallback: undefined    // Callback function for closing webview
    property var models                            // Available chat models
    property bool showCustomURLInput: false        // Toggle between URL selector and custom URL input
    property var webview: (parent && parent.webviewRoot) ? parent.webviewRoot.webview : null

    // Navigation buttons
    PlasmaComponents3.Button {
        icon.name: "go-previous"
        display: PlasmaComponents3.AbstractButton.IconOnly
        onClicked: navigateBackRequested()
        visible: !plasmoid.configuration.hideNavigationButtons
        z: 3
        PlasmaComponents3.ToolTip.text: i18n("Go back to previous page")
        PlasmaComponents3.ToolTip.delay: Kirigami.Units.toolTipDelay
        PlasmaComponents3.ToolTip.visible: hovered
    }

    PlasmaComponents3.Button {
        icon.name: "go-next"
        display: PlasmaComponents3.AbstractButton.IconOnly
        onClicked: navigateForwardRequested()
        visible: !plasmoid.configuration.hideNavigationButtons
        z: 3
        PlasmaComponents3.ToolTip.text: i18n("Go forward to next page")
        PlasmaComponents3.ToolTip.delay: Kirigami.Units.toolTipDelay
        PlasmaComponents3.ToolTip.visible: hovered
    }

    PlasmaComponents3.Button {
        icon.name: "go-home"
        display: PlasmaComponents3.AbstractButton.IconOnly
        onClicked: goBackToHomePage()
        visible: !plasmoid.configuration.hideHomeButton
        z: 3
        PlasmaComponents3.ToolTip.text: i18n("Return to homepage/default chat")
        PlasmaComponents3.ToolTip.delay: Kirigami.Units.toolTipDelay
        PlasmaComponents3.ToolTip.visible: hovered
    }

    PlasmaComponents3.Button {
        icon.name: "view-refresh"
        display: PlasmaComponents3.AbstractButton.IconOnly
        onClicked: reloadPageRequested()
        visible: !plasmoid.configuration.hideRefreshButton
        z: 3
        PlasmaComponents3.ToolTip.text: i18n("Reload current page")
        PlasmaComponents3.ToolTip.delay: Kirigami.Units.toolTipDelay
        PlasmaComponents3.ToolTip.visible: hovered
    }

    // URL Selection components
    PlasmaComponents3.ComboBox {
        id: urlComboBox
        Layout.fillWidth: true
        PlasmaComponents3.ToolTip.text: i18n("Select or enter chat website URL")
        PlasmaComponents3.ToolTip.delay: Kirigami.Units.toolTipDelay
        PlasmaComponents3.ToolTip.visible: hovered && !pressed
        model: []
        editable: currentIndex === count - 1
        
        property string customUrlText: ""
        
        displayText: {
            if (currentIndex === count - 1 && editable) {
                return customUrlText || ""
            }
            return currentText
        }
        
        onActivated: {
            if (currentIndex === count - 1) {
                editable = true
                customUrlText = ""
                editText = ""
                Qt.callLater(() => {
                    forceActiveFocus()
                    if (urlComboBox.hasOwnProperty("textField")) {
                        urlComboBox.textField.forceActiveFocus()
                    }
                })
            } else {
                editable = false
                handleModelSelection()
            }
        }

        onEditTextChanged: {
            if (currentIndex === count - 1) {
                customUrlText = editText
            }
        }

        Keys.onReturnPressed: event => {
            if (currentIndex === count - 1 && editText) {
                let url = editText
                plasmoid.configuration.url = url.match(/^https?:\/\//) ? url : "https://" + url
                goBackToHomePage()
                event.accepted = true
            }
        }

        onAccepted: {
            if (currentIndex === count - 1 && editText) {
                let url = editText
                plasmoid.configuration.url = url.match(/^https?:\/\//) ? url : "https://" + url
                goBackToHomePage()
            }
        }

        Component.onCompleted: renderChatModel()
    }

    // Auto-Hide Button
    PlasmaComponents3.Button {
        id: autoHideButton
        visible: !plasmoid.configuration.hidePrintButton
        icon.name: plasmoid.configuration.autoHideHeader ? "view-visible" : "view-hidden"
        display: PlasmaComponents3.AbstractButton.IconOnly
        checkable: true
        checked: plasmoid.configuration.autoHideHeader
        z: 3
        PlasmaComponents3.ToolTip.text: checked ? 
            i18n("Header will hide automatically when not in use") : 
            i18n("Header will stay visible")
        PlasmaComponents3.ToolTip.delay: Kirigami.Units.toolTipDelay
        PlasmaComponents3.ToolTip.visible: hovered
        onToggled: plasmoid.configuration.autoHideHeader = checked
    }

    // Download button with dropdown menu
    // Provides access to download folder management
    PlasmaComponents3.Button {
        icon.name: "folder-download"
        display: PlasmaComponents3.AbstractButton.IconOnly
        onClicked: downloadMenu.popup()
        visible: !plasmoid.configuration.hideDownloadButton
        z: 3
        PlasmaComponents3.ToolTip.text: i18n("Manage downloads and download folder")
        PlasmaComponents3.ToolTip.delay: Kirigami.Units.toolTipDelay
        PlasmaComponents3.ToolTip.visible: hovered

        PlasmaComponents3.Menu {
            id: downloadMenu
            PlasmaComponents3.MenuItem {
                icon.name: "folder-open"
                text: i18n("Open Download Folder")
                onTriggered: Qt.openUrlExternally(plasmoid.configuration.downloadPath?.replace(/^file:\/+/, '/') || StandardPaths.writableLocation(StandardPaths.DownloadLocation))
            }
            PlasmaComponents3.MenuItem {
                icon.name: "folder"
                text: i18n("Choose Download Folder")
                onTriggered: folderDialog.open()
            }
        }
    }

    // Dialog for selecting download folder location
    FolderDialog {
        id: folderDialog
        currentFolder: plasmoid.configuration.downloadPath || StandardPaths.writableLocation(StandardPaths.DownloadLocation)
        onAccepted: plasmoid.configuration.downloadPath = selectedFolder
    }

    // Pin button - Keeps the widget open when focused is lost
    PlasmaComponents3.Button {
        icon.name: "window-pin"
        display: PlasmaComponents3.AbstractButton.IconOnly
        checkable: true
        checked: Boolean(plasmoid.configuration.keepOpen)
        onToggled: plasmoid.configuration.pin = checked
        visible: !Boolean(plasmoid.configuration.hideKeepOpen)
        z: 3
        PlasmaComponents3.ToolTip.text: checked ? 
            i18n("Widget will stay open when clicking outside") : 
            i18n("Widget will close when clicking outside")
        PlasmaComponents3.ToolTip.delay: Kirigami.Units.toolTipDelay
        PlasmaComponents3.ToolTip.visible: hovered
    }

    // Close button - Closes the webview and collapses the widget
    PlasmaComponents3.Button {
        icon.name: "window-close"
        display: PlasmaComponents3.AbstractButton.IconOnly
        onClicked: {
            closeWebViewRequested()
            closeWebViewCallback?.()
        }
        visible: !plasmoid.configuration.hideCloseButton
        z: 3
        PlasmaComponents3.ToolTip.text: i18n("Close the webview and release memory")
        PlasmaComponents3.ToolTip.delay: Kirigami.Units.toolTipDelay
        PlasmaComponents3.ToolTip.visible: hovered
    }

    // Helper Functions
    // Returns the number of available chat models
    function getModelsLength() {
        return urlComboBox.model.length
    }

    // Updates the chat model list and current selection
    // Handles both predefined and custom chat models
    function renderChatModel() {
        // Create model list from enabled predefined models
        const chatModel = models
            .filter(model => !model.prop.startsWith("showCustom_") && plasmoid.configuration[model.prop])
            .map(model => model.text)
            // Add custom sites to the model list
            .concat((plasmoid.configuration.customSites || "")
                .split(',')
                .filter(site => site?.includes('|'))
                .map(site => site.split('|')[0]))
            .concat([i18n("Custom URL...")]);

        // Update ComboBox model and select current item
        urlComboBox.model = chatModel;
        
        const currentUrl = plasmoid.configuration.url;
        const currentModel = models.find(model => !model.prop.startsWith("showCustom_") && model.url === currentUrl);
        
        if (currentModel) {
            const index = chatModel.indexOf(currentModel.text);
            urlComboBox.currentIndex = index;
            urlComboBox.editable = false;
        } else {
            const customSite = (plasmoid.configuration.customSites || "")
                .split(',')
                .find(site => site?.includes('|') && site.split('|')[1] === currentUrl);
            
            if (customSite) {
                const siteName = customSite.split('|')[0];
                const index = chatModel.indexOf(siteName);
                urlComboBox.currentIndex = index;
                urlComboBox.editable = false;
            } else {
                urlComboBox.currentIndex = chatModel.length - 1;
                urlComboBox.customUrlText = currentUrl;
                urlComboBox.editText = currentUrl;
                urlComboBox.editable = true;
            }
        }
    }

    // Handles model selection from ComboBox
    // Updates current URL and navigates to selected chat
    function handleModelSelection() {
        if (urlComboBox.currentIndex === urlComboBox.count - 1) {
            // Custom URL handling
            let url = urlComboBox.editText;
            if (url) {
                plasmoid.configuration.url = url.match(/^https?:\/\//) ? url : "https://" + url;
                goBackToHomePage();
            }
            return;
        }

        const selectedText = urlComboBox.currentValue
        if (!selectedText) return

        urlComboBox.displayText = selectedText

        const selectedModel = models.find(model => !model.prop.startsWith("showCustom_") && model.text === selectedText)
        if (selectedModel) {
            plasmoid.configuration.url = selectedModel.url
            goBackToHomePage()
            return
        }

        const customSite = (plasmoid.configuration.customSites || "")
            .split(',')
            .find(site => site?.split('|')[0] === selectedText)
        if (customSite) {
            plasmoid.configuration.url = customSite.split('|')[1]
            goBackToHomePage()
        }
    }

    Binding {
        target: root
        property: "hideOnWindowDeactivate"
        value: !plasmoid.configuration.pin
        restoreMode: Binding.RestoreBinding
    }

    // Configuration change handlers
    // Updates model list when chat service visibility settings change
    Connections {
        target: plasmoid.configuration
        function onCustomSitesChanged() { renderChatModel() }
        function onShowT3ChatChanged() { renderChatModel() }
        function onShowDuckDuckGoChatChanged() { renderChatModel() }
        function onShowChatGPTChanged() { renderChatModel() }
        function onShowHugginChatChanged() { renderChatModel() }
        function onShowGoogleGeminiChanged() { renderChatModel() }
        function onShowYouChanged() { renderChatModel() }
        function onShowPerplexityChanged() { renderChatModel() }
        function onShowLobeChatChanged() { renderChatModel() }
        function onShowBigAGIChanged() { renderChatModel() }
        function onShowBlackBoxChanged() { renderChatModel() }
        function onShowBingCopilotChanged() { renderChatModel() }
        function onShowClaudeChanged() { renderChatModel() }
        function onShowDeepSeekChanged() { renderChatModel() }
        function onShowMetaAIChanged() { renderChatModel() }
        function onShowGrokChanged() { renderChatModel() }
    }
}
