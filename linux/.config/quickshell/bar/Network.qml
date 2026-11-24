import Quickshell.Networking
import Quickshell.Io
import QtQuick
import "BarLogic.js" as Logic

BarButton {
    id: root
    // The service's qmltypes mark ObjectModel as opaque; values is a runtime API.
    // qmllint disable missing-property
    property var devices: Networking.devices.values
    // qmllint enable missing-property
    readonly property var device: devices.find(device => device.connected && device.type === DeviceType.Wired)
        || devices.find(device => device.connected && device.type === DeviceType.Wifi) || null
    readonly property var wifi: device && device.type === DeviceType.Wifi
        ? device.networks.values.find(network => network.connected) : null
    readonly property var radio: ({ enabled: Networking.wifiEnabled, hardware: Networking.wifiHardwareEnabled })
    readonly property string kind: device ? (device.type === DeviceType.Wired ? "wired" : "wifi")
        : !radio.enabled || !radio.hardware ? "off" : "disconnected"
    property string address: ""
    property string queriedInterface: ""
    property int generation: 0
    property int queryGeneration: 0
    property bool refreshPending: false

    text: Logic.networkIcon(kind, wifi ? wifi.signalStrength : 0)
    foreground: kind === "off" ? Style.red : Style.text
    tooltip: Logic.networkTooltip(device ? device.name : "", address, kind, radio)
    onClicked: button => {
        if (button === Qt.LeftButton && radio.hardware) Networking.wifiEnabled = !radio.enabled;
    }
    onHoveredChanged: {
        if (hovered) refreshAddress();
    }
    onDeviceChanged: {
        generation++;
        address = "";
        if (hovered) refreshAddress();
    }

    // Fetch address details only on hover. Icon state is pushed by NetworkManager.
    function refreshAddress() {
        if (!device) return;
        if (query.running) {
            refreshPending = true;
            return;
        }
        refreshPending = false;
        queriedInterface = device.name;
        queryGeneration = generation;
        query.command = ["nmcli", "--escape", "no", "--get-values", "IP4.ADDRESS,IP6.ADDRESS", "device", "show", queriedInterface];
        query.running = true;
    }

    Process {
        id: query
        stdout: StdioCollector { id: output }
        onExited: (code, status) => {
            if (root.device && root.device.name === root.queriedInterface && root.generation === root.queryGeneration) {
                root.address = code === 0 ? Logic.networkAddress(output.text) : "IP address unavailable";
            }
            if (code !== 0) console.warn("nmcli address query failed with exit code " + code);
            if (root.refreshPending) Qt.callLater(root.refreshAddress);
        }
    }
}
