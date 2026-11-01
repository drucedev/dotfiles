import Quickshell
import QtQuick

ShellRoot {
    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    PanelWindow {
        anchors {
            top: true
            left: true
            right: true
        }

        implicitHeight: 32
        color: "#1e1e2e" // Catppuccin Mocha base

        Text {
            anchors.centerIn: parent
            text: Qt.formatDateTime(clock.date, "hh:mm")
            color: "#cba6f7" // Catppuccin Mocha mauve
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 15
        }
    }
}
