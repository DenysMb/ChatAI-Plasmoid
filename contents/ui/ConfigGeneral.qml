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
    property alias cfg_hideHeader: hideHeader.checked

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

        Kirigami.InlineMessage {
            Layout.fillWidth: true
            text: 'You can still use the "Go back to ..." and "Keep open" actions by right-clicking the widget icon.'
            visible: hideHeader.checked
        }

    }
}
