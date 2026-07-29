// shell.qml

import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "WorkspaceUtils.js" as WorkspaceUtils

ShellRoot {
    id: root

    readonly property string home: Quickshell.env("HOME")
    readonly property string dotfiles: home + "/dotfiles"

    property string currentTheme: ""

    property string lastError: ""

    // Each entry: { id, name, apps: [{ wmClass, title }] }
    property var workspaceModel: []

    // Holds the result of the "hyprctl -j workspaces" step until the
    // "hyprctl -j clients" step finishes and can merge the two.
    property var _parsedWorkspaces: []

    property int focusedIndex: -1

    property var selectedWorkspace: null

    // Fall back if colors don't load
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

    function colorFor(action) {
        return root.colors[action.colorKey] || root.colors.accent
    }

    function loadColorsFor(themeName) {
        colorsProc.themeArg = themeName
        colorsProc.running = true
    }

    // Resolves a window's WM_CLASS to something usable as an
    // IconImage.source, in order of confidence:
    //   1. exact / case-insensitive desktop-entry id match
    //   2. the manual override table (see WorkspaceUtils.classIconOverrides)
    //   3. a fuzzy scan through every known desktop entry
    //   4. a bare guess that the icon theme has a file named after the class
    function iconForClass(wmClass) {
        if (!wmClass || wmClass.length === 0) {
            return Quickshell.iconPath("application-x-executable", true)
        }

        const needle = wmClass.toLowerCase()
        let entry = DesktopEntries.byId(wmClass) || DesktopEntries.byId(needle)

        if (!entry) {
            const overrideId = WorkspaceUtils.classIconOverrides[needle]
            if (overrideId) entry = DesktopEntries.byId(overrideId)
        }

        if (!entry) {
            const apps = DesktopEntries.applications.values
            for (let i = 0; i < apps.length; i++) {
                const app = apps[i]
                const id = (app.id || "").toLowerCase()
                const name = (app.name || "").toLowerCase()
                if (id === needle || id.endsWith("." + needle) || name === needle) {
                    entry = app
                    break
                }
            }
        }

        if (entry && entry.icon) {
            return Quickshell.iconPath(entry.icon, "application-x-executable")
        }

        return Quickshell.iconPath(needle, "application-x-executable")
    }

    function moveFocus(delta) {
        const n = root.workspaceModel.length
        root.focusedIndex = ((root.focusedIndex + delta) % n + n) % n
    }

    Component.onCompleted: {
        currentThemeProc.running = true
        getWorkspaces.running = true
    }

    // Read themes/.current_theme so this menu
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

    // Read a theme's colors.json
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
                    console.log("switch-workspaces: no valid colors.json for " + colorsProc.themeArg)
                }
            }
        }
    }

    // get the list of active workspaces.
    Process {
        id: getWorkspaces
        command: ["bash", "-c", "hyprctl -j workspaces"]
        stdout: StdioCollector {
            onStreamFinished: {
                root._parsedWorkspaces = WorkspaceUtils.parseWorkspaces(this.text)
                getClients.running = true
            }
        }
    }

    // get every window so we know what's actually on each workspace.
    Process {
        id: getClients
        command: ["bash", "-c", "hyprctl -j clients"]
        stdout: StdioCollector {
            onStreamFinished: {
                const grouped = WorkspaceUtils.groupClientsByWorkspace(this.text)
                root.workspaceModel = WorkspaceUtils.buildWorkspaceModel(root._parsedWorkspaces, grouped)
                getActiveWorkspace.running = true
            }
        }
    }

    // figure out which workspace was focused before we opened,
    // so the rolodex starts centered on it.
    Process {
        id: getActiveWorkspace
        command: ["bash", "-c", "hyprctl -j activeworkspace"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const active = JSON.parse(this.text)
                    const idx = WorkspaceUtils.indexOfWorkspaceId(root.workspaceModel, active.id)
                    if (idx !== -1) rolodexView.currentIndex = idx
                } catch (e) {
                    console.log("workspace switcher: couldn't read active workspace")
                }
            }
        }
    }

    Process {
        id: switchWorkspace
        command: ["bash", "-c", "hyprctl dispatch 'hl.dsp.focus({ workspace = \"" + root.selectedWorkspace + "\" })'"]
        onExited: {
            Qt.quit()
        }
    }

    PanelWindow {
        id: mainWindow

        anchors { top: true; bottom: true; left: true; right: true; }
        color: "transparent"

        focusable: true

        FocusScope {
            id: scope
            anchors.fill: parent
            focus: true

            // ----- Key Presses -----

            Keys.onEscapePressed: Qt.quit()

            Keys.onUpPressed: { root.moveFocus(-1); rolodexView.currentIndex = root.focusedIndex }
            Keys.onDownPressed: { root.moveFocus(1); rolodexView.currentIndex = root.focusedIndex }

            Keys.onLeftPressed: { root.moveFocus(-1); rolodexView.currentIndex = root.focusedIndex }
            Keys.onRightPressed: { root.moveFocus(1); rolodexView.currentIndex = root.focusedIndex }

            Keys.onReturnPressed: {
                if (root.focusedIndex >= 0 && root.focusedIndex < root.workspaceModel.length) {
                    const modelData = root.workspaceModel[root.focusedIndex]
                    if (modelData.name && isNaN(Number(modelData.name))) {
                        root.selectedWorkspace = "name:" + modelData.name
                    } else {
                        root.selectedWorkspace = modelData.id
                    }
                    switchWorkspace.running = true
                }
            }
            Keys.onEnterPressed: { scope.Keys.onReturnPressed(event) }
                

            // End Keys

            // Dim Surroundings
            Rectangle {
                anchors.fill: parent
                color: Qt.rgba(0, 0, 0, 0.2) // Semi-transparent dark overlay

                Component.onCompleted: {
                    opacity = 1.0
                }

                Behavior on opacity {
                    NumberAnimation { duration: 400; easing.type: Easing.OutQuad }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        Qt.quit()
                    }
                }
            }

            // Actual Window
            Rectangle {
                id: winRect
                anchors.centerIn: parent
                implicitWidth: 200
                implicitHeight: 300
                radius: 50

                // Finaly Product will have Color be transparent but is this now for testing and visibility
                // color: root.colors.surface
                // border.color: root.colors.backgroundAlt
                // border.width: 4
                color: "transparent"

                MouseArea {
                    anchors.fill: parent
                    onClicked: {}
                    onPressed: {}
                }

                Text {
                    visible: root.workspaceModel.length === 0
                    anchors.centerIn: parent
                    text: "No active workspaces"
                    color: root.colors.foregroundMuted
                    font.pixelSize: 20
                }


                PathView {
                    id: rolodexView
                    visible: root.workspaceModel.length > 0
                    anchors.fill: parent
                    anchors.margins: 10

                    model: root.workspaceModel
                    pathItemCount: (root.workspaceModel && root.workspaceModel.length < 5) ? root.workspaceModel.length : 5

                    highlightRangeMode: PathView.StrictlyEnforceRange
                    preferredHighlightBegin: 0.5
                    preferredHighlightEnd: 0.5

                    interactive: true

                    onCurrentIndexChanged: {
                        root.focusedIndex = currentIndex
                    }

                    path: Path {
                        startX: rolodexView.width / 2
                        startY: 0
                        PathAttribute { name: "itemScale"; value: 0.75 }
                        PathAttribute { name: "itemOpacity"; value: 0.3 }

                        PathLine {
                            x: rolodexView.width / 2
                            y: rolodexView.height / 2
                        }
                        PathAttribute { name: "itemScale"; value: 1.0 }
                        PathAttribute { name: "itemOpacity"; value: 1.0 }

                        PathLine {
                            x: rolodexView.width / 2
                            y: rolodexView.height
                        }
                        PathAttribute { name: "itemScale"; value: 0.75 }
                        PathAttribute { name: "itemOpacity"; value: 0.3 }
                    }

                    delegate: Item {
                        id: delegateItem
                        width: winRect.width - 40
                        height: 50

                        property real itemProgress: PathView.percent !== undefined ? PathView.percent : 0.5

                        scale: PathView.itemScale !== undefined ? PathView.itemScale : 1.0
                        opacity: PathView.itemOpacity !== undefined ? PathView.itemOpacity : 1.0

                        transform: Rotation {
                            origin.x: delegateItem.width / 2
                            origin.y: delegateItem.height / 2
                            axis { x: 1; y: 0; z: 0 }
                            angle: (1-0 - (delegateItem.scale)) * 45 * (PathView.percent < 0.5 ? 1 : -1)
                        }

                        Rectangle {
                            anchors.fill: parent
                            radius: 12
                            clip: true
                            color: root.colors.backgroundAlt
                            border.color: rolodexView.currentIndex === index ? root.colors.accent : root.colors.borderSoft
                            border.width: 2

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 14
                                anchors.rightMargin: 14
                                spacing: 10

                                // Left spacer to push content toward the middle
                                Item { Layout.fillWidth: true }

                                Text {
                                    text: {
                                        if (modelData.name === "desktop") return "~:"
                                        if (modelData.name === "discord") return "D:"
                                        if (modelData.name === "spotify") return "S:"
                                        return modelData.id + ":"
                                    }
                                    color: root.colors.info
                                    font.pixelSize: 16
                                    font.bold: true
                                }

                                Row {
                                    spacing: 6

                                    Repeater {
                                        model: modelData.apps

                                        IconImage {
                                            implicitSize: 28
                                            asynchronous: true
                                            source: root.iconForClass(modelData.wmClass)
                                        }
                                    }
                                }

                                Text {
                                    visible: modelData.apps.length === 0
                                    text: "(empty)"
                                    color: root.colors.foregroundMuted
                                    font.pixelSize: 14
                                    font.italic: true
                                }

                                // Right spacer to push content toward the middle
                                Item { Layout.fillWidth: true }
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    rolodexView.currentIndex = index
                                    if (modelData.name && isNaN(Number(modelData.name))) {
                                        root.selectedWorkspace = "name:" + modelData.name
                                    } else {
                                        root.selectedWorkspace = modelData.id
                                    }
                                    switchWorkspace.running = true
                                }
                            }

                            Behavior on scale {
                                NumberAnimation { duration: 200; easing.type: Easing.OutBack }
                            }

                            Behavior on opacity {
                                NumberAnimation { duration: 150 }
                            }


                        }

                    }


                }

            }


        }
    }
}
