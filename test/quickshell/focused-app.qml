import Quickshell
import QtQuick
import "." as Bar

ShellRoot {
    id: root
    property var focusedWindow: ({ id: 1, app_id: "bar-test-app", title: "document", is_focused: true })
    property int phase: 0

    QtObject {
        id: service
        property var focusedWindow: root.focusedWindow
    }

    Bar.FocusedApp { id: app; service: service }

    Timer {
        interval: 50
        repeat: true
        running: true
        onTriggered: {
            if (root.phase === 0 && app.name === "Test App") {
                if (app.tooltip !== "document") {
                    console.error("title tooltip: " + app.tooltip);
                    Qt.exit(1);
                    return;
                }
                root.phase = 1;
                root.focusedWindow = { id: 2, app_id: "unknown-app", title: "Fallback Title", is_focused: true };
            } else if (root.phase === 1 && app.name === "unknown-app") {
                if (app.tooltip !== "Fallback Title") {
                    console.error("fallback tooltip: " + app.tooltip);
                    Qt.exit(1);
                    return;
                }
                root.phase = 2;
                root.focusedWindow = { id: 3, app_id: null, title: " Only Title ", is_focused: true };
            } else if (root.phase === 2 && app.name === "Only Title") {
                if (app.tooltip !== "") {
                    console.error("matching title must not tooltip");
                    Qt.exit(1);
                    return;
                }
                root.phase = 3;
                root.focusedWindow = null;
            } else if (root.phase === 3 && app.name === "") {
                console.log("PASS: focused app name");
                Qt.quit();
            }
        }
    }

    Timer {
        interval: 4000
        running: true
        onTriggered: {
            console.error("focused app timed out at phase " + root.phase + " name=" + app.name);
            Qt.exit(1);
        }
    }
}
