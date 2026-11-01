//@ pragma UseQApplication
pragma ComponentBehavior: Bound
import Quickshell
import Quickshell.Wayland
import QtQuick

ShellRoot {
    Niri { id: niri }

    Variants {
        model: Quickshell.screens.filter(screen => screen.name === "DP-5")

        // Quickshell selects the creatable layer-shell backend at runtime.
        // qmllint disable uncreatable-type
        PanelWindow {
            // qmllint enable uncreatable-type
            required property var modelData
            screen: modelData
            anchors { top: true; left: true; right: true }
            implicitHeight: Style.barHeight
            color: Style.background
            exclusiveZone: Style.barHeight
            WlrLayershell.namespace: "quickshell-bar"
            WlrLayershell.layer: WlrLayer.Top

            Workspaces {
                service: niri
                anchors.left: parent.left
                anchors.leftMargin: 8
                anchors.verticalCenter: parent.verticalCenter
            }

            Clock { anchors.centerIn: parent }

            Row {
                anchors.right: parent.right
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                spacing: 20

                Tray {}
                Network {}
                Audio {}
                Cpu {}
                Power {}
            }
        }
    }
}
