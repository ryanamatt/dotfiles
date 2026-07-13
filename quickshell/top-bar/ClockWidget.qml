// ClockWidget.qml

import QtQuick

Text {
    text: Time.time
    color: Colors.colors.foreground
    font.pixelSize: 14
    font.family: "Noto Sans Mono"
}