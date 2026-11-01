import Quickshell.Services.Pipewire
import QtQuick
import "BarLogic.js" as Logic

BarButton {
    id: root
    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNode source: Pipewire.defaultAudioSource
    property var sinkAudio: sink && sink.ready ? sink.audio : null
    property var sourceAudio: source && source.ready ? source.audio : null
    readonly property bool headphones: sink && sink.ready && (
        sink.properties["device.form-factor"] === "headphones"
        || /headphone|headset/i.test(sink.description))
    property real wheelRemainder: 0

    PwObjectTracker { objects: [root.sink, root.source] }

    text: Logic.audioIcon(sinkAudio ? sinkAudio.volume : 0, sinkAudio ? sinkAudio.muted : false, headphones)
    foreground: sinkAudio && sinkAudio.muted ? Style.red : Style.text
    tooltip: sinkAudio ? "Volume: " + Math.round(sinkAudio.volume * 100) + "%" : "No audio output"

    onClicked: button => {
        const audio = button === Qt.LeftButton ? root.sinkAudio : button === Qt.RightButton ? root.sourceAudio : null;
        if (audio) audio.muted = !audio.muted;
    }
    onScrolled: (delta, horizontal) => {
        if (horizontal || !root.sinkAudio) return;
        const total = root.wheelRemainder + delta;
        const steps = Math.trunc(total / 120);
        root.wheelRemainder = total - steps * 120;
        if (steps) root.sinkAudio.volume = Math.max(0, Math.min(1, root.sinkAudio.volume + steps * 0.05));
    }
    onSinkAudioChanged: wheelRemainder = 0
}
