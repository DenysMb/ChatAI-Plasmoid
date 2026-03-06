import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore

Item {
    id: compactRoot

    property var models: []
    property var webview: null
    property string fallbackIcon: "help-about"

    readonly property bool isVertical: plasmoid.formFactor === PlasmaCore.Types.Vertical

    Layout.minimumWidth: isVertical ? 0 : Kirigami.Units.iconSizes.large
    Layout.minimumHeight: isVertical ? Kirigami.Units.iconSizes.large : 0

    implicitWidth: Kirigami.Units.iconSizes.large
    implicitHeight: Kirigami.Units.iconSizes.large

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        onClicked: root.expanded = !root.expanded
    }

    Kirigami.Icon {
        anchors.fill: parent
        // Use a function that returns a URL or icon name appropriately
        source: getIconSource()
    }

    function getIconSource() {
        let icon = getIconNameOrPath();
        if (icon.indexOf("/") !== -1 || icon.endsWith(".svg") || icon.endsWith(".png")) {
            return Qt.resolvedUrl(icon);
        }
        return icon;
    }

    function getChatModelIcon() {
        if (!models || models.length === 0) return `assets/logo-${getBackgroundColorContrast()}.svg`;

        const mode = plasmoid.configuration.iconMode;
        const currentModel = models.find(model => plasmoid.configuration.url.includes(model.url));
        const colorContrast = getBackgroundColorContrast();
        
        // Mode 6 is Colorful. If not in colorful mode, some models only have colorful icons available
        const hasOnlyColorfulIcon = mode !== 6 && ["lobechat", "bigagi"].includes(currentModel?.id);

        if (!currentModel || currentModel?.id === "blackbox" || hasOnlyColorfulIcon) {
            return `assets/logo-${colorContrast}.svg`;
        }

        if (currentModel.useIcon) {
            const style = mode === 5 ? "filled" : "outlined";
            return `assets/${style}/${currentModel.useIcon}-${colorContrast}.svg`;
        }

        if (mode === 6) {
            return `assets/colorful/${currentModel.id}.svg`;
        }

        const style = mode === 5 ? "filled" : "outlined";
        return `assets/${style}/${currentModel.id}-${colorContrast}.svg`;
    }

    function getIconNameOrPath() {
        const mode = plasmoid.configuration.iconMode;
        
        if (mode === 7) {
            return plasmoid.configuration.customIcon || fallbackIcon;
        }
        
        if (mode === 0) {
            const faviconUrl = plasmoid.configuration.favIcon || plasmoid.configuration.lastFavIcon;
            if (faviconUrl) {
                return faviconUrl.replace("image://favicon/", "");
            }
        }

        if (mode >= 4) {
            return getChatModelIcon() || fallbackIcon;
        }

        const contrast = getBackgroundColorContrast();
        if (mode === 2) return "assets/logo-dark.svg";
        if (mode === 3) return "assets/logo-light.svg";
        
        return `assets/logo-${contrast}.svg`;
    }

    function getBackgroundColorContrast() {
        // Use Kirigami.Theme for better Plasma 6 compatibility
        const color = Kirigami.Theme.backgroundColor;
        const luma = 0.2126 * color.r + 0.7152 * color.g + 0.0722 * color.b;
        return luma > 0.5 ? "dark" : "light";
    }
}
