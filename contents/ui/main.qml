import QtQuick.Layouts 1.1
import org.kde.kirigami 2.20 as Kirigami
import org.kde.plasma.plasmoid 2.0

PlasmoidItem {
    id: root

    property var models: [
        { id: "duckduckgo", url: "https://duckduckgo.com/chat", text: "DuckDuckGo Chat", prop: "showDuckDuckGoChat" },
        { id: "chatgpt", url: "https://chatgpt.com", text: "ChatGPT", prop: "showChatGPT" },
        { id: "huggingface", url: "https://huggingface.co/chat", text: "HugginChat", prop: "showHugginChat" },
        { id: "copilot", url: "https://copilot.microsoft.com/", text: "Bing Copilot", prop: "showBingCopilot" },
        { id: "google", url: "https://gemini.google.com/app", text: "Google Gemini", prop: "showGoogleGemini" },
        { id: "blackbox", url: "https://www.blackbox.ai", text: "BlackBox AI", prop: "showBlackBox" },
        { id: "you", url: "https://you.com/?chatMode=default", text: "You", prop: "showYou" },
        { id: "perplexity", url: "https://www.perplexity.ai", text: "Perplexity", prop: "showPerplexity" },
        { id: "lobechat", url: "https://lobechat.com/chat", text: "LobeChat", prop: "showLobeChat" },
        { id: "bigagi", url: "https://get.big-agi.com", text: "Big-AGI", prop: "showBigAGI" }
    ]

    compactRepresentation: CompactRepresentation {
            models: root.models
    }

    fullRepresentation: ColumnLayout {
        Layout.minimumWidth: Kirigami.Units.gridUnit * 28
        Layout.minimumHeight: Kirigami.Units.gridUnit * 39

        Header {
            id: headerRoot
            models: root.models
            onGoBackToHomePage: webviewRoot.goBackToHomePage()
            visible: plasmoid.configuration.hideHeader ? headerRoot.getModelsLength() > 1 : true
        }

        WebView {
            id: webviewRoot
        }
    }
}
