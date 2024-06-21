import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2

import org.kde.iconthemes as KIconThemes
import org.kde.kirigami 2.20 as Kirigami
import org.kde.ksvg 1.0 as KSvg
import org.kde.kcmutils as KCM

import org.kde.plasma.core as PlasmaCore

KCM.SimpleKCM {
    property string cfg_icon: plasmoid.configuration.icon
    property alias cfg_useFilledChatIcon: useFilledChatIcon.checked
    property alias cfg_useOutlinedChatIcon: useOutlinedChatIcon.checked
    property alias cfg_useDefaultIcon: useDefaultIcon.checked
    property alias cfg_useDefaultLightIcon: useDefaultLightIcon.checked
    property alias cfg_useDefaultDarkIcon: useDefaultDarkIcon.checked

    Kirigami.FormLayout {

        QQC2.ButtonGroup {
            id: iconGroup
        }

        QQC2.RadioButton {
            id: useDefaultIcon

            Kirigami.FormData.label: i18nc("@title:group", "Icon:")
            text: i18nc("@option:radio", "Default adaptive icon")

            QQC2.ButtonGroup.group: iconGroup
        }

        QQC2.RadioButton {
            id: useDefaultDarkIcon

            text: i18nc("@option:radio", "Default dark icon")

            QQC2.ButtonGroup.group: iconGroup
        }

        QQC2.RadioButton {
            id: useDefaultLightIcon

            text: i18nc("@option:radio", "Default light icon")

            QQC2.ButtonGroup.group: iconGroup
        }

        QQC2.RadioButton {
            id: useFilledChatIcon

            text: i18nc("@option:radio", "Filled chat's icon")

            QQC2.ButtonGroup.group: iconGroup
        }

        QQC2.RadioButton {
            id: useOutlinedChatIcon

            text: i18nc("@option:radio", "Outlined chat's icon")

            QQC2.ButtonGroup.group: iconGroup
        }
    }
}
