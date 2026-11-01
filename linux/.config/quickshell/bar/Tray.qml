import Quickshell.Services.SystemTray
import QtQuick

Item {
    implicitWidth: icons.implicitWidth > 0 ? icons.implicitWidth + 8 : 0
    implicitHeight: Style.barHeight
    visible: icons.implicitWidth > 0

    Row {
        id: icons
        anchors.centerIn: parent
        spacing: 17
        Repeater {
            // The service's qmltypes mark ObjectModel as opaque; values is a runtime API.
            // qmllint disable missing-property
            model: SystemTray.items.values.filter(item => item.status !== Status.Passive)
            // qmllint enable missing-property
            TrayItem {
                required property var modelData
                item: modelData
            }
        }
    }
}
