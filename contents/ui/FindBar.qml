import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents3
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid

Rectangle {
    id: findBarRoot

    property bool barVisible: false
    readonly property bool animEnabled: plasmoid.configuration.enableAnimations
    readonly property real overlayOpacity: plasmoid.configuration.overlayOpacity

    signal findRequested(string text)
    signal findPreviousRequested(string text)
    signal closed()

    visible: barVisible
    height: visible ? findBarRow.height + Kirigami.Units.smallSpacing * 2 : 0
    color: Kirigami.Theme.backgroundColor
    opacity: overlayOpacity
    radius: Kirigami.Units.smallSpacing
    z: 5

    function focusField() {
        findField.forceActiveFocus();
        findField.selectAll();
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
            onTextChanged: if (text)
                findBarRoot.findRequested(text)
            onAccepted: findBarRoot.findRequested(text)
            Keys.onEscapePressed: findBarRoot.closed()

            Component.onCompleted: {
                if (findBarRoot.barVisible) {
                    forceActiveFocus();
                }
            }
        }

        PlasmaComponents3.Button {
            icon.name: "go-up"
            display: PlasmaComponents3.AbstractButton.IconOnly
            onClicked: findBarRoot.findPreviousRequested(findField.text)
            PlasmaComponents3.ToolTip.text: i18n("Find previous")
            PlasmaComponents3.ToolTip.visible: hovered
            enabled: findField.text !== ""
        }

        PlasmaComponents3.Button {
            icon.name: "go-down"
            display: PlasmaComponents3.AbstractButton.IconOnly
            onClicked: findBarRoot.findRequested(findField.text)
            PlasmaComponents3.ToolTip.text: i18n("Find next")
            PlasmaComponents3.ToolTip.visible: hovered
            enabled: findField.text !== ""
        }

        PlasmaComponents3.Button {
            icon.name: "dialog-close"
            display: PlasmaComponents3.AbstractButton.IconOnly
            PlasmaComponents3.ToolTip.text: i18n("Close")
            PlasmaComponents3.ToolTip.visible: hovered
            onClicked: findBarRoot.closed()
        }
    }

    Behavior on height {
        enabled: findBarRoot.animEnabled
        NumberAnimation {
            duration: Kirigami.Units.shortDuration
            easing.type: Easing.InOutQuad
        }
    }
}
