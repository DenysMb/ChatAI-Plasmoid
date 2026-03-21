import QtQuick
import QtQuick.Layouts
import QtWebEngine
import org.kde.plasma.components as PlasmaComponents3
import org.kde.kirigami as Kirigami

Column {
    id: downloadsBarRoot

    property var downloadsModel: null
    property var downloadCacheRef: ({})

    visible: downloadsModel !== null && downloadsModel.count > 0
    spacing: 4

    function getOpenPath(path) {
        return path.replace(/^file:\/+/, '').replace(/^\/+/, '/');
    }

    Repeater {
        model: downloadsBarRoot.downloadsModel

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
                            return model.fileName + " - Completed";
                        }
                        if (model.isPdfExport) {
                            return model.fileName + " - Saving PDF...";
                        }
                        let progress = Math.round((model.progress || 0) * 100);
                        let size = "";
                        if (model.totalBytes > 0) {
                            let received = (model.receivedBytes / 1024 / 1024).toFixed(1);
                            let total = (model.totalBytes / 1024 / 1024).toFixed(1);
                            size = ` (${received}/${total} MB)`;
                        }
                        return model.fileName + " - " + progress + "%" + size;
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
                                Qt.openUrlExternally(downloadsBarRoot.getOpenPath(model.fullPath));
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
                                Qt.openUrlExternally(downloadsBarRoot.getOpenPath(dirPath));
                            }
                        }
                    }

                    PlasmaComponents3.Button {
                        icon.name: "dialog-close"
                        PlasmaComponents3.ToolTip.text: i18n("Close")
                        PlasmaComponents3.ToolTip.visible: hovered
                        onClicked: {
                            downloadsBarRoot.downloadsModel.remove(model.index);
                        }
                    }
                }

                PlasmaComponents3.Button {
                    icon.name: "dialog-cancel"
                    visible: model.state === WebEngineDownloadRequest.DownloadInProgress && !model.isPdfExport
                    PlasmaComponents3.ToolTip.text: i18n("Cancel")
                    PlasmaComponents3.ToolTip.visible: hovered
                    onClicked: {
                        let downloadData = downloadsBarRoot.downloadCacheRef[model.downloadId];
                        if (downloadData && downloadData.download) {
                            downloadData.download.receivedBytesChanged.disconnect(downloadData.bytesConnection);
                            downloadData.download.stateChanged.disconnect(downloadData.stateConnection);
                            downloadData.download.cancel();
                            delete downloadsBarRoot.downloadCacheRef[model.downloadId];
                            downloadsBarRoot.downloadsModel.remove(index);
                        }
                    }
                }
            }
        }
    }
}
