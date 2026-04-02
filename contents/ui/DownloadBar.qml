/*
 *  SPDX-FileCopyrightText: 2024 Denys Madureira <denysmb@zoho.com>
 *  SPDX-FileCopyrightText: 2025 Bruno Gonçalves <bigbruno@gmail.com>
 *
 *  SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

import QtQuick
import QtQuick.Layouts
import QtWebEngine

import org.kde.plasma.components as PlasmaComponents3
import org.kde.kirigami as Kirigami

Column {
    id: downloadsBar

    property var downloadsModel
    property var downloadCache
    property var webviewItem

    visible: downloadsModel && downloadsModel.count > 0
    spacing: 4

    anchors {
        left: parent.left
        right: parent.right
        bottom: parent.bottom
    }

    Repeater {
        model: downloadsModel

        delegate: Rectangle {
            width: parent.width
            height: 40
            color: Kirigami.Theme.backgroundColor
            opacity: 0.9

            RowLayout {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 8

                PlasmaComponents3.Label {
                    text: {
                        if (model.state === WebEngineDownloadRequest.DownloadCompleted) {
                            return i18n("%1 - Completed", model.fileName);
                        }
                        if (model.isPdfExport) {
                            return i18n("%1 - Saving PDF...", model.fileName);
                        }
                        let progress = Math.round((model.progress || 0) * 100);
                        let size = "";
                        if (model.totalBytes > 0) {
                            let received = (model.receivedBytes / 1024 / 1024).toFixed(1);
                            let total = (model.totalBytes / 1024 / 1024).toFixed(1);
                            size = ` (${received}/${total} MB)`;
                        }
                        return i18n("%1 - %2%%3", model.fileName, progress, size);
                    }
                    Layout.fillWidth: true
                    elide: Text.ElideMiddle
                }

                PlasmaComponents3.ProgressBar {
                    Layout.fillWidth: true
                    indeterminate: model.isPdfExport
                    from: 0
                    to: 1
                    value: model.progress || 0
                    visible: model.state === WebEngineDownloadRequest.DownloadInProgress
                }

                RowLayout {
                    visible: model.state === WebEngineDownloadRequest.DownloadCompleted
                    spacing: 4

                    PlasmaComponents3.Button {
                        icon.name: "document-open"
                        PlasmaComponents3.ToolTip.text: i18n("Open file")
                        PlasmaComponents3.ToolTip.visible: hovered
                        onClicked: {
                            if (model.fullPath) {
                                let openPath = getOpenPath(model.fullPath);
                                Qt.openUrlExternally(openPath);
                            }
                        }
                    }

                    PlasmaComponents3.Button {
                        icon.name: "folder-open"
                        PlasmaComponents3.ToolTip.text: i18n("Open folder")
                        PlasmaComponents3.ToolTip.visible: hovered
                        onClicked: {
                            if (model.fullPath) {
                                let dirPath = model.fullPath.substring(0, model.fullPath.lastIndexOf("/"));
                                let openPath = getOpenPath(dirPath);
                                Qt.openUrlExternally(openPath);
                            }
                        }
                    }

                    PlasmaComponents3.Button {
                        icon.name: "dialog-close"
                        PlasmaComponents3.ToolTip.text: i18n("Close")
                        PlasmaComponents3.ToolTip.visible: hovered
                        onClicked: {
                            downloadsModel.remove(model.index);
                        }
                    }
                }

                PlasmaComponents3.Button {
                    icon.name: "dialog-cancel"
                    visible: model.state === WebEngineDownloadRequest.DownloadInProgress && !model.isPdfExport
                    PlasmaComponents3.ToolTip.text: i18n("Cancel")
                    PlasmaComponents3.ToolTip.visible: hovered
                    onClicked: {
                        let downloadData = downloadCache && downloadCache[model.downloadId];
                        if (downloadData && downloadData.download) {
                            downloadData.download.receivedBytesChanged.disconnect(downloadData.bytesConnection);
                            downloadData.download.stateChanged.disconnect(downloadData.stateConnection);
                            downloadData.download.cancel();
                            delete downloadCache[model.downloadId];
                            downloadsModel.remove(index);
                        }
                    }
                }
            }
        }
    }

    function getOpenPath(path) {
        if (Qt.platform.os === "windows" || Qt.platform.os === "osx") {
            return "file:///" + path;
        }
        return "file://" + path;
    }
}