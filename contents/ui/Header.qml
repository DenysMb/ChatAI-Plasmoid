import QtQuick
import QtQuick.Layouts 1.1
import QtQuick.Controls 2.12 as QQC2
import org.kde.plasma.components 3.0 as PlasmaComponents3
import org.kde.plasma.plasmoid 2.0

RowLayout {
    Layout.fillWidth: true

    PlasmaComponents3.Button {
        icon.name: "go-home-symbolic"
        onClicked: webview.url = urlComboBox.currentValue
        display: PlasmaComponents3.AbstractButton.IconOnly
        text: "Go back to " + urlComboBox.currentText
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

    function renderChatModel() {
            const chatModel = [];
            
            plasmoid.configuration.showDuckDuckGoChat && chatModel.push({ value: "https://duckduckgo.com/chat", text: "DuckDuckGo Chat" })

            plasmoid.configuration.showChatGPT && chatModel.push({ value: "https://chat.openai.com/chat", text: "ChatGPT" })

            plasmoid.configuration.showHugginChat && chatModel.push({ value: "https://huggingface.co/chat", text: "HugginChat" })

            plasmoid.configuration.showBingCopilot && chatModel.push({ value: "https://www.bing.com/chat", text: "Bing Copilot" })

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