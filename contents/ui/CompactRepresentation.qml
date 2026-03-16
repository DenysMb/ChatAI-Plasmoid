/*
 *  SPDX-FileCopyrightText: 2024 Denys Madureira <denysmb@zoho.com>
 *  SPDX-FileCopyrightText: 2025 Bruno Gonçalves <bigbruno@gmail.com>
 *
 *  SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

import QtQuick
import QtQuick.Layouts

import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami

Item {
    id: compactRoot

    // Icon mode constants (must match ConfigAppearance.qml ComboBox order)
    readonly property int iconModeFavicon: 0
    readonly property int iconModeAdaptive: 1
    readonly property int iconModeDark: 2
    readonly property int iconModeLight: 3
    readonly property int iconModeOutlined: 4
    readonly property int iconModeFilled: 5
    readonly property int iconModeColorful: 6
    readonly property int iconModeCustom: 7

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
        
        // Colorful mode. If not in colorful mode, some models only have colorful icons available
        const hasOnlyColorfulIcon = mode !== iconModeColorful && ["lobechat", "bigagi"].includes(currentModel?.id);

        if (!currentModel || currentModel?.id === "blackbox" || hasOnlyColorfulIcon) {
            return `assets/logo-${colorContrast}.svg`;
        }

        if (currentModel.useIcon) {
            const style = mode === iconModeFilled ? "filled" : "outlined";
            return `assets/${style}/${currentModel.useIcon}-${colorContrast}.svg`;
        }

        if (mode === iconModeColorful) {
            return `assets/colorful/${currentModel.id}.svg`;
        }

        const style = mode === iconModeFilled ? "filled" : "outlined";
        return `assets/${style}/${currentModel.id}-${colorContrast}.svg`;
    }

    function getIconNameOrPath() {
        const mode = plasmoid.configuration.iconMode;
        
        if (mode === iconModeCustom) {
            return plasmoid.configuration.customIcon || fallbackIcon;
        }
        
        if (mode === iconModeFavicon) {
            const faviconUrl = plasmoid.configuration.favIcon || plasmoid.configuration.lastFavIcon;
            if (faviconUrl) {
                return faviconUrl.replace("image://favicon/", "");
            }
        }

        if (mode >= iconModeOutlined) {
            return getChatModelIcon() || fallbackIcon;
        }

        const contrast = getBackgroundColorContrast();
        if (mode === iconModeDark) return "assets/logo-dark.svg";
        if (mode === iconModeLight) return "assets/logo-light.svg";
        
        return `assets/logo-${contrast}.svg`;
    }

    function getBackgroundColorContrast() {
        // Use Kirigami.Theme for better Plasma 6 compatibility
        const color = Kirigami.Theme.backgroundColor;
        const luma = 0.2126 * color.r + 0.7152 * color.g + 0.0722 * color.b;
        return luma > 0.5 ? "dark" : "light";
    }
}
