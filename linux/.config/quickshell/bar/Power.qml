import Quickshell
import QtQuick

BarButton {
    text: "󰐥"
    tooltip: "Power\n\nSuper + Alt + Space"
    foreground: hovered ? Style.red : Style.text
    onClicked: button => {
        if (button === Qt.LeftButton) {
            const bin = Quickshell.env("XDG_BIN_HOME") || Quickshell.env("HOME") + "/.local/bin";
            Quickshell.execDetached([bin + "/power-menu"]);
        }
    }
}
