import QtQuick
import QtQuick.Layouts 1.1
import org.kde.kirigami 2.20 as Kirigami
import org.kde.plasma.plasmoid 2.0

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
            return "assets/logo.svg";
        }
    }
}