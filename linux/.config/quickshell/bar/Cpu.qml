import Quickshell
import Quickshell.Io
import QtQuick
import "BarLogic.js" as Logic

BarButton {
    id: root
    property var previous: null
    text: "󰍛"
    tooltip: "CPU: collecting usage…"
    onClicked: button => {
        if (button === Qt.LeftButton) Quickshell.execDetached(["ghostty", "-e", "btop"]);
    }

    FileView {
        id: stat
        path: "/proc/stat"
        onLoaded: {
            const sample = Logic.cpuSample(text());
            root.tooltip = Logic.cpuUsage(root.previous, sample);
            root.previous = sample;
        }
        onLoadFailed: {
            root.previous = null;
            root.tooltip = "CPU usage unavailable";
        }
    }
    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: stat.reload()
    }
}
