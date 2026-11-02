import QtQuick
import Jankk

Window {
    visible: true
    width: 960
    height: 640
    title: "jankk"
    color: "black"

    GbaView {
        anchors.fill: parent
        source: emu
        focus: true

        Component.onCompleted: forceActiveFocus()

        Keys.onPressed: e => {
            if (!e.isAutoRepeat)
                emu.keyEvent(e.key, true);
        }
        Keys.onReleased: e => {
            if (!e.isAutoRepeat)
                emu.keyEvent(e.key, false);
        }
    }

    Emulator {
        id: emu
        Component.onCompleted: play(Qt.application.arguments[1])
    }
}
