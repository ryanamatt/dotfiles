// shell.qml
//
// A Quickshell power menu: Lock, Sleep, Log Out, Restart, Shut Down.

import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

ShellRoot {
    id: root

    readonly property string home: Quickshell.env("HOME")
    readonly property string dotfiles: home + "/dotfiles"

    property string currentTheme: ""
    property string lastError: ""

    property int focusedIndex: 0
    property bool confirming: false
    property bool confirmYes: false

    // Fallback palette, used until the active theme's colors.json loads
    // (or if it's missing). Matches the shape every theme's
    // theme_colors.json should have -- same file the theme-switcher reads,
    // just with a few extra semantic roles added on top.
    property var colors: ({
        background: "#0d0010",
        backgroundAlt: "#1a0028",
        surface: "#2a0e3a",
        surfaceAlt: "#3b1f4a",
        foreground: "#e8c5e9",
        foregroundMuted: "#a08bb0",
        accent: "#b00ea2",
        accentAlt: "#d966f5",
        border: "#2a0e3a",
        borderActive: "#b00ea2",
        borderSoft: "#443a52",
        borderStrong: "#5a4d6b",
        hover: "#3b1f4a",
        success: "#5ecfa0",
        warning: "#f5c842",
        error: "#e05c7a",
        info: "#9de8e8",
        shadow: "#40b00ea2"
    })

    // Ordered left-to-right: safest actions first, most destructive last.
    // colorKey looks itself up in root.colors so each action reads using
    // a color that matches its severity, per-theme.
    property var actions: [
        {
            id: "lock",
            label: "Lock",
            glyph: "\uf023",
            colorKey: "accent",
            question: "Lock the screen?",
            command: ["hyprlock"]
        },
        {
            id: "sleep",
            label: "Sleep",
            glyph: "\uf186",
            colorKey: "info",
            question: "Suspend to sleep?",
            command: ["systemctl", "suspend"]
        },
        {
            id: "logout",
            label: "Log Out",
            glyph: "\uf2f5",
            colorKey: "accentAlt",
            question: "End the current session?",
            command: ["hyprctl", "dispatch", "exit"]
        },
        {
            id: "restart",
            label: "Restart",
            glyph: "\uf2f1",
            colorKey: "warning",
            question: "Restart the system?",
            command: ["systemctl", "reboot"]
        },
        {
            id: "shutdown",
            label: "Shut Down",
            glyph: "\uf011",
            colorKey: "error",
            question: "Shut down the system?",
            command: ["systemctl", "poweroff"]
        }
    ]

    function colorFor(action) {
        return root.colors[action.colorKey] || root.colors.accent
    }

    function loadColorsFor(themeName) {
        colorsProc.themeArg = themeName
        colorsProc.running = true
    }

    function moveFocus(delta) {
        const n = root.actions.length
        root.focusedIndex = ((root.focusedIndex + delta) % n + n) % n
    }

    function beginConfirm() {
        root.confirming = true
        root.confirmYes = false
    }

    function cancelConfirm() {
        root.confirming = false
    }

    function runFocused() {
        root.lastError = ""
        actionProc.cmd = root.actions[root.focusedIndex].command
        actionProc.running = true
    }

    Component.onCompleted: currentThemeProc.running = true

    // ---------------------------------------------------------------
    // Background processes
    // ---------------------------------------------------------------

    // Read themes/.current_theme (written by switcher.sh) so this menu
    // always matches whatever theme is currently active.
    Process {
        id: currentThemeProc
        command: ["bash", "-c", "cat '" + root.dotfiles + "/themes/.current_theme' 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                const t = this.text.trim()
                root.currentTheme = t
                if (t.length > 0) root.loadColorsFor(t)
            }
        }
    }

    // Read a theme's colors.json -- same file the theme-switcher uses.
    Process {
        id: colorsProc
        property string themeArg: ""
        command: ["bash", "-c",
            "cat '" + root.dotfiles + "/themes/" + themeArg + "/quickshell/colors.json' 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const parsed = JSON.parse(this.text)
                    root.colors = Object.assign({}, root.colors, parsed)
                } catch (e) {
                    console.log("powermenu: no valid colors.json for " + colorsProc.themeArg)
                }
            }
        }
    }

    // Runs whichever action was confirmed.
    Process {
        id: actionProc
        property var cmd: []
        command: cmd
        stderr: StdioCollector {
            onStreamFinished: {
                if (this.text.trim().length > 0) root.lastError = this.text.trim()
            }
        }
        onExited: (exitCode) => {
            if (exitCode === 0) {
                Qt.quit()
            } else {
                console.log("powermenu: command failed (exit " + exitCode + "): " + root.lastError)
            }
        }
    }

    // ---------------------------------------------------------------
    // Window
    // ---------------------------------------------------------------

    PanelWindow {
        id: win
        anchors { top: true; bottom: true; left: true; right: true }
        color: "transparent"
        focusable: true

        FocusScope {
            id: scope
            anchors.fill: parent
            focus: true

            Keys.onEscapePressed: {
                if (root.confirming) root.cancelConfirm()
                else Qt.quit()
            }
            Keys.onLeftPressed: {
                if (root.confirming) root.confirmYes = !root.confirmYes
                else root.moveFocus(-1)
            }
            Keys.onRightPressed: {
                if (root.confirming) root.confirmYes = !root.confirmYes
                else root.moveFocus(1)
            }
            Keys.onUpPressed: { if (!root.confirming) root.moveFocus(-1) }
            Keys.onDownPressed: { if (!root.confirming) root.moveFocus(1) }
            Keys.onReturnPressed: {
                if (root.confirming) {
                    if (root.confirmYes) root.runFocused()
                    else root.cancelConfirm()
                } else {
                    root.beginConfirm()
                }
            }
            Keys.onEnterPressed: {
                if (root.confirming) {
                    if (root.confirmYes) root.runFocused()
                    else root.cancelConfirm()
                } else {
                    root.beginConfirm()
                }
            }

            // Dim scrim behind the card. Click it to dismiss (only when
            // not mid-confirm, so a stray click can't nuke the prompt).
            Rectangle {
                anchors.fill: parent
                color: "#aa000000"

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        if (root.confirming) root.cancelConfirm()
                        else Qt.quit()
                    }
                }
            }

            Rectangle {
                id: card
                anchors.centerIn: parent
                width: Math.min(620, parent.width - 80)
                height: root.confirming ? 220 : 220
                radius: 18
                color: root.colors.surface
                border.color: root.colors.backgroundAlt
                border.width: 4

                Behavior on width { NumberAnimation { duration: 120 } }

                // Swallow clicks so the scrim's MouseArea doesn't see them
                MouseArea {
                    anchors.fill: parent
                    onClicked: (mouse) => mouse.accepted = true
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 24
                    spacing: 16

                    Text {
                        text: "Power Menu"
                        color: root.colors.foreground
                        font.pixelSize: 18
                        font.bold: true
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                    }

                    Text {
                        visible: root.lastError.length > 0
                        text: root.lastError
                        color: root.colors.error
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }

                    // ---- Chooser: row of five action tiles ----
                    RowLayout {
                        visible: !root.confirming
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 16

                        Repeater {
                            model: root.actions

                            delegate: Rectangle {
                                id: tile
                                required property var modelData
                                required property int index
                                property bool focused: index === root.focusedIndex

                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                radius: 14
                                color: focused ? root.colors.hover : root.colors.backgroundAlt
                                border.width: focused ? 3 : 1
                                border.color: focused ? root.colorFor(tile.modelData) : root.colors.borderSoft

                                ColumnLayout {
                                    anchors.centerIn: parent
                                    spacing: 8

                                    Text {
                                        text: tile.modelData.glyph
                                        font.family: "Iosevka Nerd Font Propo"
                                        font.pixelSize: 32
                                        color: root.colorFor(tile.modelData)
                                        Layout.alignment: Qt.AlignHCenter
                                    }

                                    Text {
                                        text: tile.modelData.label
                                        color: root.colors.foreground
                                        font.pixelSize: 13
                                        font.bold: tile.focused
                                        Layout.alignment: Qt.AlignHCenter
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onEntered: root.focusedIndex = tile.index
                                    onClicked: {
                                        root.focusedIndex = tile.index
                                        root.beginConfirm()
                                    }
                                }
                            }
                        }
                    }

                    // ---- Confirm: question + No/Yes ----
                    ColumnLayout {
                        visible: root.confirming
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 18
                        Layout.alignment: Qt.AlignHCenter

                        RowLayout {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignHCenter
                            spacing: 12

                            Text {
                                text: root.actions[root.focusedIndex].glyph
                                font.family: "Iosevka Nerd Font Propo"
                                font.pixelSize: 28
                                color: root.colorFor(root.actions[root.focusedIndex])
                            }

                            Text {
                                text: root.actions[root.focusedIndex].question
                                color: root.colors.foreground
                                font.pixelSize: 17
                            }
                        }

                        RowLayout {
                            Layout.alignment: Qt.AlignHCenter
                            spacing: 16

                            Rectangle {
                                id: noBtn
                                width: 110
                                height: 44
                                radius: 10
                                color: !root.confirmYes ? root.colors.hover : root.colors.backgroundAlt
                                border.width: !root.confirmYes ? 3 : 1
                                border.color: !root.confirmYes ? root.colors.foregroundMuted : root.colors.borderSoft

                                Text {
                                    anchors.centerIn: parent
                                    text: "No"
                                    color: root.colors.foreground
                                    font.bold: !root.confirmYes
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onEntered: root.confirmYes = false
                                    onClicked: root.cancelConfirm()
                                }
                            }

                            Rectangle {
                                id: yesBtn
                                width: 110
                                height: 44
                                radius: 10
                                property color tint: root.colorFor(root.actions[root.focusedIndex])
                                color: root.confirmYes ? yesBtn.tint : root.colors.backgroundAlt
                                border.width: root.confirmYes ? 3 : 1
                                border.color: yesBtn.tint

                                Text {
                                    anchors.centerIn: parent
                                    text: "Yes"
                                    color: root.confirmYes ? root.colors.background : root.colors.foreground
                                    font.bold: root.confirmYes
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onEntered: root.confirmYes = true
                                    onClicked: {
                                        root.confirmYes = true
                                        root.runFocused()
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
