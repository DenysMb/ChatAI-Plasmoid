/*
 *  SPDX-FileCopyrightText: 2024 Denys Madureira <denysmb@zoho.com>
 *  SPDX-FileCopyrightText: 2025 Bruno Gonçalves <bigbruno@gmail.com>
 *
 *  SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

import QtQuick

import org.kde.plasma.extras as PlasmaExtras
import QtWebEngine

PlasmaExtras.Menu {
    id: contextMenu

    property string link
    property var webviewItem
    property bool canGoBack: webviewItem ? webviewItem.canGoBack : false
    property bool canGoForward: webviewItem ? webviewItem.canGoForward : false

    signal reloadRequested()
    signal savePdfRequested()
    signal saveMhtmlRequested()

    visualParent: webviewItem

    PlasmaExtras.MenuItem {
        text: i18n("Back")
        icon: "go-previous"
        enabled: contextMenu.canGoBack
        onClicked: {
            if (webviewItem) webviewItem.goBack();
        }
    }

    PlasmaExtras.MenuItem {
        text: i18n("Forward")
        icon: "go-next"
        enabled: contextMenu.canGoForward
        onClicked: {
            if (webviewItem) webviewItem.goForward();
        }
    }

    PlasmaExtras.MenuItem {
        text: i18n("Reload")
        icon: "view-refresh"
        onClicked: contextMenu.reloadRequested()
    }

    PlasmaExtras.MenuItem {
        text: i18n("Save as PDF")
        icon: "document-save-as"
        visible: !contextMenu.link
        onClicked: contextMenu.savePdfRequested()
    }

    PlasmaExtras.MenuItem {
        text: i18n("Save as MHTML")
        icon: "document-save"
        visible: !contextMenu.link
        onClicked: contextMenu.saveMhtmlRequested()
    }

    PlasmaExtras.MenuItem {
        text: i18n("Open Link in Browser")
        icon: "internet-web-browser"
        visible: contextMenu.link !== ""
        onClicked: Qt.openUrlExternally(contextMenu.link)
    }

    PlasmaExtras.MenuItem {
        text: i18n("Copy Link Address")
        icon: "edit-copy"
        visible: contextMenu.link !== ""
        onClicked: {
            if (webviewItem) webviewItem.triggerWebAction(WebEngineView.CopyLinkToClipboard);
        }
    }
}