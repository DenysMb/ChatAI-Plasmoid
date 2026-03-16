/*
 *  SPDX-FileCopyrightText: 2024 Denys Madureira <denysmb@zoho.com>
 *  SPDX-FileCopyrightText: 2025 Bruno Gonçalves <bigbruno@gmail.com>
 *
 *  SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

import QtQuick
import QtQuick.Layouts

import org.kde.plasma.components as PlasmaComponents3
import org.kde.kirigami as Kirigami
import QtWebEngine

Rectangle {
    id: findBar

    property bool findBarVisible: false
    property var webviewItem
    property alias findText: findField.text

    signal closeRequested()

    visible: findBarVisible
    height: visible ? findBarRow.height + Kirigami.Units.smallSpacing * 2 : 0
    color: Kirigami.Theme.backgroundColor
    z: 5

    anchors {
        top: parent.top
        left: parent.left
        right: parent.right
    }

    RowLayout {
        id: findBarRow

        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: Kirigami.Units.smallSpacing
        }

        spacing: Kirigami.Units.smallSpacing

        PlasmaComponents3.TextField {
            id: findField

            Layout.fillWidth: true

            placeholderText: i18n("Find in page...")
            onTextChanged: {
                if (text && webviewItem) {
                    webviewItem.findText(text);
                }
            }
            onAccepted: {
                if (webviewItem) {
                    webviewItem.findText(text);
                }
            }
            Keys.onEscapePressed: findBarVisible = false

            Component.onCompleted: {
                if (findBarVisible) {
                    forceActiveFocus();
                }
            }
        }

        PlasmaComponents3.Button {
            icon.name: "go-up"
            display: PlasmaComponents3.AbstractButton.IconOnly
            onClicked: {
                if (webviewItem) {
                    webviewItem.findText(findField.text, WebEngineView.FindBackward);
                }
            }
            PlasmaComponents3.ToolTip.text: i18n("Find previous")
            PlasmaComponents3.ToolTip.visible: hovered
            enabled: findField.text !== ""
        }

        PlasmaComponents3.Button {
            icon.name: "go-down"
            display: PlasmaComponents3.AbstractButton.IconOnly
            onClicked: {
                if (webviewItem) {
                    webviewItem.findText(findField.text);
                }
            }
            PlasmaComponents3.ToolTip.text: i18n("Find next")
            PlasmaComponents3.ToolTip.visible: hovered
            enabled: findField.text !== ""
        }

        PlasmaComponents3.Button {
            icon.name: "dialog-close"
            display: PlasmaComponents3.AbstractButton.IconOnly
            PlasmaComponents3.ToolTip.text: i18n("Close")
            PlasmaComponents3.ToolTip.visible: hovered
            onClicked: closeRequested()
        }
    }

    Behavior on height {
        NumberAnimation {
            duration: Kirigami.Units.shortDuration
            easing.type: Easing.InOutQuad
        }
    }

    function focusAndSelect() {
        findField.forceActiveFocus();
        findField.selectAll();
    }

    function clearSearch() {
        findField.text = "";
        if (webviewItem) {
            webviewItem.findText("");
        }
    }
}