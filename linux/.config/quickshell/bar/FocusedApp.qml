pragma ComponentBehavior: Bound
import Quickshell
import QtQuick
import QtQuick.Controls
import "BarLogic.js" as Logic

Item {
    id: root
    required property var service

    // Desktop entries are scanned after startup. A constant applications model
    // does not notify bindings, so the revision forces the name to resolve.
    property int desktopRevision: 0
    readonly property var window: service.focusedWindow
    readonly property string appId: window && window.app_id ? String(window.app_id) : ""
    readonly property var entry: {
        if (desktopRevision === 0 || appId === "") return null;
        return DesktopEntries.byId(appId) || DesktopEntries.heuristicLookup(appId);
    }
    readonly property string name: desktopRevision === 0 ? "" : Logic.appName(window, entry && entry.name ? entry.name : "")
    readonly property string title: window && window.title ? String(window.title).trim() : ""
    readonly property string tooltip: name !== "" && title !== "" && title !== name ? title : ""

    visible: name !== ""
    implicitWidth: visible ? Math.min(280, label.implicitWidth) : 0
    implicitHeight: Style.barHeight

    Component.onCompleted: {
        if (DesktopEntries.applications.values.length > 0) root.desktopRevision = 1;
    }

    Connections {
        target: DesktopEntries
        function onApplicationsChanged() { root.desktopRevision++; }
    }

    Text {
        id: label
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        text: root.name
        color: Style.text
        font.family: Style.fontFamily
        font.pixelSize: Style.fontSize
        textFormat: Text.PlainText
        elide: Text.ElideRight
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
    }

    ToolTip {
        popupType: Popup.Window
        y: root.height + 2
        visible: mouse.containsMouse && root.tooltip !== ""
        delay: 500
        text: root.tooltip
        contentItem: Text {
            text: root.tooltip
            color: Style.text
            font.family: Style.fontFamily
            font.pixelSize: Style.fontSize
            textFormat: Text.PlainText
        }
        background: Rectangle { color: Style.base }
    }

    Accessible.role: Accessible.StaticText
    Accessible.name: name
}
