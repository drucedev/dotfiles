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
            tooltip: Logic.workspaceLabel(modelData)
            foreground: modelData.is_focused ? Style.accent : Style.inactive
            Accessible.name: Logic.workspaceLabel(modelData) + " on " + modelData.output
            onClicked: button => {
                if (button === Qt.LeftButton) root.service.focus(modelData.id);
            }
        }
    }
}
