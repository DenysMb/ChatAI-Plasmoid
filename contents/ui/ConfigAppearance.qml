import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kcmutils as KCM
import org.kde.kirigami as Kirigami

KCM.SimpleKCM {
    property alias cfg_iconMode: iconMode.currentIndex

    // Remove padding for better layout
    leftPadding: 0
    rightPadding: 0

    // Main form layout container
    Kirigami.FormLayout {
        anchors.left: parent.left
        width: Math.min(parent.width, Kirigami.Units.gridUnit * 25)

        QQC2.ComboBox {
            id: iconMode
            Kirigami.FormData.label: i18n("Icon:")
            model: [
                i18n("Use website favicon"),
                i18n("Default adaptive icon"),
                i18n("Default dark icon"),
                i18n("Default light icon"),
                i18n("Outlined icon"),
                i18n("Filled icon"),
                i18n("Colorful icon")
            ]
            Layout.fillWidth: true
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

            text: i18n("Hide Header")
            checked: plasmoid.configuration.hideHeader
            onCheckedChanged: plasmoid.configuration.hideHeader = checked
            Layout.fillWidth: true
        }

        QQC2.CheckBox {
            id: autoHideHeader
            text: i18n("Auto-hide Header (show on mouse hover)")
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

            text: i18n("Hide Navigation buttons")
            checked: plasmoid.configuration.hideNavigationButtons
            onCheckedChanged: plasmoid.configuration.hideNavigationButtons = checked
            Layout.fillWidth: true
        }

        QQC2.CheckBox {
            id: hideRefreshButton

            text: i18n("Hide Refresh button")
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
