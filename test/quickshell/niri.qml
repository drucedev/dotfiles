import Quickshell
import QtQuick
import "." as Bar

ShellRoot {
    id: root
    property int phase: 0

    Bar.Niri {
        id: niri
        onWorkspacesChanged: {
            if (root.phase === 0 && workspaces.length === 2) {
                root.phase = 1;
                // Requests must not be written on the EventStream socket.
                Qt.callLater(() => {
                    if (!niri.focus(7)) Qt.exit(1);
                });
            } else if (root.phase === 1 && workspaces.length === 0) {
                root.phase = 2;
            } else if (root.phase === 2 && workspaces.length === 1 && workspaces[0].id === 9) {
                console.log("PASS: Niri socket lifecycle");
                Qt.quit();
            }
        }
    }

    Bar.Workspaces { service: niri }
}
