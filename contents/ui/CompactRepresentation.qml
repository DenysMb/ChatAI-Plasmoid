import QtQuick
import QtQuick.Layouts 1.1
import org.kde.kirigami 2.20 as Kirigami
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.0 as PlasmaCore

Loader {
    id: favIconLoader
    active: Plasmoid.configuration.useFavIcon
    asynchronous: true
    sourceComponent: Image {
        asynchronous: true
        cache: false
        fillMode: Image.PreserveAspectFit
        source: Plasmoid.configuration.favIcon
    }

    TapHandler {
        property bool wasExpanded: false

        acceptedButtons: Qt.LeftButton

        onPressedChanged: if (pressed) {
            wasExpanded = root.expanded;
        }
        onTapped: root.expanded = !wasExpanded
    }

    Kirigami.Icon {
        anchors.fill: parent
        visible: favIconLoader.item?.status !== Image.Ready
        source: Qt.resolvedUrl(getIcon())
    }

    function getIcon() {
        if (Plasmoid.configuration.useDefaultDarkIcon) {
            return "assets/logo-dark.svg";
        } else if (Plasmoid.configuration.useDefaultLightIcon) {
            return "assets/logo-light.svg";
        } else {
            const colorContrast = getBackgroundColorContrast();
        
            return `assets/logo-${colorContrast}.svg`;
        }
    }

    function getBackgroundColorContrast() {
        const hex = `${PlasmaCore.Theme.backgroundColor}`.substring(1);
        const r = parseInt(hex.substring(0, 2), 16);
        const g = parseInt(hex.substring(2, 4), 16);
        const b = parseInt(hex.substring(4, 6), 16);
        const luma = 0.2126 * r + 0.7152 * g + 0.0722 * b;
        
        return luma > 128 ? "dark" : "light";
    }
}