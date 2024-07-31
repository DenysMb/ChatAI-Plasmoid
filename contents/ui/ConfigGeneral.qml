import QtQuick
import QtQuick.Layouts 1.3
import QtQuick.Controls 2.12 as QQC2

import org.kde.kirigami 2.20 as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    property alias cfg_showDuckDuckGoChat: showDuckDuckGoChat.checked
    property alias cfg_showChatGPT: showChatGPT.checked
    property alias cfg_showHugginChat: showHugginChat.checked
    property alias cfg_showBingCopilot: showBingCopilot.checked
    property alias cfg_showGoogleGemini: showGoogleGemini.checked
    property alias cfg_showBlackBox: showBlackBox.checked
    property alias cfg_showYou: showYou.checked
    property alias cfg_showPerplexity: showPerplexity.checked
    property alias cfg_showLobeChat: showLobeChat.checked
    property alias cfg_showBigAGI: showBigAGI.checked
    property alias cfg_showClaude: showClaude.checked
    property alias cfg_hideHeader: hideHeader.checked
    property alias cfg_hideGoToButton: hideGoToButton.checked
    property alias cfg_hideKeepOpen: hideKeepOpen.checked
    property alias cfg_hideCustomURL: hideCustomURL.checked

    Kirigami.FormLayout {

        RowLayout {
            Kirigami.FormData.label: i18nc("@title:group", "Available chats:")

            QQC2.CheckBox {
                id: showDuckDuckGoChat

                text: qsTr("DuckDuckGo Chat")
            }
        }

        RowLayout {

            QQC2.CheckBox {
                id: showChatGPT

                text: qsTr("ChatGPT")
            }
        }

        RowLayout {
            QQC2.CheckBox {
                id: showHugginChat

                text: qsTr("HugginChat")
            }
        }

        RowLayout {
            QQC2.CheckBox {
                id: showGoogleGemini

                text: qsTr("Google Gemini")
            }
        }

        RowLayout {
            QQC2.CheckBox {
                id: showYou

                text: qsTr("You")
            }
        }

        RowLayout {
            QQC2.CheckBox {
                id: showPerplexity

                text: qsTr("Perplexity")
            }
        }

        RowLayout {
            QQC2.CheckBox {
                id: showBlackBox

                text: qsTr("BlackBox AI")
            }
        }

        RowLayout {
            QQC2.CheckBox {
                id: showBingCopilot

                text: qsTr("Bing Copilot")
            }
        }

        RowLayout {
            QQC2.CheckBox {
                id: showBigAGI

                text: qsTr("Big AGI")
            }
        }

        RowLayout {
            QQC2.CheckBox {
                id: showLobeChat

                text: qsTr("LobeChat")
            }
        }

        RowLayout {
            QQC2.CheckBox {
                id: showClaude

                text: qsTr("Claude")
            }
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
        }

        RowLayout {
            Kirigami.FormData.label: i18nc("@title:group", "Header display:")

            QQC2.CheckBox {
                id: hideHeader

                text: qsTr("Hide header when only one model is selected")
            }
        }

        RowLayout {
            QQC2.CheckBox {
                id: hideGoToButton

                text: qsTr("Hide \"Go to ...\" button")
            }
        }

        RowLayout {
            QQC2.CheckBox {
                id: hideKeepOpen

                text: qsTr("Hide \"Keep Open\" button")
            }
        }

        RowLayout {
            QQC2.CheckBox {
                id: hideCustomURL

                text: qsTr("Hide \"Custom URL\" button")
            }
        }

        Kirigami.InlineMessage {
            Layout.fillWidth: true
            text: 'You can still use the "Go back to ..." and "Keep open" actions by right-clicking the widget icon.'
            visible: hideHeader.checked || hideGoToButton.checked || hideKeepOpen.checked
        }
    }
}
