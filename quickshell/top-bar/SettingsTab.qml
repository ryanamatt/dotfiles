// SettingsTab.qml

import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

Rectangle {
    id: root
    color: "transparent"
    Layout.fillWidth: true
    Layout.fillHeight: true


    // ----- Network/Wifi Section -----

    property string netType: "" // "ethernet" | "wifi" | ""
    property string netState: "disconnected" // "connected | "disconnected"
    property string netName: "" // "SSID or connection name"

    function refreshNetwork() {
        netProc.running = true
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refreshNetwork()
    }

    Process {
        id: netProc
        command: ["nmcli", "-t", "-f", "TYPE,STATE,CONNECTION", "dev"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n")
                let ethernet = null
                let wifi = null

                for (const line of lines) {
                    const parts = line.split(":")
                    if (parts.length < 3) continue
                    const type = parts[0]
                    const state = parts[1]
                    const connection = parts.slice(2).join(":")
                    if (type === "ethernet" && state === "connected") ethernet = connection
                    if (type === "wifi" && state === "connected") wifi = connection
                }

                if (ethernet) {
                    root.netType = "ethernet"
                    root.netState = "connected"
                    root.netName = ethernet
                } else if (wifi) {
                    root.netType = "wifi"
                    root.netState = "connected"
                    root.netName = wifi
                } else {
                    root.netType = ""
                    root.netState = "disconnected"
                    root.netName = ""
                }
            }
        }
    }

    Process {
        id: networkManagerProc
        command: ["nm-connection-editor"]
    }

    ColumnLayout {
        id: connectionLayout
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 12

        // --- Network Row ---
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            MouseArea {
                Layout.fillWidth: true
                Layout.fillHeight: true
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: networkManagerProc.running = true

                RowLayout {
                    anchors.fill: parent
                    spacing: 10

                    Rectangle {
                        Layout.preferredWidth: 36
                        Layout.preferredHeight: 36
                        color: "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: root.netType === "ethernet" ? "\udb80\ude01"
                                : root.netType === "wifi" ? "\uf1eb"
                                : "\uf05e"
                            font.family: "Symbols Nerd Font"
                            font.pixelSize: 30
                            color: Colors.colors.foreground
                        }
                    }

                    ColumnLayout {
                        spacing: 2
                        Layout.fillWidth: true

                        Text {
                            text: root.netState === "connected"
                                ? (root.netType === "ethernet" ? "Ethernet" : "Wi-Fi")
                                : "Not Connected"
                            color: Colors.colors.foreground
                            font.bold: true
                            font.pixelSize: 14
                        }

                        Text {
                            text: root.netState === "connected" ? root.netName : "No active connection"
                            color: Colors.colors.foregroundMuted
                            font.pixelSize: 12
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }
                }
            }

            MouseArea {
                Layout.preferredWidth: 28
                Layout.preferredHeight: 28
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.refreshNetwork()

                Text {
                    id: refreshIcon
                    anchors.centerIn: parent
                    text: "\uf021" // refresh icon
                    font.family: "Symbols Nerd Font"
                    font.pixelSize: 14
                    color: Colors.colors.foregroundMuted

                    RotationAnimation on rotation {
                        running: netProc.running
                        loops: Animation.Infinite
                        from: 0
                        to: 2160
                        duration: 800
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Colors.colors.border
        }
    }

    // ----- Bluetooth Section -----

    property bool bluetoothPowered: false
    ListModel { id: bluetoothDevicesModel }

    function refreshBluetooth() {
        bluetoothPowerProc.running = true
        bluetoothDevicesProc.running = true
    }

    function disconnectDevice(mac) {
        disconnectProc.command = ["bluetoothctl", "disconnect", mac]
        disconnectProc.running = true
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refreshBluetooth()
    }

    Process {
        id: bluetoothPowerProc
        command: ["bluetoothctl", "show"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.bluetoothPowered = text.includes("Powered: yes")
            }
        }
    }

    Process {
        id: bluetoothDevicesProc
        command: ["bluetoothctl", "devices", "Connected"]
        stdout: StdioCollector {
            onStreamFinished: {
                bluetoothDevicesModel.clear()
                const lines = text.trim().split("\n")
                for (const line of lines) {
                    if (!line.startsWith("Device")) continue
                    const parts = line.split(" ")
                    if (parts.length < 3) continue
                    const mac = parts[1]
                    const name = parts.slice(2).join(" ")
                    bluetoothDevicesModel.append({ mac: mac, name: name })
                }
            }
        }
    }

    Process {
        id: disconnectProc
        onExited: root.refreshBluetooth()
    }

    Process {
        id: bluetoothSettingsProc
        command: ["blueman-manager"]
    }

    ColumnLayout {
        id: bluetoothLayout
        anchors.top: connectionLayout.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: 5
        spacing: 12

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            MouseArea {
                Layout.fillWidth: true
                Layout.fillHeight: true
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: bluetoothSettingsProc.running = true

                RowLayout {
                    anchors.fill: parent
                    spacing: 10

                    Rectangle {
                        Layout.preferredWidth: 36
                        Layout.preferredHeight: 36
                        color: "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: root.isBluetoothConnected ? "\udb80\udcaf" : "\udb80\udcb2"
                            font.family: "Symbols Nerd Font"
                            font.pixelSize: 30
                            color: Colors.colors.foreground
                        }
                    }

                    ColumnLayout {
                        spacing: 2
                        Layout.fillWidth: true

                        Text {
                            text: !root.bluetoothPowered ? "Bluetooth Off"
                            : bluetoothDevicesModel.count > 0 ? "Connected"
                            : "Not Connected"
                            color: Colors.colors.foreground
                            font.bold: true
                            font.pixelSize: 14
                        }
                    }
                }
            }

            MouseArea {
                Layout.preferredWidth: 28
                Layout.preferredHeight: 28
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.refreshBluetooth()

                Text {
                    anchors.centerIn: parent
                    text: "\uf021"
                    font.family: "Symbols Nerd Font"
                    font.pixelSize: 14
                    color: Colors.colors.foregroundMuted

                    RotationAnimation on rotation {
                        running: bluetoothDevicesProc.running
                        loops: Animation.Infinite
                        from: 0
                        to: 2160
                        duration: 800
                    }
                }
            }
        }


        // Connected Devices List (one row per device)
        Repeater {
            model: bluetoothDevicesModel

            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 46
                spacing: 10

                Text {
                    text: "\udb80\udcb1" // generic device icon
                    font.family: "Symbols Nerd Font"
                    font.pixelSize: 16
                    color: Colors.colors.foregroundMuted
                }

                Text {
                    text: name
                    color: Colors.colors.foreground
                    font.pixelSize: 13
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                MouseArea {
                    Layout.preferredWidth: 22
                    Layout.preferredHeight: 22
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.disconnectDevice(mac)

                    Text {
                        anchors.centerIn: parent
                        text: "\uf00d" // disconnect icon
                        font.family: "Symbols Nerd Font"
                        font.pixelSize: 12
                        color: Colors.colors.foregroundMuted
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Colors.colors.border
        }
    }

    // ----- Volume Control -----

    property int volumeLevel: 0
    property bool isMuted: false

    Process {
        id: toggleVolumeMute
        command: ["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"]
    }

    Process {
        id: getVolume
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
        stdout: StdioCollector {
            onStreamFinished: {
                isMuted = text.includes("MUTED")
                const match = text.match(/Volume: ([\d.]+)/)
                if (match) {
                    volumeLevel = Math.round(parseFloat(match[1]) * 100)
                }
            }
        }
    }

    // Refresh volume state periodically
    Timer {
        interval: 200
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: getVolume.running = true
    }

    // Process to update volume
    Process {
        id: setVolumeProc
    }

    ColumnLayout {
        id: volumeLayout
        anchors.top: bluetoothLayout.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: 5
        spacing: 12

        RowLayout {
            id: audioSliderRow
            spacing: 10

            // Volume icon that acts as a mute toggle
            Text {
                text: isMuted ? "\ueee8" : "\ue638"
                font.family: "Symbols Nerd Font"
                font.pixelSize: 30
                color: Colors.colors.foreground
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        // Toggle mute via command and trigger refresh
                        let cmd = isMuted ? "0" : "1"
                        setVolumeProc.command = ["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", cmd]
                        setVolumeProc.running = true
                        getVolume.running = true 
                    }
                }
            }

            // Slider for level control
            Slider {
                id: volumeSlider
                Layout.fillWidth: true
                from: 0
                to: 100
                value: volumeLevel

                // Prevent infinite loop when setting value from system
                onMoved: {
                    let vol = value / 100
                    setVolumeProc.command = ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", vol.toString()]
                    setVolumeProc.running = true
                }

                // Track (the line the handle slides along)
                background: Rectangle {
                    x: volumeSlider.leftPadding
                    y: volumeSlider.topPadding + volumeSlider.availableHeight / 2 - height / 2
                    implicitWidth: 200
                    implicitHeight: 20
                    width: volumeSlider.availableWidth
                    height: 4
                    radius: 2
                    color: Colors.colors.foregroundMuted // unfilled (right side) track color

                    Rectangle {
                        width: volumeSlider.visualPosition * parent.width
                        height: parent.height
                        radius: 2
                        color: Colors.colors.accent // filled (progress) track color
                    }
                }

                // Handle (the round knob dragged)
                handle: Rectangle {
                    x: volumeSlider.leftPadding + volumeSlider.visualPosition * (volumeSlider.availableWidth - width)
                    y: volumeSlider.topPadding + volumeSlider.availableHeight / 2 - height / 2
                    implicitWidth: 16
                    implicitHeight: 16
                    radius: width / 2
                    color: Colors.colors.accent // knob color
                    border.color: Colors.colors.accent
                }
            }

            Text {
                text: volumeLevel + " %"
                font.family: "Symbols Nerd Font"
                font.pixelSize: 15
                font.bold: true
                color: Colors.colors.foreground
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Colors.colors.border
        }
    }

    // ----- Media Player (Mpris) Section -----

   property var activePlayer: null
    property bool mediaSeeking: false
    property int mediaTick: 0 // bumped periodically to force position/slider re-evaluation

    function formatMediaTime(seconds) {
        if (!seconds || seconds < 0 || !isFinite(seconds)) return "0:00"
        const total = Math.floor(seconds)
        const m = Math.floor(total / 60)
        const s = total % 60
        return m + ":" + (s < 10 ? "0" : "") + s
    }

    function pickActivePlayer() {
        const players = Mpris.players.values
        let playing = null
        let fallback = null
        for (const p of players) {
            if (p.playbackState === MprisPlaybackState.Playing) {
                playing = p
                break
            }
            if (!fallback) fallback = p
        }
        root.activePlayer = playing || fallback || null
    }

    Connections {
        target: Mpris.players
        function onValuesChanged() { root.pickActivePlayer() }
    }

    Component.onCompleted: root.pickActivePlayer()

    // Poll for playback state / position changes, since not everything is reactive
    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            root.pickActivePlayer()
            if (!root.mediaSeeking) root.mediaTick++
        }
    }

    ColumnLayout {
        id: mediaLayout
        anchors.top: volumeLayout.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: 5
        spacing: 12
        visible: root.activePlayer !== null

        // --- Track Info Row ---
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Rectangle {
                Layout.preferredWidth: 40
                Layout.preferredHeight: 40
                radius: 6
                color: Colors.colors.foregroundMuted
                clip: true

                Image {
                    anchors.fill: parent
                    source: root.activePlayer && root.activePlayer.trackArtUrl ? root.activePlayer.trackArtUrl : ""
                    fillMode: Image.PreserveAspectCrop
                    visible: source !== ""
                }

                Text {
                    anchors.centerIn: parent
                    visible: !root.activePlayer || !root.activePlayer.trackArtUrl
                    text: "\uf001" // music note fallback icon
                    font.family: "Symbols Nerd Font"
                    font.pixelSize: 18
                    color: Colors.colors.foreground
                }
            }

            ColumnLayout {
                spacing: 2
                Layout.fillWidth: true

                Text {
                    text: root.activePlayer && root.activePlayer.trackTitle ? root.activePlayer.trackTitle : "Nothing Playing"
                    color: Colors.colors.foreground
                    font.bold: true
                    font.pixelSize: 14
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                Text {
                    text: {
                        if (!root.activePlayer) return ""
                        const parts = [root.activePlayer.trackArtist, root.activePlayer.trackAlbum].filter(s => s && s.length > 0)
                        return parts.length > 0 ? parts.join(" — ") : root.activePlayer.identity
                    }
                    color: Colors.colors.foregroundMuted
                    font.pixelSize: 12
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
            }
        }

        // --- Seek Bar Row ---
        RowLayout {
            Layout.fillWidth: true
            spacing: 10
            visible: root.activePlayer !== null && root.activePlayer.lengthSupported

            Text {
                text: root.mediaTick, root.activePlayer ? root.formatMediaTime(root.activePlayer.position) : "0:00"
                font.pixelSize: 11
                color: Colors.colors.foregroundMuted
                Layout.preferredWidth: 36
            }

            Slider {
                id: mediaSlider
                Layout.fillWidth: true
                from: 0
                to: root.activePlayer ? root.activePlayer.length : 0
                value: root.mediaTick, (root.activePlayer && !root.mediaSeeking ? root.activePlayer.position : mediaSlider.value)
                enabled: root.activePlayer !== null && root.activePlayer.canSeek

                onPressedChanged: {
                    root.mediaSeeking = pressed
                    if (!pressed && root.activePlayer && root.activePlayer.canSeek) {
                        root.activePlayer.position = value
                    }
                }

                background: Rectangle {
                    x: mediaSlider.leftPadding
                    y: mediaSlider.topPadding + mediaSlider.availableHeight / 2 - height / 2
                    implicitWidth: 200
                    implicitHeight: 20
                    width: mediaSlider.availableWidth
                    height: 4
                    radius: 2
                    color: Colors.colors.foregroundMuted

                    Rectangle {
                        width: mediaSlider.visualPosition * parent.width
                        height: parent.height
                        radius: 2
                        color: Colors.colors.accent
                    }
                }

                handle: Rectangle {
                    x: mediaSlider.leftPadding + mediaSlider.visualPosition * (mediaSlider.availableWidth - width)
                    y: mediaSlider.topPadding + mediaSlider.availableHeight / 2 - height / 2
                    implicitWidth: 16
                    implicitHeight: 16
                    radius: width / 2
                    color: Colors.colors.accent
                    border.color: Colors.colors.accent
                }
            }

            Text {
                text: root.activePlayer ? root.formatMediaTime(root.activePlayer.length) : "0:00"
                font.pixelSize: 11
                color: Colors.colors.foregroundMuted
                Layout.preferredWidth: 36
            }
        }

        // --- Playback Controls Row ---
        RowLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
            spacing: 28

            MouseArea {
                Layout.preferredWidth: 28
                Layout.preferredHeight: 28
                enabled: root.activePlayer !== null && root.activePlayer.canGoPrevious
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.activePlayer.previous()

                Text {
                    anchors.centerIn: parent
                    text: "\uf048" // previous icon
                    font.family: "Symbols Nerd Font"
                    font.pixelSize: 18
                    color: parent.enabled ? Colors.colors.foreground : Colors.colors.foregroundMuted
                }
            }

            MouseArea {
                Layout.preferredWidth: 34
                Layout.preferredHeight: 34
                enabled: root.activePlayer !== null && (root.activePlayer.canPlay || root.activePlayer.canPause)
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.activePlayer.togglePlaying()

                Text {
                    anchors.centerIn: parent
                    text: root.activePlayer && root.activePlayer.playbackState === MprisPlaybackState.Playing ? "\uf04c" : "\uf04b" // pause : play
                    font.family: "Symbols Nerd Font"
                    font.pixelSize: 22
                    color: parent.enabled ? Colors.colors.foreground : Colors.colors.foregroundMuted
                }
            }

            MouseArea {
                Layout.preferredWidth: 28
                Layout.preferredHeight: 28
                enabled: root.activePlayer !== null && root.activePlayer.canGoNext
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.activePlayer.next()

                Text {
                    anchors.centerIn: parent
                    text: "\uf051" // next icon
                    font.family: "Symbols Nerd Font"
                    font.pixelSize: 18
                    color: parent.enabled ? Colors.colors.foreground : Colors.colors.foregroundMuted
                }
            }
        }
    }
}