import QtQuick
import Ryu.Shapes

Window {
    visible: true
    width: 960
    height: 640
    title: "jankk"
    color: "#101014"

    Column {
        anchors.centerIn: parent
        spacing: 24

        MaterialShape {
            id: logo
            width: 120
            height: 120
            anchors.horizontalCenter: parent.horizontalCenter
            shape: MaterialShape.Cookie9Sided
            color: "#6750A4"

            TapHandler {
                onTapped: logo.shape = logo.shape === MaterialShape.Cookie9Sided ? MaterialShape.Heart : MaterialShape.Cookie9Sided
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "jankk"
            color: "white"
            font.pixelSize: 48
        }
    }
}
