// Bar.qml

import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

Scope {
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: bar
            required property var modelData
            screen: modelData

            exclusionMode: ExclusionMode.Ignore
            
            color: "transparent"

            anchors { top: true }
            implicitWidth: 200
            implicitHeight: 40

            Rectangle {
                anchors.fill: parent
                color: Colors.colors.background
                border.color: Colors.colors.border
                opacity: 0.9
                border.width: 1
                radius: bar.height / 2    // Half of implicitHeight to get half-circles on each edge
            }

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 2

                ClockWidget { Layout.alignment: Qt.AlignHCenter }

                WorkspaceIndicator {
                    Layout.alignment: Qt.AlignHCenter
                    screen: bar.modelData
                }

            }

            MouseArea {
                id: hoverArea
                anchors.fill: parent
                hoverEnabled: true
            }

            MenuPopup {
                id: menuPopup
                hoverArea: hoverArea
                anchor.window: bar
                anchor.rect.x: 0 - ( bar.width / 2 )
                anchor.rect.y: bar.height
            }
        }
    }
}