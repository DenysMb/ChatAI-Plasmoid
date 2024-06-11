import QtQuick
import org.kde.plasma.core as PlasmaCore
import QtQuick.Layouts 1.1
import QtQuick.Controls 2.12 as QQC2
import org.kde.plasma.components 3.0 as PlasmaComponents3
import org.kde.plasma.plasmoid 2.0

RowLayout {
    Layout.fillWidth: true

    signal goBackToHomePage()

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

    QQC2.ComboBox {
        id: urlComboBox

        Layout.fillWidth: true

        textRole: "text"
        valueRole: "value"
        
        model: []

        onActivated: plasmoid.configuration.url = urlComboBox.currentValue

        Component.onCompleted: renderChatModel()

        Connections {
            target: plasmoid.configuration

            onShowDuckDuckGoChatChanged: renderChatModel()
            onShowChatGPTChanged: renderChatModel()
            onShowHugginChatChanged: renderChatModel()
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
            
            plasmoid.configuration.showDuckDuckGoChat && chatModel.push({ value: "https://duckduckgo.com/chat", text: "DuckDuckGo Chat" })

            plasmoid.configuration.showChatGPT && chatModel.push({ value: "https://chat.openai.com/chat", text: "ChatGPT" })

            plasmoid.configuration.showHugginChat && chatModel.push({ value: "https://huggingface.co/chat", text: "HugginChat" })

            plasmoid.configuration.showBingCopilot && chatModel.push({ value: "https://www.bing.com/chat", text: "Bing Copilot" })
            
            plasmoid.configuration.showGoogleGemini && chatModel.push({ value: "https://gemini.google.com/app", text: "Google Gemini" })

            plasmoid.configuration.showBlackBox && chatModel.push({ value: "https://www.blackbox.ai", text: "BlackBox AI" })

            urlComboBox.model = chatModel

            const currentPageIndex = chatModel.findIndex(chat => chat.value === plasmoid.configuration.url)

            if (currentPageIndex === -1) {
                urlComboBox.currentIndex = 0
                urlComboBox.currentValue = chatModel[0].value
                urlComboBox.currentText = chatModel[0].text
                plasmoid.configuration.url = chatModel[0].value
            } else {
                urlComboBox.currentIndex = currentPageIndex
            }
        }
}