// StatisticsTab.qml

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

    // Small helper so every bar's fill color reacts to how "hot" the stat is
    function levelColor(percent, warnAt, critAt) {
        if (percent >= critAt) return Colors.colors.error
        if (percent >= warnAt) return Colors.colors.warning
        return Colors.colors.accent
    }

    // ----- CPU Section -----

    property int cpuUsage: 0
    property real prevCpuTotal: 0
    property real prevCpuIdle: 0

    property real cpuTemp: 0
    property bool hasCpuTemp: false

    Process {
        id: cpuProc
        command: ["cat", "/proc/stat"]
        stdout: StdioCollector {
            onStreamFinished: {
                const line = text.split("\n")[0]
                const parts = line.trim().split(/\s+/).slice(1).map(Number)
                if (parts.length < 4) return

                const idle = parts[3] + (parts[4] || 0) // idle + iowait
                const total = parts.reduce((a, b) => a + b, 0)

                const totalDelta = total - root.prevCpuTotal
                const idleDelta = idle - root.prevCpuIdle

                if (root.prevCpuTotal > 0 && totalDelta > 0) {
                    root.cpuUsage = Math.round(Math.max(0, Math.min(100, (1 - idleDelta / totalDelta) * 100)))
                }

                root.prevCpuTotal = total
                root.prevCpuIdle = idle
            }
        }
    }

    Process {
        id: tempProc
        command: ["bash", "-c", "cat /sys/class/thermal/thermal_zone*/temp 2>/dev/null | sort -rn | head -1"]
        stdout: StdioCollector {
            onStreamFinished: {
                const val = parseInt(text.trim())
                root.hasCpuTemp = !isNaN(val)
                if (root.hasCpuTemp) root.cpuTemp = val / 1000
            }
        }
    }

    // ----- Memory / Swap Section -----

    property real memUsedGb: 0
    property real memTotalGb: 0
    property int memPercent: 0

    property real swapUsedGb: 0
    property real swapTotalGb: 0
    property int swapPercent: 0

    Process {
        id: memProc
        command: ["cat", "/proc/meminfo"]
        stdout: StdioCollector {
            onStreamFinished: {
                const info = {}
                for (const line of text.trim().split("\n")) {
                    const match = line.match(/^(\w+):\s+(\d+)/)
                    if (match) info[match[1]] = parseInt(match[2]) // kB
                }

                const totalKb = info.MemTotal || 0
                const availKb = info.MemAvailable !== undefined ? info.MemAvailable : (info.MemFree || 0)
                const usedKb = Math.max(0, totalKb - availKb)

                root.memTotalGb = totalKb / 1048576
                root.memUsedGb = usedKb / 1048576
                root.memPercent = totalKb > 0 ? Math.round((usedKb / totalKb) * 100) : 0

                const swapTotalKb = info.SwapTotal || 0
                const swapFreeKb = info.SwapFree || 0
                const swapUsedKb = Math.max(0, swapTotalKb - swapFreeKb)

                root.swapTotalGb = swapTotalKb / 1048576
                root.swapUsedGb = swapUsedKb / 1048576
                root.swapPercent = swapTotalKb > 0 ? Math.round((swapUsedKb / swapTotalKb) * 100) : 0
            }
        }
    }

    // ----- Disk Section -----

    property real diskUsedGb: 0
    property real diskTotalGb: 0
    property int diskPercent: 0

    Process {
        id: diskProc
        command: ["bash", "-c", "df -BG / | tail -1"]
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.trim().split(/\s+/)
                if (parts.length >= 5) {
                    root.diskTotalGb = parseFloat(parts[1])
                    root.diskUsedGb = parseFloat(parts[2])
                    root.diskPercent = parseInt(parts[4])
                }
            }
        }
    }

    // ----- Network Throughput Section -----

    property real netDownKBs: 0
    property real netUpKBs: 0
    property real prevRxBytes: -1
    property real prevTxBytes: -1

    Process {
        id: netProc
        command: ["bash", "-c", "cat /proc/net/dev | tail -n +3 | grep -v ' lo:'"]
        stdout: StdioCollector {
            onStreamFinished: {
                let rx = 0
                let tx = 0
                for (const line of text.trim().split("\n")) {
                    const cols = line.split(":")
                    if (cols.length < 2) continue
                    const fields = cols[1].trim().split(/\s+/)
                    if (fields.length < 9) continue
                    rx += parseFloat(fields[0])
                    tx += parseFloat(fields[8])
                }

                if (root.prevRxBytes >= 0) {
                    // 2 second poll interval
                    root.netDownKBs = Math.max(0, (rx - root.prevRxBytes) / 1024 / 2)
                    root.netUpKBs = Math.max(0, (tx - root.prevTxBytes) / 1024 / 2)
                }

                root.prevRxBytes = rx
                root.prevTxBytes = tx
            }
        }
    }

    function formatRate(kbs) {
        if (kbs >= 1024) return (kbs / 1024).toFixed(1) + " MB/s"
        return kbs.toFixed(0) + " KB/s"
    }

    // ----- Uptime / Load Average Section -----

    property string uptimeText: ""
    property string loadAvgText: ""

    Process {
        id: uptimeProc
        command: ["uptime", "-p"]
        stdout: StdioCollector {
            onStreamFinished: root.uptimeText = text.trim().replace(/^up /, "")
        }
    }

    Process {
        id: loadAvgProc
        command: ["cat", "/proc/loadavg"]
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.trim().split(" ")
                if (parts.length >= 3) root.loadAvgText = parts[0] + "  " + parts[1] + "  " + parts[2]
            }
        }
    }

    function refreshAll() {
        cpuProc.running = true
        tempProc.running = true
        memProc.running = true
        diskProc.running = true
        netProc.running = true
        uptimeProc.running = true
        loadAvgProc.running = true
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refreshAll()
    }

    // ----- Layout -----

    ScrollView {
        anchors.fill: parent
        clip: true
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        ScrollBar.vertical.policy: ScrollBar.AsNeeded

        ColumnLayout {
            id: contentLayout
            width: root.width
            spacing: 10

            ColumnLayout {
                id: cpuLayout
                Layout.fillWidth: true
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Text {
                        text: "\uf2db" // microchip icon
                        font.family: "Symbols Nerd Font"
                        font.pixelSize: 22
                        color: Colors.colors.foreground
                        Layout.preferredWidth: 28
                    }

                    Text {
                        text: "CPU"
                        color: Colors.colors.foreground
                        font.bold: true
                        font.pixelSize: 14
                        Layout.fillWidth: true
                    }

                    Text {
                        text: root.hasCpuTemp ? root.cpuTemp.toFixed(0) + "°C  ·  " + root.cpuUsage + "%" : root.cpuUsage + "%"
                        color: Colors.colors.foregroundMuted
                        font.pixelSize: 12
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.leftMargin: 38
                    height: 6
                    radius: 3
                    color: Colors.colors.foregroundMuted

                    Rectangle {
                        width: parent.width * (root.cpuUsage / 100)
                        height: parent.height
                        radius: 3
                        color: root.levelColor(root.cpuUsage, 60, 85)

                        Behavior on width {
                            NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.topMargin: 4
                    height: 1
                    color: Colors.colors.border
                }
            }

            ColumnLayout {
                id: memoryLayout
                Layout.fillWidth: true
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Text {
                        text: "\udb80\udf5b" // memory icon
                        font.family: "Symbols Nerd Font"
                        font.pixelSize: 22
                        color: Colors.colors.foreground
                        Layout.preferredWidth: 28
                    }

                    Text {
                        text: "Memory"
                        color: Colors.colors.foreground
                        font.bold: true
                        font.pixelSize: 14
                        Layout.fillWidth: true
                    }

                    Text {
                        text: root.memUsedGb.toFixed(1) + " / " + root.memTotalGb.toFixed(1) + " GB"
                        color: Colors.colors.foregroundMuted
                        font.pixelSize: 12
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.leftMargin: 38
                    height: 6
                    radius: 3
                    color: Colors.colors.foregroundMuted

                    Rectangle {
                        width: parent.width * (root.memPercent / 100)
                        height: parent.height
                        radius: 3
                        color: root.levelColor(root.memPercent, 70, 90)

                        Behavior on width {
                            NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
                        }
                    }
                }

                // --- Swap (only shown if a swap device exists) ---
                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: 6
                    spacing: 10
                    visible: root.swapTotalGb > 0

                    Text {
                        text: "\uf0ec" // exchange/swap icon
                        font.family: "Symbols Nerd Font"
                        font.pixelSize: 18
                        color: Colors.colors.foreground
                        Layout.preferredWidth: 28
                    }

                    Text {
                        text: "Swap"
                        color: Colors.colors.foreground
                        font.pixelSize: 13
                        Layout.fillWidth: true
                    }

                    Text {
                        text: root.swapUsedGb.toFixed(1) + " / " + root.swapTotalGb.toFixed(1) + " GB"
                        color: Colors.colors.foregroundMuted
                        font.pixelSize: 12
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.leftMargin: 38
                    height: 4
                    radius: 2
                    color: Colors.colors.foregroundMuted
                    visible: root.swapTotalGb > 0

                    Rectangle {
                        width: parent.width * (root.swapPercent / 100)
                        height: parent.height
                        radius: 2
                        color: Colors.colors.accentAlt

                        Behavior on width {
                            NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.topMargin: 4
                    height: 1
                    color: Colors.colors.border
                }
            }

            ColumnLayout {
                id: diskLayout
                Layout.fillWidth: true
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Text {
                        text: "\uf0a0" // hdd icon
                        font.family: "Symbols Nerd Font"
                        font.pixelSize: 22
                        color: Colors.colors.foreground
                        Layout.preferredWidth: 28
                    }

                    Text {
                        text: "Disk (/)"
                        color: Colors.colors.foreground
                        font.bold: true
                        font.pixelSize: 14
                        Layout.fillWidth: true
                    }

                    Text {
                        text: root.diskUsedGb.toFixed(0) + " / " + root.diskTotalGb.toFixed(0) + " GB"
                        color: Colors.colors.foregroundMuted
                        font.pixelSize: 12
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.leftMargin: 38
                    height: 6
                    radius: 3
                    color: Colors.colors.foregroundMuted

                    Rectangle {
                        width: parent.width * (root.diskPercent / 100)
                        height: parent.height
                        radius: 3
                        color: root.levelColor(root.diskPercent, 75, 90)

                        Behavior on width {
                            NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.topMargin: 4
                    height: 1
                    color: Colors.colors.border
                }
            }

            ColumnLayout {
                id: networkLayout
                Layout.fillWidth: true
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Text {
                        text: "\uf0ab" // signal/network icon
                        font.family: "Symbols Nerd Font"
                        font.pixelSize: 22
                        color: Colors.colors.foreground
                        Layout.preferredWidth: 28
                    }

                    Text {
                        text: "Network"
                        color: Colors.colors.foreground
                        font.bold: true
                        font.pixelSize: 14
                        Layout.fillWidth: true
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: 38
                    spacing: 20

                    RowLayout {
                        spacing: 6
                        Text {
                            text: "\uf063" // down arrow
                            font.family: "Symbols Nerd Font"
                            font.pixelSize: 13
                            color: Colors.colors.success
                        }
                        Text {
                            text: root.formatRate(root.netDownKBs)
                            color: Colors.colors.foregroundMuted
                            font.pixelSize: 12
                        }
                    }

                    RowLayout {
                        spacing: 6
                        Text {
                            text: "\uf062" // up arrow
                            font.family: "Symbols Nerd Font"
                            font.pixelSize: 13
                            color: Colors.colors.info
                        }
                        Text {
                            text: root.formatRate(root.netUpKBs)
                            color: Colors.colors.foregroundMuted
                            font.pixelSize: 12
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.topMargin: 4
                    height: 1
                    color: Colors.colors.border
                }
            }

            RowLayout {
                id: systemLayout
                Layout.fillWidth: true
                Layout.bottomMargin: 6
                spacing: 10

                Text {
                    text: "\uf017" // clock icon
                    font.family: "Symbols Nerd Font"
                    font.pixelSize: 22
                    color: Colors.colors.foreground
                    Layout.preferredWidth: 28
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        text: "Uptime"
                        color: Colors.colors.foreground
                        font.bold: true
                        font.pixelSize: 13
                    }

                    Text {
                        text: root.uptimeText.length > 0 ? root.uptimeText : "—"
                        color: Colors.colors.foregroundMuted
                        font.pixelSize: 12
                        elide: Text.ElideRight
                    }
                }

                ColumnLayout {
                    spacing: 2

                    Text {
                        text: "Load Avg"
                        color: Colors.colors.foreground
                        font.bold: true
                        font.pixelSize: 13
                        horizontalAlignment: Text.AlignRight
                        Layout.alignment: Qt.AlignRight
                    }

                    Text {
                        text: root.loadAvgText.length > 0 ? root.loadAvgText : "—"
                        color: Colors.colors.foregroundMuted
                        font.pixelSize: 12
                        horizontalAlignment: Text.AlignRight
                        Layout.alignment: Qt.AlignRight
                    }
                }
            }

        } // end contentLayout
    } // end ScrollView

    Component.onCompleted: root.refreshAll()
}
