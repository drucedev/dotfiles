import QtQuick
import QtQuick.Controls

Item {
    id: root

    property alias text: label.text
    property color foreground: Style.text
    property string tooltip: ""
    readonly property bool hovered: mouse.containsMouse
    signal clicked(int button)
    signal scrolled(real delta, bool horizontal)

    implicitWidth: Math.max(24, label.implicitWidth + 8)
    implicitHeight: Style.barHeight

    Text {
        id: label
        anchors.centerIn: parent
        color: root.foreground
        font.family: Style.fontFamily
        font.pixelSize: Style.fontSize
        textFormat: Text.PlainText
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onClicked: event => root.clicked(event.button)
        onWheel: event => {
            const horizontal = event.angleDelta.y === 0;
            root.scrolled(horizontal ? event.angleDelta.x : event.angleDelta.y, horizontal);
        }
    }

    ToolTip {
        // Item popups are clipped by the panel's 36px surface.
        popupType: Popup.Window
        y: root.height + 2
        visible: root.hovered && root.tooltip !== ""
        delay: 500
        text: root.tooltip
        contentItem: Text {
            text: root.tooltip
            color: Style.text
            font.family: Style.fontFamily
            font.pixelSize: Style.fontSize
            textFormat: Text.PlainText
        }
        background: Rectangle { color: Style.base }
    }

    Accessible.role: Accessible.Button
    Accessible.name: tooltip || text
    Accessible.onPressAction: root.clicked(Qt.LeftButton)
}
