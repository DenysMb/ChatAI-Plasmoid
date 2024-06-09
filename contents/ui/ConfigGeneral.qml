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
                id: showBingCopilot

                text: qsTr("Bing Copilot")
            }
        }
    }
}
