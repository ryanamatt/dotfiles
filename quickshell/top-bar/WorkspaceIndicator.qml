// WorkspaceIndicator.qml

import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts

RowLayout {
    id: root

    // Pass in the screen this bar lives on (Bar.qml's modelData)
    required property var screen

    spacing: 6

    // The Hyprland monitor object matching this screen
    property var monitor: Hyprland.monitorFor(root.screen)

    // id of the currently active workspace on this monitor (-1 if none)
    property int activeId: (root.monitor && root.monitor.activeWorkspace)
        ? root.monitor.activeWorkspace.id
        : -1

    // First workspace number belonging to this monitor.
    // DP-3 -> 1-5, DP-2 -> 6-10. Add more cases if you add monitors.
    property int startWorkspace: {
        switch (root.screen.name) {
            case "DP-3": return 1
            case "DP-2": return 6
            default: return 1
        }
    }

    Repeater {
        model: 5

        delegate: Item {
            id: slot
            required property int index
            property int wsNumber: root.startWorkspace + index
            property bool active: wsNumber === root.activeId

            // Fixed-size slot so the RowLayout never repositions siblings,
            // regardless of how big the dot inside currently is.
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: 24
            Layout.preferredHeight: 8

            Rectangle {
                id: dot
                anchors.centerIn: parent

                // Circle when inactive, oval/pill when active
                width: slot.active ? 24 : 16
                height: 8
                radius: height / 2

                transformOrigin: Item.Center

                color: slot.active ? Colors.colors.accent : Colors.colors.foregroundMuted

                // Morph between circle <-> oval with a slight overshoot ("bounce")
                Behavior on width {
                    NumberAnimation {
                        duration: 350
                        easing.type: Easing.OutBack
                        easing.overshoot: 3
                    }
                }

                Behavior on color {
                    ColorAnimation { duration: 150 }
                }

                // Extra pop of scale when a workspace becomes active
                SequentialAnimation {
                    id: bounceAnim
                    NumberAnimation {
                        target: dot
                        property: "scale"
                        to: 1.35
                        duration: 120
                        easing.type: Easing.OutQuad
                    }
                    NumberAnimation {
                        target: dot
                        property: "scale"
                        to: 1.0
                        duration: 220
                        easing.type: Easing.OutBack
                        easing.overshoot: 5
                    }
                }
            }

            onActiveChanged: {
                if (active) bounceAnim.restart()
            }
        }
    }
}