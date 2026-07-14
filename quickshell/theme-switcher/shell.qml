// shell.qml
//
// A Quickshell popup that wraps ~/dotfiles/switcher.sh.

import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

ShellRoot {
    id: root

    readonly property string home: Quickshell.env("HOME")
    readonly property string dotfiles: home + "/dotfiles"

    property string currentTheme: ""
    property var themeNames: []
    property var wallpaperMap: ({})
    property int focusedIndex: -1
    property string lastError: ""

    // How many cards fit per row, used for up/down arrow navigation
    property int columns: Math.max(1, Math.floor((flow.width + flow.spacing) / (200 + flow.spacing)))

    // Fallback palette, used until a theme's colors.json loads (or if it's
    // missing). Matches the shape every theme's colors.json should have.
    property var colors: ({
        background: "#1e1e2e",
        surface: "#313244",
        foreground: "#cdd6f4",
        accent: "#89b4fa",
        accentAlt: "#f38ba8",
        border: "#45475a"
    })

    function refreshAll() {
        listThemesProc.running = true
        currentThemeProc.running = true
        wallpaperMapProc.running = true
    }

    function loadColorsFor(themeName) {
        colorsProc.themeArg = themeName
        colorsProc.running = true
    }

    function switchTo(name) {
        root.lastError = ""
        switchProc.target = name
        switchProc.running = true
    }

    // Point keyboard focus at the active theme once known the list and
    // the current theme (order of arrival between the two isn't guaranteed).
    function syncFocusedIndex() {
        if (root.themeNames.length === 0) {
            root.focusedIndex = -1
            return
        }
        const idx = root.themeNames.indexOf(root.currentTheme)
        root.focusedIndex = idx >= 0 ? idx : 0
    }

    function moveFocus(delta) {
        if (root.themeNames.length === 0) return
        const base = root.focusedIndex < 0 ? 0 : root.focusedIndex
        const next = Math.max(0, Math.min(root.themeNames.length - 1, base + delta))
        root.focusedIndex = next
    }

    function activateFocused() {
        if (root.focusedIndex >= 0 && root.focusedIndex < root.themeNames.length) {
            root.switchTo(root.themeNames[root.focusedIndex])
        }
    }

    Component.onCompleted: refreshAll()

    // ---------------------------------------------------------------
    // Background processes — all the shelling-out lives here so the
    // UI below just reacts to plain QML properties.
    // ---------------------------------------------------------------

    // List theme directory names, e.g. ["Arcane", "Grotto", "Windward"]
    Process {
        id: listThemesProc
        command: ["bash", "-c",
            "find '" + root.dotfiles + "/themes' -mindepth 1 -maxdepth 1 -type d -printf '%f\\n' | sort"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.themeNames = this.text.split("\n").filter(s => s.length > 0)
                root.syncFocusedIndex()
            }
        }
    }

    // Read themes/.current_theme (written by switcher.sh)
    Process {
        id: currentThemeProc
        command: ["bash", "-c", "cat '" + root.dotfiles + "/themes/.current_theme' 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                const t = this.text.trim()
                root.currentTheme = t
                if (t.length > 0) root.loadColorsFor(t)
                root.syncFocusedIndex()
            }
        }
    }

    // Grab the first image file in each theme's wallpaper folder, e.g.
    // "Arcane:::/home/you/dotfiles/wallpapers/Arcane/Cabin.jpeg"
    Process {
        id: wallpaperMapProc
        command: ["bash", "-c",
            "for d in '" + root.dotfiles + "'/wallpapers/*/; do " +
            "t=$(basename \"$d\"); " +
            "f=$(find \"$d\" -maxdepth 1 -type f | head -n1); " +
            "echo \"$t:::$f\"; done"]
        stdout: StdioCollector {
            onStreamFinished: {
                const map = {}
                this.text.split("\n").forEach(line => {
                    if (!line.includes(":::")) return
                    const parts = line.split(":::")
                    if (parts[0] && parts[1]) map[parts[0]] = parts[1]
                })
                root.wallpaperMap = map
            }
        }
    }

    // Read a theme's colors.json (see create_theme.sh for the schema)
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
                    console.log("theme-switcher: no valid colors.json for " + colorsProc.themeArg)
                }
            }
        }
    }

    // Runs switcher.sh <theme>, then refreshes everything once it's done.
    //
    // workingDirectory matters here: switcher.sh internally calls
    // "./change_wallpaper.sh" using a relative path, so it must run with
    // dotfiles/ as its cwd. Without this, that call — and the whole
    // script, since it uses `set -e` — fails silently, which is why theme
    // switching wasn't doing anything.
    Process {
        id: switchProc
        property string target: ""
        command: ["bash", root.dotfiles + "/switcher.sh", target]
        workingDirectory: root.dotfiles
        stderr: StdioCollector {
            onStreamFinished: {
                if (this.text.trim().length > 0) root.lastError = this.text.trim()
            }
        }
        onExited: (exitCode) => {
            root.refreshAll()
            if (exitCode === 0) {
                Qt.quit()
            } else {
                console.log("theme-switcher: switcher.sh failed (exit " + exitCode + "): " + root.lastError)
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

            Keys.onEscapePressed: Qt.quit()
            Keys.onLeftPressed: root.moveFocus(-1)
            Keys.onRightPressed: root.moveFocus(1)
            Keys.onUpPressed: root.moveFocus(-root.columns)
            Keys.onDownPressed: root.moveFocus(root.columns)
            Keys.onReturnPressed: root.activateFocused()
            Keys.onEnterPressed: root.activateFocused()

            // Dim scrim behind the card. Click it to dismiss.
            Rectangle {
                anchors.fill: parent
                color: "#aa000000"

                MouseArea {
                    anchors.fill: parent
                    onClicked: Qt.quit()
                }
            }

            Rectangle {
                id: card
                anchors.centerIn: parent
                width: Math.min(760, parent.width - 80)
                height: Math.min(520, parent.height - 80)
                radius: 14
                color: root.colors.background
                border.color: root.colors.border
                border.width: 2

                // Swallow clicks so the scrim's MouseArea doesn't see them
                MouseArea {
                    anchors.fill: parent
                    onClicked: (mouse) => mouse.accepted = true
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 16

                    RowLayout {
                        Layout.fillWidth: true

                        Text {
                            text: "Choose a theme"
                            color: root.colors.foreground
                            font.pixelSize: 20
                            font.bold: true
                            Layout.fillWidth: true
                        }

                        Rectangle {
                            width: 28
                            height: 28
                            radius: 14
                            color: root.colors.surface

                            Text {
                                anchors.centerIn: parent
                                text: "\u2715"
                                color: root.colors.foreground
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Qt.quit()
                            }
                        }
                    }

                    Text {
                        visible: root.lastError.length > 0
                        text: root.lastError
                        color: "#f38ba8"
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }

                    Flickable {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        contentWidth: width
                        contentHeight: flow.height
                        clip: true

                        Flow {
                            id: flow
                            width: parent.width
                            spacing: 14

                            Repeater {
                                model: root.themeNames

                                delegate: Rectangle {
                                    id: themeCard
                                    required property string modelData
                                    required property int index
                                    property bool active: modelData === root.currentTheme
                                    property bool focused: index === root.focusedIndex

                                    width: 200
                                    height: 160
                                    radius: 10
                                    color: root.colors.surface
                                    border.width: (active || focused) ? 3 : 1
                                    border.color: focused
                                        ? root.colors.accentAlt
                                        : (active ? root.colors.accent : root.colors.border)

                                    ColumnLayout {
                                        anchors.fill: parent
                                        anchors.margins: 8
                                        spacing: 6

                                        Rectangle {
                                            Layout.fillWidth: true
                                            Layout.fillHeight: true
                                            radius: 6
                                            color: root.colors.background
                                            clip: true

                                            Image {
                                                anchors.fill: parent
                                                fillMode: Image.PreserveAspectCrop
                                                asynchronous: true
                                                source: root.wallpaperMap[themeCard.modelData]
                                                    ? "file://" + root.wallpaperMap[themeCard.modelData]
                                                    : ""
                                            }
                                        }

                                        RowLayout {
                                            Layout.fillWidth: true

                                            Text {
                                                text: themeCard.modelData
                                                color: root.colors.foreground
                                                font.bold: themeCard.active
                                                Layout.fillWidth: true
                                                elide: Text.ElideRight
                                            }

                                            Text {
                                                visible: themeCard.active
                                                text: "\u25cf"
                                                color: root.colors.accent
                                            }
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            root.focusedIndex = themeCard.index
                                            root.switchTo(themeCard.modelData)
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
}
