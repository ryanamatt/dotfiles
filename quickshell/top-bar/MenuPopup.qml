// MenuPopup.qml

import Quickshell
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

PopupWindow {
    id: root

    // Dependency from Bar.qml
    required property var hoverArea

    implicitHeight: 325
    implicitWidth: 400
    color: "transparent"
    visible: false

    Timer {
        id: hideTimer
        interval: 200
        onTriggered: root.hide()
    }

    onVisibleChanged: {
        if (visible) hideTimer.stop()
    }

    // Helper to handle visibility logic
    function checkVisibility() {
        if (root.hoverArea.containsMouse || menuHoverHandler.hovered) {
            hideTimer.stop()
            root.show()
        } else {
            hideTimer.start()
        }
    }

    function show() {
        root.visible = true
        shrinkAnim.stop()
        growAnim.start()
    }

    function hide() {
        growAnim.stop()
        shrinkAnim.start()
    }

    Connections {
        target: root.hoverArea
        function onContainsMouseChanged() { root.checkVisibility() }
    }

    HoverHandler {
        id: menuHoverHandler
        onHoveredChanged: root.checkVisibility()
    }

    Rectangle {
        id: menuContent
        anchors.fill: parent
        color: Colors.colors.surface
        border.color: Colors.colors.backgroundAlt
        border.width: 4
        radius: 20

        // Starting State: shrunk, tilted, slid up and invisible
        opacity: 0

        transform: [
            Scale {
                id: popupScale
                origin.x: menuContent.width / 2
                origin.y: 0
                xScale: 0.85
                yScale: 0.7
            },
            Rotation {
                id: popupRotate
                origin.x: menuContent.width / 2
                origin.y: 0
                angle: -6
            },
            Translate {
                id: popupTranslate
                y: -24
            }
        ]

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 10

            TabBar {
                id: tabBar
                Layout.fillWidth: true

                onVisibleChanged: {
                    if (visible) {
                        currentIndex = 0
                    }
                }

                background: Rectangle {
                    color: "transparent"
                }

                // Basic Settings Tab
                TabButton { 
                    text: "\ue690"

                    background: Rectangle {
                        color: parent.checked ? Colors.colors.foregroundMuted : Colors.colors.foreground
                        radius: 10
                        height: 25
                    }

                    contentItem: Text {
                        text: parent.text
                        color: parent.checked ? Colors.colors.surfaceAlt : Colors.colors.surface
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font.pixelSize: 16
                    }

                    HoverHandler {
                        onHoveredChanged: if (hovered) tabBar.currentIndex = 0
                    }
                }

                TabButton { 
                    text: "\udb85\udea0" 

                    background: Rectangle {
                        color: parent.checked ? Colors.colors.foregroundMuted : Colors.colors.foreground
                        radius: 10
                    }

                    contentItem: Text {
                        text: parent.text
                        color: parent.checked ? Colors.colors.surfaceAlt : Colors.colors.surface
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font.pixelSize: 16
                    }

                    HoverHandler {
                        onHoveredChanged: if (hovered) tabBar.currentIndex = 1
                    }
                }

                TabButton {
                    text: "\uf0bd"

                    background: Rectangle {
                        color: parent.checked ? Colors.colors.foregroundMuted : Colors.colors.foreground
                        radius: 10
                    }

                    contentItem: Text {
                        text: parent.text
                        color: parent.checked ? Colors.colors.surfaceAlt : Colors.colors.surface
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font.pixelSize: 16
                    }

                    HoverHandler {
                        onHoveredChanged: if (hovered) tabBar.currentIndex = 2
                    }
                }
            }

            StackLayout {
                id: tabStack
                Layout.fillWidth: true
                Layout.fillHeight: true
                currentIndex: 0

                opacity: 1

                transform: Translate {
                    id: tabStackTranslate
                    y: 0
                }

                SettingsTab {}
                StatisticsTab {}
                AppsTab {}
                // Rectangle { color: "transparent"; Text { text: "Content of Tab 3"; anchors.centerIn: parent } }
            }
        }

        // Watches for tab changes and kicks off the switch animation
        Connections {
            target: tabBar
            function onCurrentIndexChanged() { tabSwitchAnim.restart() }
        }

        SequentialAnimation {
            id: tabSwitchAnim

            ParallelAnimation {
                NumberAnimation {
                    target: tabStack
                    property: "opacity"
                    to: 0
                    duration: 110
                    easing.type: Easing.InCubic
                }
                NumberAnimation {
                    target: tabStackTranslate
                    property: "y"
                    to: 8
                    duration: 110
                    easing.type: Easing.InCubic
                }
            }

            ScriptAction {
                script: {
                    tabStack.currentIndex = tabBar.currentIndex
                    tabStackTranslate.y = -8
                }
            }

            ParallelAnimation {
                NumberAnimation {
                    target: tabStack
                    property: "opacity"
                    to: 1
                    duration: 180
                    easing.type: Easing.OutCubic
                }
                NumberAnimation {
                    target: tabStackTranslate
                    property: "y"
                    to: 0
                    duration: 180
                    easing.type: Easing.OutCubic
                }
            }
        }

        // Growing and Shrinking Popup Animations
        ParallelAnimation {
            id: growAnim

            NumberAnimation {
                target: menuContent
                property: "opacity"
                to: 0.95
                duration: 260
                easing.type: Easing.OutCubic
            }

            // Slide down from the bar with a springy overshoot
            NumberAnimation {
                target: popupTranslate
                property: "y"
                to: 0
                duration: 480
                easing.type: Easing.OutBack
                easing.overshoot: 1.6
            }

            // Tilt settles back to level, slightly overshooting past 0
            NumberAnimation {
                target: popupRotate
                property: "angle"
                to: 0
                duration: 500
                easing.type: Easing.OutBack
                easing.overshoot: 2.5
            }

            // Unfurl: vertical scale leads, overshoots, then settles
            SequentialAnimation {
                NumberAnimation {
                    target: popupScale
                    property: "yScale"
                    to: 1.06
                    duration: 230
                    easing.type: Easing.OutCubic
                }
                NumberAnimation {
                    target: popupScale
                    property: "yScale"
                    to: 1
                    duration: 200
                    easing.type: Easing.OutBack
                    easing.overshoot: 1.5
                }
            }

            // Horizontal scale follows a beat behind for a cascading pop
            SequentialAnimation {
                PauseAnimation { duration: 70 }
                NumberAnimation {
                    target: popupScale
                    property: "xScale"
                    to: 1.03
                    duration: 220
                    easing.type: Easing.OutCubic
                }
                NumberAnimation {
                    target: popupScale
                    property: "xScale"
                    to: 1
                    duration: 190
                    easing.type: Easing.OutBack
                    easing.overshoot: 1.5
                }
            }
        }

        ParallelAnimation {
            id: shrinkAnim
            NumberAnimation {
                target: menuContent
                property: "opacity"
                to: 0
                duration: 150
                easing.type: Easing.InCubic
            }
            NumberAnimation {
                target: popupTranslate
                property: "y"
                to: -24
                duration: 200
                easing.type: Easing.InBack
                easing.overshoot: 1.2
            }
            NumberAnimation {
                target: popupRotate
                property: "angle"
                to: -6
                duration: 200
                easing.type: Easing.InCubic
            }
            NumberAnimation {
                target: popupScale
                property: "xScale"
                to: 0.85
                duration: 180
                easing.type: Easing.InCubic
            }
            NumberAnimation {
                target: popupScale
                property: "yScale"
                to: 0.7
                duration: 180
                easing.type: Easing.InCubic
            }
            onFinished: root.visible = false
        }
    }
}