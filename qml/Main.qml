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
    }

    Emulator {
        id: emu
        Component.onCompleted: play(Qt.application.arguments[1])
    }
}
