import QtQuick
import org.kde.plasma.core as PlasmaCore
import QtQuick.Layouts 1.1
import QtQuick.Controls 2.12 as QQC2
import org.kde.plasma.components 3.0 as PlasmaComponents3
import org.kde.plasma.plasmoid 2.0
import org.kde.kirigami 2.20 as Kirigami

RowLayout {
    Layout.fillWidth: true

    signal goBackToHomePage()

    property var models;

    Plasmoid.contextualActions: [
        PlasmaCore.Action {
            text: i18n("Keep Open")
            icon.name: "window-pin"
            priority: Plasmoid.LowPriorityAction
            checkable: true
            checked: plasmoid.configuration.pin
            onTriggered: plasmoid.configuration.pin = checked
        },
        PlasmaCore.Action {
            text: "Go back to " + urlComboBox.currentText
            icon.name: "go-home-symbolic"
            priority: Plasmoid.LowPriorityAction
            onTriggered: goBackToHomePage()
        }
    ]

    PlasmaComponents3.Button {
        icon.name: "go-home-symbolic"
        text: "Go back to " + urlComboBox.currentText
        display: PlasmaComponents3.AbstractButton.IconOnly
        onClicked: goBackToHomePage()
        visible: !plasmoid.configuration.hideGoToButton

        PlasmaComponents3.ToolTip.text: text
        PlasmaComponents3.ToolTip.delay: Kirigami.Units.toolTipDelay
        PlasmaComponents3.ToolTip.visible: hovered
    }

    PlasmaComponents3.ComboBox {
        id: urlComboBox

        Layout.fillWidth: true

        model: []

        onActivated: handleModelSelection()

        Component.onCompleted: renderChatModel()

        Connections {
            target: plasmoid.configuration

            onShowDuckDuckGoChatChanged: renderChatModel()
            onShowChatGPTChanged: renderChatModel()
            onShowHugginChatChanged: renderChatModel()
            onShowGoogleGeminiChanged: renderChatModel()
            onShowYouChanged: renderChatModel()
            onShowPerplexityChanged: renderChatModel()
            onShowBlackBoxChanged: renderChatModel()
            onShowBingCopilotChanged: renderChatModel()
        }
    }


    PlasmaComponents3.Button {
        icon.name: "window-pin"
        text: i18n("Keep Open")
        display: PlasmaComponents3.AbstractButton.IconOnly
        checkable: true
        checked: plasmoid.configuration.pin
        onToggled: plasmoid.configuration.pin = checked
        visible: !plasmoid.configuration.hideKeepOpen

        PlasmaComponents3.ToolTip.text: text
        PlasmaComponents3.ToolTip.delay: Kirigami.Units.toolTipDelay
        PlasmaComponents3.ToolTip.visible: hovered
    }

    Binding {
        target: root
        property: "hideOnWindowDeactivate"
        value: !plasmoid.configuration.pin
        restoreMode: Binding.RestoreBinding
    }

    function getModelsLength() {
        return urlComboBox.model.length
    }

    function renderChatModel() {
            const chatModel = [];

            models.forEach(model => {
                plasmoid.configuration[model.prop] && chatModel.push(model.text)
            });

            urlComboBox.model = chatModel;

            urlComboBox.displayText = models.find(model => model.url === plasmoid.configuration.url)?.text || undefined;
        }

    function handleModelSelection() {
        const selectedModel = urlComboBox.currentValue

        urlComboBox.displayText = urlComboBox.currentValue;

        plasmoid.configuration.url = models.find(model => model.text === selectedModel).url
    }
}