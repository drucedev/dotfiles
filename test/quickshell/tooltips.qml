//@ pragma UseQApplication
import Quickshell
import QtQuick
import QtQuick.Controls
import "." as Bar

ShellRoot {
    property var tip: null

    FloatingWindow {
        visible: true
        implicitWidth: 100
        implicitHeight: 36
        Bar.BarButton {
            id: button
            tooltip: "Power\n\nSuper + Alt + Space"
        }
    }

    Component.onCompleted: Qt.callLater(() => {
        tip = button.data.find(object => object instanceof ToolTip);
        tip.delay = 0;
        tip.open();
    })

    Timer {
        interval: 100
        running: true
        repeat: true
        onTriggered: {
            if (!tip || !tip.opened) return;
            if (tip.contentItem.Window.window === button.Window.window) {
                console.error("Tooltip is clipped to the 36px panel window");
                Qt.exit(1);
                return;
            }
            console.log("PASS: tooltip renders outside the panel window");
            Qt.quit();
        }
    }
}
