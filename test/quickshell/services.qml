//@ pragma UseQApplication
import Quickshell
import Quickshell.Networking
import QtQuick
import "." as Bar

ShellRoot {
    id: root
    property bool started: false
    property int phase: 0

    QtObject {
        id: accessPoint
        property bool connected: true
        property real signalStrength: 0.75
    }
    QtObject { id: networks; property var values: [accessPoint] }
    QtObject {
        id: wifi
        property int type: DeviceType.Wifi
        property bool connected: true
        property string name: "wifi-test"
        property var networks: networks
    }
    QtObject {
        id: wired
        property int type: DeviceType.Wired
        property bool connected: true
        property string name: "wired-test"
    }
    Bar.Network { id: network; devices: [] }
    Bar.Cpu { id: cpu }
    Bar.Power { id: power }
    Bar.Tray {}

    Component.onCompleted: Qt.callLater(() => {
        try {
            if (network.kind !== "disconnected") throw new Error("network disconnected state");
            network.devices = [wifi];
            if (network.kind !== "wifi" || network.text !== "󰤥") throw new Error("Wi-Fi state");
            accessPoint.signalStrength = 1;
            if (network.text !== "󰤨") throw new Error("signal change must update icon");
            network.refreshAddress();
            network.devices = [wifi, wired];
            if (network.kind !== "wired") throw new Error("wired preference");
            network.refreshAddress();
            cpu.clicked(Qt.LeftButton);
            power.clicked(Qt.LeftButton);
            root.started = true;
        } catch (error) {
            console.error(error);
            Qt.exit(1);
        }
    })

    Timer {
        interval: 25
        running: true
        repeat: true
        onTriggered: {
            if (!root.started) return;
            if (root.phase === 1) {
                if (network.address !== "IP address unavailable") return;
                console.log("PASS: native services and command boundaries");
                Qt.quit();
                return;
            }
            if (network.address === "192.0.2.1") {
                console.error("stale Wi-Fi response was applied to wired interface");
                Qt.exit(1);
            }
            if (network.address !== "192.0.2.2" || !cpu.previous || !cpu.previous.cpu) return;
            if (network.tooltip !== "wired-test: 192.0.2.2") {
                console.error("network IP tooltip");
                Qt.exit(1);
            }
            wired.connected = false;
            if (network.kind !== "wifi") {
                console.error("network must react to disconnection");
                Qt.exit(1);
            }
            root.phase = 1;
            wifi.name = "failed-test";
            network.refreshAddress();
        }
    }
}
