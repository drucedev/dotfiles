import Quickshell
import Quickshell.Widgets
import QtQuick

BarButton {
    id: root
    required property var item
    implicitWidth: 16
    tooltip: [item.tooltipTitle || item.title, item.tooltipDescription].filter(Boolean).join("\n")

    IconImage {
        anchors.centerIn: parent
        implicitSize: 16
        source: root.item.icon
    }

    onClicked: button => {
        if (button === Qt.MiddleButton) {
            item.secondaryActivate();
        } else if (button === Qt.RightButton || (button === Qt.LeftButton && item.onlyMenu)) {
            const window = root.QsWindow.window;
            if (!window) return;
            const point = root.QsWindow.contentItem.mapFromItem(root, 0, root.height);
            item.display(window, point.x, point.y);
        } else if (button === Qt.LeftButton) {
            item.activate();
        }
    }
    onScrolled: (delta, horizontal) => item.scroll(delta, horizontal)
}
