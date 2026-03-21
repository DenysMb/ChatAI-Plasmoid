import QtQuick
import org.kde.plasma.components as PlasmaComponents3

PlasmaComponents3.Menu {
    id: contextMenu

    property bool canGoBack: false
    property bool canGoForward: false
    property string link: ""

    signal backRequested()
    signal forwardRequested()
    signal reloadRequested()
    signal saveAsPdfRequested()
    signal saveAsMHTMLRequested()
    signal copyLinkRequested()

    PlasmaComponents3.MenuItem {
        text: i18n("Back")
        icon.name: "go-previous"
        enabled: contextMenu.canGoBack
        onTriggered: contextMenu.backRequested()
    }

    PlasmaComponents3.MenuItem {
        text: i18n("Forward")
        icon.name: "go-next"
        enabled: contextMenu.canGoForward
        onTriggered: contextMenu.forwardRequested()
    }

    PlasmaComponents3.MenuItem {
        text: i18n("Reload")
        icon.name: "view-refresh"
        onTriggered: contextMenu.reloadRequested()
    }

    PlasmaComponents3.MenuItem {
        text: i18n("Save as PDF")
        icon.name: "document-save-as"
        visible: !contextMenu.link
        onTriggered: contextMenu.saveAsPdfRequested()
    }

    PlasmaComponents3.MenuItem {
        text: i18n("Save as MHTML")
        icon.name: "document-save"
        visible: !contextMenu.link
        onTriggered: contextMenu.saveAsMHTMLRequested()
    }

    PlasmaComponents3.MenuItem {
        text: i18n("Open Link in Browser")
        icon.name: "internet-web-browser"
        visible: contextMenu.link !== ""
        onTriggered: Qt.openUrlExternally(contextMenu.link)
    }

    PlasmaComponents3.MenuItem {
        text: i18n("Copy Link Address")
        icon.name: "edit-copy"
        visible: contextMenu.link !== ""
        onTriggered: contextMenu.copyLinkRequested()
    }
}
