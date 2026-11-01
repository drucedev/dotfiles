pragma ComponentBehavior: Bound
import QtQuick
import "BarLogic.js" as Logic

Row {
    id: root
    required property var service

    Repeater {
        model: root.service.workspaces
        BarButton {
            required property var modelData
            text: Logic.workspaceIcon(modelData)
            foreground: modelData.is_active || modelData.is_focused ? Style.accent : Style.inactive
            opacity: modelData.active_window_id === null ? 0.5 : 1
            Accessible.name: "Workspace " + (modelData.name || modelData.idx) + " on " + modelData.output
            onClicked: button => {
                if (button === Qt.LeftButton) root.service.focus(modelData.id);
            }
        }
    }
}
