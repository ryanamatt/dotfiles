// AppsTab.qml

import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

Rectangle {
    id: root
    color: "transparent"
    Layout.fillWidth: true
    Layout.fillHeight: true
    clip: true

    // ----- App List -----

    property var appsModel: [
        {
            name: "Chrome",
            command: ["google-chrome-stable"],
            icon: "google-chrome",
            fallback: "\uf268" // chrome glyph
        },
        {
            name: "Discord",
            command: ["discord"],
            icon: "discord",
            fallback: "\uf392" // discord glyph
        },
        {
            name: "Spotify",
            command: ["spotify-launcher"],
            icon: "spotify-launcher",
            fallback: "\uf1bc" // spotify glyph
        },
        {
            name: "Obsidian",
            command: ["flatpak", "run", "md.obsidian.Obsidian"],
            icon: "md.obsidian.Obsidian",
            fallback: "\uf02d" // book glyph
        },
        {
            name: "VS Code",
            command: ["code"],
            icon: "vscode",
            fallback: "\ue70c" // vscode glyph
        },
        {
            name: "OBS Studio",
            command: ["flatpak", "run", "com.obsproject.Studio"],
            icon: "com.obsproject.Studio",
            fallback: "\uf03d" // video camera glyph
        },
        {
            name: "Steam",
            command: ["steam"],
            icon: "steam",
            fallback: "\uf1b6" // steam glyph
        },
        {
            name: "Dolphin",
            command: ["dolphin"],
            icon: "org.kde.dolphin",
            fallback: "\uf07c" // open folder glyph
        },
        {
            name: "Polychromatic",
            command: ["polychromatic-controller"],
            icon: "polychromatic",
            fallback: "\uf0eb" // lightbulb/RGB glyph
        }
    ]

    // Launches an app given its argv array
    function launch(cmd) {
        launchProc.command = cmd
        launchProc.running = false
        launchProc.running = true
    }

    Process {
        id: launchProc
    }

    property int tileWidth: 76
    property int tileSpacing: 14

    ScrollView {
        anchors.fill: parent
        clip: true
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        ScrollBar.vertical.policy: ScrollBar.AsNeeded

        Item {
            width: root.width
            height: appsFlow.height

            Flow {
                id: appsFlow
                anchors.horizontalCenter: parent.horizontalCenter

                property int columns: Math.max(1, Math.floor((root.width + root.tileSpacing) / (root.tileWidth + root.tileSpacing)))

                width: columns * root.tileWidth + (columns - 1) * root.tileSpacing
                spacing: root.tileSpacing

                Repeater {
                    model: root.appsModel

                    delegate: Rectangle {
                        id: tile
                        width: root.tileWidth
                        height: 84
                        radius: 12
                        color: tileMouse.containsMouse ? Colors.colors.hover : Colors.colors.surface
                        border.color: tileMouse.containsMouse ? Colors.colors.borderActive : Colors.colors.border
                        border.width: 1

                        Behavior on color {
                            ColorAnimation { duration: 120 }
                        }

                        scale: tileMouse.pressed ? 0.94 : (tileMouse.containsMouse ? 1.05 : 1.0)
                        Behavior on scale {
                            NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
                        }

                        MouseArea {
                            id: tileMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.launch(modelData.command)
                        }

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 6

                            Item {
                                Layout.preferredWidth: 32
                                Layout.preferredHeight: 32
                                Layout.alignment: Qt.AlignHCenter

                                Image {
                                    id: iconImage
                                    anchors.fill: parent
                                    source: "image://icon/" + modelData.icon
                                    sourceSize.width: 32
                                    sourceSize.height: 32
                                    fillMode: Image.PreserveAspectFit
                                    visible: status === Image.Ready
                                }

                                Text {
                                    anchors.centerIn: parent
                                    visible: iconImage.status !== Image.Ready
                                    text: modelData.fallback
                                    font.family: "Symbols Nerd Font"
                                    font.pixelSize: 22
                                    color: Colors.colors.foreground
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                text: modelData.name
                                color: Colors.colors.foreground
                                font.pixelSize: 11
                                horizontalAlignment: Text.AlignHCenter
                                elide: Text.ElideRight
                                wrapMode: Text.NoWrap
                            }
                        }
                    }
                }
            }
        }
    }
}
