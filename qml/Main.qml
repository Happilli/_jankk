pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import QtMultimedia
import Ryu.Extraa
import Jankk

Window {
    id: win
    visible: true
    width: 1280
    height: 720
    title: "jankk"
    color: theme.bg

    property bool playing: false
    property bool sfxMuted: false
    property bool hintVisible: false
    property string errorText: ""
    property alias query: searchBox.text

    QtObject {
        id: theme
        readonly property color bg: "#141218"
        readonly property color surface: "#1D1B20"
        readonly property color surfaceHigh: "#2B2930"
        readonly property color primary: "#D0BCFF"
        readonly property color primaryContainer: "#4F378B"
        readonly property color tertiary: "#EFB8C8"
        readonly property color danger: "#F2B8B5"
        readonly property color dangerContainer: "#601410"
        readonly property color textMain: "#E6E0E9"
        readonly property color dangerText: "#F9DEDC"
        readonly property color textDim: "#CAC4D0"
        readonly property color outline: "#938F99"
        readonly property color outlineVariant: "#49454F"
        readonly property string font: "Google Sans"
        readonly property int margin: 64
    }

    component Sfx: SoundEffect {
        property string file
        source: "qrc:/qt/qml/Jankk/sfx/" + file + ".wav"
        volume: 0.8
    }

    component KeyHint: Row {
        id: hint
        property string keyText: ""
        property string label: ""
        spacing: 8

        Item {
            width: Math.max(28, keyLabel.implicitWidth + 16)
            height: 22

            Text {
                id: keyLabel
                anchors.centerIn: parent
                text: hint.keyText
                color: theme.primary
                font.family: theme.font
                font.pixelSize: 12
                font.bold: true
            }
        }
        Text {
            height: 22
            verticalAlignment: Text.AlignVCenter
            text: hint.label
            color: theme.textDim
            font.family: theme.font
            font.pixelSize: 13
        }
    }

    Sfx {
        id: sfxNav
        file: "nav"
    }
    Sfx {
        id: sfxEdge
        file: "nav_edge"
    }
    Sfx {
        id: sfxType
        file: "type"
    }
    Sfx {
        id: sfxDelete
        file: "delete"
    }
    Sfx {
        id: sfxClear
        file: "clear"
    }
    Sfx {
        id: sfxSelect
        file: "select"
    }
    Sfx {
        id: sfxLaunch
        file: "launch"
    }
    Sfx {
        id: sfxExit
        file: "exit"
    }
    Sfx {
        id: sfxNoMatch
        file: "nomatch"
    }
    Sfx {
        id: sfxFullscreen
        file: "fullscreen"
    }
    Sfx {
        id: sfxBoot
        file: "boot"
    }

    Timer {
        interval: 200
        running: true
        onTriggered: sfxBoot.play()
    }

    Timer {
        id: errorTimer
        interval: 3500
        onTriggered: win.errorText = ""
    }

    Timer {
        id: hintTimer
        interval: 2800
        onTriggered: win.hintVisible = false
    }

    function launch(path) {
        sfxLaunch.play();
        emu.play(path);
        playing = true;
        hintVisible = true;
        hintTimer.restart();
    }
    function exitGame() {
        sfxExit.play();
        emu.stop();
        playing = false;
        hintVisible = false;
    }
    function toggleFullscreen() {
        sfxFullscreen.play();
        visibility = visibility === Window.FullScreen ? Window.Windowed : Window.FullScreen;
    }

    GameLibrary {
        id: library
        folder: Qt.application.arguments.length > 1 ? Qt.application.arguments[1] : "~/Games/encore"
        filter: win.query
    }

    Emulator {
        id: emu
        onError: msg => {
            win.playing = false;
            win.hintVisible = false;
            win.errorText = msg;
            errorTimer.restart();
            sfxNoMatch.play();
        }
    }

    FocusScope {
        id: launcher
        property string bgSource: library.count > 0 ? library.imageAt(list.currentIndex) : ""

        anchors.fill: parent
        visible: !win.playing
        focus: !win.playing

        Item {
            id: bgStack
            anchors.fill: parent
            clip: true
            layer.enabled: true
            layer.effect: MultiEffect {
                blurEnabled: true
                blur: 1
                blurMax: 32
                brightness: -0.27
            }

            Image {
                anchors.fill: parent
                source: launcher.bgSource
                fillMode: Image.PreserveAspectCrop
                asynchronous: false
                sourceSize.width: 640
                sourceSize.height: 360
            }
        }

        MaterialSearchBox {
            id: searchBox
            readonly property bool expanded: win.query !== "" || activeFocus

            anchors.horizontalCenter: parent.horizontalCenter
            y: 32
            width: expanded ? 440 : 200
            placeholderText: "Search"
            maxLength: 48
            font.family: theme.font

            springStiffness: 800
            springDamping: 0.6

            color: theme.surfaceHigh
            textColor: theme.textMain
            placeholderColor: theme.outline
            iconColor: theme.textDim
            cursorColor: theme.primary
            selectionColor: theme.primaryContainer
            borderWidth: 2
            borderColor: expanded ? theme.primary : theme.outlineVariant

            Behavior on width {
                SpringAnimation {
                    spring: 6.0
                    damping: 0.5
                    epsilon: 0.25
                }
            }

            onAccepted: {
                sfxSelect.play();
                list.forceActiveFocus();
            }
            Keys.onPressed: e => {
                if (e.key === Qt.Key_Down || e.key === Qt.Key_Escape) {
                    list.forceActiveFocus();
                    e.accepted = true;
                    return;
                }
                if (e.key === Qt.Key_Backspace && text !== "") {
                    sfxDelete.play();
                    return;
                }
                const mods = e.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier);
                if (e.text.length === 1 && e.text >= " " && e.text !== "\x7f" && mods === 0)
                    sfxType.play();
            }
        }

        ListView {
            id: list
            readonly property real stride: 420
            property string currentTitle: ""
            property string currentPath: ""
            property string currentCover: ""

            anchors.left: parent.left
            anchors.right: parent.right
            y: parent.height * 0.2
            height: parent.height * 0.56
            orientation: ListView.Horizontal
            model: library
            spacing: 40
            leftMargin: width / 2 - 190
            rightMargin: width / 2 - 190
            focus: true
            interactive: false
            keyNavigationEnabled: true
            keyNavigationWraps: false
            cacheBuffer: 1600
            boundsBehavior: Flickable.StopAtBounds
            highlightRangeMode: ListView.StrictlyEnforceRange
            preferredHighlightBegin: width / 2 - 190
            preferredHighlightEnd: width / 2 + 190
            highlightFollowsCurrentItem: true
            highlightMoveVelocity: -1
            highlightMoveDuration: 420

            onCurrentIndexChanged: {
                if (!win.sfxMuted && currentIndex >= 0)
                    sfxNav.play();
            }

            Keys.onReturnPressed: if (currentPath !== "")
                win.launch(currentPath)
            Keys.onEnterPressed: if (currentPath !== "")
                win.launch(currentPath)
            Keys.onPressed: e => {
                if (e.key === Qt.Key_F11) {
                    win.toggleFullscreen();
                    return;
                }
                if (count > 0 && ((e.key === Qt.Key_Left && currentIndex <= 0) || (e.key === Qt.Key_Right && currentIndex >= count - 1)))
                    sfxEdge.play();
                if (e.key === Qt.Key_Escape && win.query !== "") {
                    sfxClear.play();
                    win.query = "";
                    e.accepted = true;
                    return;
                }
                if (e.key === Qt.Key_Backspace && win.query !== "") {
                    sfxDelete.play();
                    searchBox.forceActiveFocus();
                    win.query = win.query.slice(0, -1);
                    e.accepted = true;
                    return;
                }
                const t = e.text;
                const mods = e.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier);
                if (t.length === 1 && t >= " " && t !== "\x7f" && mods === 0) {
                    if (t === " " && win.query === "")
                        return;
                    sfxType.play();
                    searchBox.forceActiveFocus();
                    win.query += t;
                    e.accepted = true;
                }
            }

            delegate: Item {
                id: tile
                required property string title
                required property string image
                required property string path
                readonly property bool current: ListView.isCurrentItem
                readonly property real off: (x + width / 2 - list.contentX - list.width / 2) / list.stride
                readonly property real dist: Math.min(1, Math.abs(off))

                function publish() {
                    if (!current)
                        return;
                    list.currentTitle = title;
                    list.currentPath = path;
                    list.currentCover = image;
                }

                onCurrentChanged: publish()
                Component.onCompleted: publish()

                width: 380
                height: list.height

                Rectangle {
                    id: card
                    readonly property int frame: 3

                    anchors.centerIn: parent
                    width: 380
                    height: 254
                    scale: 1.12 - 0.22 * tile.dist
                    color: theme.surface

                    Item {
                        anchors.fill: parent
                        anchors.margins: card.frame
                        clip: true

                        Image {
                            id: art
                            anchors.fill: parent
                            source: tile.image
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: false
                            sourceSize.width: 480
                            smooth: true
                            mipmap: true
                            visible: tile.image !== "" && status !== Image.Error
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: tile.image === "" || art.status === Image.Error
                        text: tile.title
                        color: theme.textMain
                        width: parent.width - 40
                        wrapMode: Text.Wrap
                        horizontalAlignment: Text.AlignHCenter
                        font.family: theme.font
                        font.pixelSize: 20
                    }
                }
            }
        }

        Item {
            id: selector
            readonly property string cornerPath: {
                const w = width;
                const h = height;
                const l = 26;
                return `M 0 ${l} L 0 0 L ${l} 0 M ${w} ${h - l} L ${w} ${h} L ${w - l} ${h}`;
            }

            x: list.x + list.width / 2 - width / 2
            y: list.y + list.height / 2 - height / 2
            width: 380 * 1.12
            height: 254 * 1.12
            visible: library.count > 0

            Shape {
                anchors.fill: parent
                anchors.margins: -3

                ShapePath {
                    strokeColor: theme.primary
                    strokeWidth: 3
                    fillColor: "transparent"
                    capStyle: ShapePath.SquareCap
                    PathSvg {
                        path: selector.cornerPath
                    }
                }
            }
        }

        Connections {
            target: library
            function onCountChanged() {
                win.sfxMuted = true;
                list.currentIndex = library.count > 0 ? 0 : -1;
                win.sfxMuted = false;
                if (library.count === 0) {
                    list.currentTitle = "";
                    list.currentPath = "";
                    list.currentCover = "";
                }
                if (library.count === 0 && win.query !== "")
                    sfxNoMatch.play();
            }
        }

        Column {
            anchors.centerIn: list
            visible: library.count === 0
            spacing: 12

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: win.query === "" ? "No games found" : "No match for \"" + win.query + "\""
                color: theme.textDim
                font.family: theme.font
                font.pixelSize: 24
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: win.query === "" ? "Drop .gba files into your ROM folder" : "Press Esc to clear the search"
                color: theme.outline
                font.family: theme.font
                font.pixelSize: 14
            }
        }

        Column {
            id: info
            anchors.horizontalCenter: parent.horizontalCenter
            y: Math.min(parent.height * 0.77, parent.height - 170)
            width: parent.width - theme.margin * 2
            spacing: 10
            visible: library.count > 0

            Text {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                text: list.currentTitle
                color: theme.textMain
                font.family: theme.font
                font.pixelSize: 36
                font.bold: true
            }

            Text {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: (list.currentIndex + 1) + " / " + library.count
                color: theme.textDim
                font.family: theme.font
                font.pixelSize: 16
            }
        }

        Item {
            anchors.horizontalCenter: parent.horizontalCenter
            y: parent.height - 56
            width: hintRow.implicitWidth + 48
            height: 40

            Row {
                id: hintRow
                anchors.centerIn: parent
                spacing: 30

                KeyHint {
                    keyText: "\u25C0  \u25B6"
                    label: "Browse"
                }
                KeyHint {
                    keyText: "Enter"
                    label: "Launch"
                }
                KeyHint {
                    keyText: "A-Z"
                    label: "Search"
                }
                KeyHint {
                    keyText: "Esc"
                    label: "Clear"
                }
                KeyHint {
                    keyText: "F11"
                    label: "Fullscreen"
                }
            }
        }
    }

    GbaView {
        anchors.fill: parent
        source: emu
        visible: win.playing
        focus: win.playing

        Keys.onEscapePressed: win.exitGame()
        Keys.onPressed: e => {
            if (e.key === Qt.Key_F11) {
                win.toggleFullscreen();
                return;
            }
            if (!e.isAutoRepeat)
                emu.keyEvent(e.key, true);
        }
        Keys.onReleased: e => {
            if (!e.isAutoRepeat)
                emu.keyEvent(e.key, false);
        }
    }

    Rectangle {
        id: ingameHint
        z: 10
        visible: win.playing && win.hintVisible
        anchors.horizontalCenter: parent.horizontalCenter
        y: 28
        width: hintText.implicitWidth + 36
        height: 32
        color: theme.surface
        border.width: 1
        border.color: theme.primary

        Text {
            id: hintText
            anchors.centerIn: parent
            text: "Esc  \u2022  Return to menu"
            color: theme.primary
            font.family: theme.font
            font.pixelSize: 13
        }
    }

    Rectangle {
        id: toast
        z: 20
        anchors.horizontalCenter: parent.horizontalCenter
        y: win.height - 100
        width: toastText.implicitWidth + 44
        height: 36
        color: theme.dangerContainer
        border.width: 1
        border.color: theme.danger
        visible: win.errorText !== ""

        Text {
            id: toastText
            anchors.centerIn: parent
            text: win.errorText
            color: theme.dangerText
            font.family: theme.font
            font.pixelSize: 13
        }
    }

    onActiveChanged: if (!active)
        emu.releaseAll()
}
