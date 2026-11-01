//@ pragma UseQApplication
import Quickshell
import QtQuick
// The test runner copies this fixture beside the production components.
import "." as Bar

ShellRoot {
    Bar.Clock { id: clock }

    QtObject { id: output; property bool muted: false; property real volume: 0.5 }
    QtObject { id: microphone; property bool muted: false; property real volume: 0.5 }
    Bar.Audio { id: audio; sinkAudio: output; sourceAudio: microphone }

    QtObject {
        id: trayItem
        property string icon: ""
        property string title: "Test tray"
        property string tooltipTitle: "Test tooltip"
        property string tooltipDescription: "Details"
        property bool onlyMenu: false
        property int activations: 0
        property int secondary: 0
        property int menus: 0
        property int delta: 0
        property bool horizontal: false
        function activate() { activations++; }
        function secondaryActivate() { secondary++; }
        function display(window, x, y) {
            if (!window || y !== 36) throw new Error("tray menu anchor");
            menus++;
        }
        function scroll(value, horizontalAxis) { delta = value; horizontal = horizontalAxis; }
    }
    FloatingWindow {
        Bar.TrayItem { id: tray; item: trayItem }
    }

    Component.onCompleted: Qt.callLater(() => {
        try {
            clock.date = new Date(2021, 0, 1, 12, 34);
            if (clock.text !== "Friday 12:34") throw new Error("English weekday/time: " + clock.text);
            clock.clicked(Qt.RightButton);
            if (clock.alternate) throw new Error("right click must not toggle clock");
            clock.clicked(Qt.LeftButton);
            if (clock.text !== "01 January W53 2021") throw new Error("English alternate date: " + clock.text);
            clock.clicked(Qt.LeftButton);
            if (clock.alternate) throw new Error("clock must toggle back");
            audio.clicked(Qt.LeftButton);
            if (!output.muted || microphone.muted) throw new Error("output mute");
            audio.clicked(Qt.RightButton);
            if (!microphone.muted) throw new Error("microphone mute");
            audio.scrolled(60, false);
            if (output.volume !== 0.5) throw new Error("partial wheel step");
            audio.scrolled(60, false);
            if (Math.abs(output.volume - 0.55) > 0.0001) throw new Error("5% scroll step");
            audio.scrolled(-240, false);
            if (Math.abs(output.volume - 0.45) > 0.0001) throw new Error("negative scroll steps");
            audio.scrolled(120, true);
            if (Math.abs(output.volume - 0.45) > 0.0001) throw new Error("horizontal volume scroll");
            output.volume = 0.99;
            audio.scrolled(120, false);
            if (output.volume !== 1) throw new Error("volume upper bound");
            output.volume = 0.01;
            audio.scrolled(-120, false);
            if (output.volume !== 0) throw new Error("volume lower bound");
            audio.sinkAudio = null;
            audio.sourceAudio = null;
            audio.clicked(Qt.LeftButton);
            audio.clicked(Qt.RightButton);
            audio.scrolled(120, false);
            if (audio.tooltip !== "No audio output") throw new Error("missing output handling");

            tray.clicked(Qt.LeftButton);
            tray.clicked(Qt.MiddleButton);
            tray.clicked(Qt.RightButton);
            trayItem.onlyMenu = true;
            tray.clicked(Qt.LeftButton);
            tray.scrolled(-120, true);
            if (trayItem.activations !== 1 || trayItem.secondary !== 1 || trayItem.menus !== 2)
                throw new Error("tray click dispatch");
            if (trayItem.delta !== -120 || !trayItem.horizontal) throw new Error("tray scroll");
            if (!tray.tooltip.includes("Details")) throw new Error("tray tooltip");
            console.log("PASS: component interactions");
            Qt.quit();
        } catch (error) {
            console.error(error);
            Qt.exit(1);
        }
    })
}
