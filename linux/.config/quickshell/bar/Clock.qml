import Quickshell
import QtQuick
import "BarLogic.js" as Logic

BarButton {
    id: root
    property bool alternate: false
    property date date: clock.date

    text: date.toLocaleString(Qt.locale("en_US"), Logic.clockFormat(date, alternate))
    onClicked: button => {
        if (button === Qt.LeftButton) root.alternate = !root.alternate;
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }
}
