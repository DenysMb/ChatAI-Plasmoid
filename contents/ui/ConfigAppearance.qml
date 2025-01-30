import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kcmutils as KCM
import org.kde.kirigami 2.20 as Kirigami

KCM.SimpleKCM {
    property string cfg_icon: plasmoid.configuration.icon
    property alias cfg_useFilledChatIcon: useFilledChatIcon.checked
    property alias cfg_useOutlinedChatIcon: useOutlinedChatIcon.checked
    property alias cfg_useColorfulChatIcon: useColorfulChatIcon.checked
    property alias cfg_useDefaultIcon: useDefaultIcon.checked
    property alias cfg_useDefaultLightIcon: useDefaultLightIcon.checked
    property alias cfg_useDefaultDarkIcon: useDefaultDarkIcon.checked
    property alias cfg_useFavicon: useFavicon.checked

    // Remove padding for better layout
    leftPadding: 0
    rightPadding: 0

    // Main form layout container
    Kirigami.FormLayout {
        anchors.left: parent.left
        width: Math.min(parent.width, Kirigami.Units.gridUnit * 25)

        // Button group to ensure only one icon type can be selected
        QQC2.ButtonGroup {
            id: iconGroup
        }

        // Icon type selection section
        QQC2.RadioButton {
            id: useFavicon

            Kirigami.FormData.label: i18n("Icon:")
            text: i18n("Use website favicon")
            QQC2.ButtonGroup.group: iconGroup
        }

        // Default icon options
        QQC2.RadioButton {
            id: useDefaultIcon

            text: i18n("Default adaptive icon")
            QQC2.ButtonGroup.group: iconGroup
        }

        QQC2.RadioButton {
            id: useDefaultDarkIcon

            text: i18n("Default dark icon")
            QQC2.ButtonGroup.group: iconGroup
        }

        QQC2.RadioButton {
            id: useDefaultLightIcon

            text: i18n("Default light icon")
            QQC2.ButtonGroup.group: iconGroup
        }

        QQC2.RadioButton {
            id: useOutlinedChatIcon

            text: i18n("Outlined icon")
            QQC2.ButtonGroup.group: iconGroup
        }

        QQC2.RadioButton {
            id: useFilledChatIcon

            text: i18n("Filled icon")
            QQC2.ButtonGroup.group: iconGroup
        }

        QQC2.RadioButton {
            id: useColorfulChatIcon

            text: i18n("Colorful icon")
            QQC2.ButtonGroup.group: iconGroup
        }

        // Separator between icon and header sections
        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Layout.fillWidth: true
        }

        // Header Options section
        QQC2.Label {
            Kirigami.FormData.label: i18n("Header Options")
            font.bold: true
            Layout.fillWidth: true
        }

        // Header visibility option
        QQC2.CheckBox {
            id: hideHeader

            text: i18n("Hide header")
            checked: plasmoid.configuration.hideHeader
            onCheckedChanged: plasmoid.configuration.hideHeader = checked
            Layout.fillWidth: true
        }

        QQC2.CheckBox {
            id: autoHideHeader
            text: i18n("Auto-hide header (show on mouse hover)")
            checked: plasmoid.configuration.autoHideHeader
            onCheckedChanged: plasmoid.configuration.autoHideHeader = checked
            enabled: !hideHeader.checked
            Layout.fillWidth: true
        }

        // Hide various header buttons
        QQC2.CheckBox {
            id: hideKeepOpen

            text: i18n("Hide Keep Open button")
            checked: plasmoid.configuration.hideKeepOpen
            onCheckedChanged: plasmoid.configuration.hideKeepOpen = checked
            Layout.fillWidth: true
        }

        QQC2.CheckBox {
            id: hideCustomURL

            text: i18n("Hide Custom URL button")
            checked: plasmoid.configuration.hideCustomURL
            onCheckedChanged: plasmoid.configuration.hideCustomURL = checked
            Layout.fillWidth: true
        }

        QQC2.CheckBox {
            id: hidePrintButton

            text: i18n("Hide Auto-Hide button")
            checked: plasmoid.configuration.hidePrintButton
            onCheckedChanged: plasmoid.configuration.hidePrintButton = checked
            Layout.fillWidth: true
        }

        QQC2.CheckBox {
            id: hideCloseButton

            text: i18n("Hide Close button")
            checked: plasmoid.configuration.hideCloseButton
            onCheckedChanged: plasmoid.configuration.hideCloseButton = checked
            Layout.fillWidth: true
        }

        QQC2.CheckBox {
            id: hideHomeButton

            text: i18n("Hide Home button")
            checked: plasmoid.configuration.hideHomeButton
            onCheckedChanged: plasmoid.configuration.hideHomeButton = checked
            Layout.fillWidth: true
        }

        QQC2.CheckBox {
            id: hideDownloadButton

            text: i18n("Hide Download button")
            checked: plasmoid.configuration.hideDownloadButton
            onCheckedChanged: plasmoid.configuration.hideDownloadButton = checked
            Layout.fillWidth: true
        }

        QQC2.CheckBox {
            id: hideNavigationButtons

            text: i18n("Hide navigation buttons")
            checked: plasmoid.configuration.hideNavigationButtons
            onCheckedChanged: plasmoid.configuration.hideNavigationButtons = checked
            Layout.fillWidth: true
        }

        QQC2.CheckBox {
            id: hideRefreshButton

            text: i18n("Hide refresh button")
            checked: plasmoid.configuration.hideRefreshButton
            onCheckedChanged: plasmoid.configuration.hideRefreshButton = checked
            Layout.fillWidth: true
        }

        // Information message about hidden functionality
        Kirigami.InlineMessage {
            Layout.fillWidth: true
            text: i18n("You can still use the Go back to... and Keep open actions by right-clicking the widget icon.")
            visible: hideHeader.checked || hideGoToButton.checked || hideKeepOpen.checked
        }

    }

}
