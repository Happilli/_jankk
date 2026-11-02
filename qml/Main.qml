pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Effects
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
    property alias query: searchBox.text

    QtObject {
        id: theme
        readonly property color bg: "#141218"
        readonly property color surface: "#1D1B20"
        readonly property color surfaceHigh: "#2B2930"
        readonly property color primary: "#D0BCFF"
        readonly property color textMain: "#E6E0E9"
        readonly property color textDim: "#CAC4D0"
        readonly property color outline: "#938F99"
        readonly property string font: "Google Sans"
        readonly property int margin: 64
    }

    component Sfx: SoundEffect {
        property string file
        source: "qrc:/qt/qml/Jankk/sfx/" + file + ".wav"
        volume: 0.8
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

    function launch(path) {
        sfxLaunch.play();
        emu.play(path);
        playing = true;
    }
    function exitGame() {
        sfxExit.play();
        emu.stop();
        playing = false;
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
        onError: msg => win.playing = false
    }

    FocusScope {
        id: launcher
        property string bgSource: library.count > 0 ? library.imageAt(list.currentIndex) : ""

        anchors.fill: parent
        visible: !win.playing
        focus: !win.playing

        Image {
            id: bg
            anchors.fill: parent
            source: launcher.bgSource
            fillMode: Image.PreserveAspectCrop
            asynchronous: false
            sourceSize.width: 320
            sourceSize.height: 180
            layer.enabled: true
            layer.effect: MultiEffect {
                blurEnabled: true
                blur: 1.0
                blurMax: 64
                brightness: -0.55
                saturation: 0.4
            }
        }
        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop {
                    position: 0.0
                    color: Qt.alpha(theme.bg, 0.9)
                }
                GradientStop {
                    position: 0.35
                    color: "transparent"
                }
                GradientStop {
                    position: 0.65
                    color: "transparent"
                }
                GradientStop {
                    position: 1.0
                    color: Qt.alpha(theme.bg, 0.95)
                }
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
            selectionColor: Qt.alpha(theme.primary, 0.35)
            borderWidth: 2
            borderColor: Qt.alpha(theme.textMain, 0.1)

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
                }
            }
        }

        ListView {
            id: list
            readonly property real stride: 420
            property bool animateTiles: true
            property string currentTitle: ""
            property string currentPath: ""
            property string currentCover: ""

            function targetX() {
                return originX + Math.max(0, currentIndex) * stride - leftMargin;
            }

            function snap() {
                animateTiles = false;
                contentX = targetX();
                settle.restart();
            }

            anchors.left: parent.left
            anchors.right: parent.right
            y: parent.height * 0.22
            height: parent.height * 0.5
            orientation: ListView.Horizontal
            model: library
            spacing: 40
            leftMargin: width / 2 - 190
            rightMargin: width / 2 - 190
            focus: true
            interactive: false
            keyNavigationEnabled: true
            cacheBuffer: 1600
            highlightRangeMode: ListView.NoHighlightRange
            highlightMoveDuration: 0

            onCurrentIndexChanged: {
                contentX = targetX();
                if (!win.sfxMuted && currentIndex >= 0)
                    sfxNav.play();
            }
            onLeftMarginChanged: snap()
            Component.onCompleted: Qt.callLater(snap)

            Behavior on contentX {
                enabled: list.animateTiles
                SmoothedAnimation {
                    velocity: 2600
                    reversingMode: SmoothedAnimation.Sync
                }
            }

            Timer {
                id: settle
                interval: 80
                onTriggered: list.animateTiles = true
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
                readonly property real dist: Math.min(1, Math.abs(x + width / 2 - list.contentX - list.width / 2) / list.stride)

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

                Item {
                    id: card
                    anchors.centerIn: parent
                    width: 380
                    height: 254
                    scale: 1.12 - 0.22 * tile.dist
                    opacity: 1.0 - 0.4 * tile.dist

                    Rectangle {
                        anchors.fill: parent
                        radius: 12
                        color: theme.surface
                    }

                    Image {
                        id: art
                        anchors.fill: parent
                        anchors.margins: 3
                        source: tile.image
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: false
                        sourceSize.width: 480
                        visible: false
                    }
                    Rectangle {
                        id: artMask
                        anchors.fill: art
                        radius: 9
                        layer.enabled: true
                        visible: false
                    }
                    MultiEffect {
                        anchors.fill: art
                        source: art
                        maskEnabled: true
                        maskSource: artMask
                        visible: tile.image !== "" && art.status !== Image.Error
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
            x: list.x + list.width / 2 - width / 2
            y: list.y + list.height / 2 - height / 2
            width: 380 * 1.12
            height: 254 * 1.12
            visible: library.count > 0

            Rectangle {
                id: selectorFrame
                anchors.fill: parent
                radius: 12 * 1.12
                color: "transparent"
                border.width: 3
                border.color: theme.primary
                visible: false
            }
            MultiEffect {
                anchors.fill: selectorFrame
                source: selectorFrame
                shadowEnabled: true
                shadowColor: theme.primary
                shadowBlur: 1.0
                shadowOpacity: 0.4
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
                list.snap();
                Qt.callLater(list.snap);
                if (library.count === 0 && win.query !== "")
                    sfxNoMatch.play();
            }
        }

        Text {
            anchors.centerIn: list
            visible: library.count === 0
            text: win.query === "" ? "NO GAMES FOUND" : "NO MATCH FOR \"" + win.query + "\""
            color: theme.textDim
            font.family: theme.font
            font.pixelSize: 24
            font.letterSpacing: 3
        }

        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            y: parent.height * 0.75
            width: parent.width - theme.margin * 2
            spacing: 10
            visible: library.count > 0

            Text {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                text: list.currentTitle
                color: theme.textMain
                font.pixelSize: 36
                font.bold: true
            }
            Text {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: String(list.currentIndex + 1).padStart(2, "0") + " / " + String(library.count).padStart(2, "0")
                color: theme.primary
                font.family: theme.font
                font.pixelSize: 16
                font.letterSpacing: 3
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

    onActiveChanged: if (!active)
        emu.releaseAll()
}
