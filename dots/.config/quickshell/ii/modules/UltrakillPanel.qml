import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Item {
    id: root
    property var data: null
    property int updateInterval: 30000

    function fmtTime(sec) {
        if (sec <= 0) return "--:--.--"
        var m = Math.floor(sec / 60)
        var s = (sec % 60).toFixed(2)
        return m.toString().padStart(2, "0") + ":" + s.padStart(5, "0")
    }

    Process {
        id: parser
        command: ["python3", Quickshell.configDir + "/../ags/scripts/uk_parse.py"]
        running: true
        onStreamFinished: {
            try {
                root.data = JSON.parse(this.text)
                errorLabel.visible = false
            } catch (e) {
                errorLabel.text = "Parse error: " + e
                errorLabel.visible = true
            }
        }
        onStdErr: {
            errorLabel.text = this.text
            errorLabel.visible = true
        }
    }

    Timer {
        interval: root.updateInterval
        running: true
        repeat: true
        onTriggered: parser.running = true
    }

    Component.onCompleted: parser.running = true

    ScrollView {
        anchors.fill: parent
        clip: true
        ScrollBar.vertical: ScrollBar { }
        ColumnLayout {
            width: parent.width
            spacing: 16

            // Header
            RowLayout {
                Layout.fillWidth: true
                Label {
                    text: "ULTRAKILL TERMINAL v1.0"
                    font.family: "JetBrains Mono"; font.pixelSize: 15; font.bold: true
                    color: "#f78166"
                }
                Label {
                    text: "▓▓▓ LINK ESTABLISHED ▓▓▓"
                    font.family: "JetBrains Mono"; font.pixelSize: 11
                    color: "#6bcb77"
                }
                Label {
                    id: clockLabel
                    text: Qt.formatDateTime(new Date(), "HH:mm:ss")
                    font.family: "JetBrains Mono"; font.pixelSize: 11
                    color: "#8b949e"
                    Layout.alignment: Qt.AlignRight
                    Layout.fillWidth: true
                }
            }

            // Cyber Grind
            Repeater {
                model: root.data?.cybergrind ? 1 : 0
                Rectangle {
                    Layout.fillWidth: true
                    color: "#161b22"
                    border.color: "#30363d"
                    border.width: 1
                    radius: 8
                    padding: 12
                    ColumnLayout {
                        spacing: 8
                        Label {
                            text: "CYBER GRIND HIGHSCORES"
                            font.family: "JetBrains Mono"; font.pixelSize: 11; font.bold: true
                            color: "#f78166"
                        }
                        RowLayout { spacing: 4
                            Repeater {
                                model: ["HARMLESS","LENIENT","STANDARD","VIOLENT","BRUTAL","UKMD"]
                                delegate: DiffCell {
                                    diffName: modelData
                                    diffIdx: index
                                    wave: root.data.cybergrind.waves[index]
                                    kills: root.data.cybergrind.kills[index]
                                    style: root.data.cybergrind.style[index]
                                    time: root.data.cybergrind.times[index]
                                }
                            }
                        }
                    }
                }
            }

            // Campaign Ranks
            Repeater {
                model: root.data?.levels ? 1 : 0
                Rectangle {
                    Layout.fillWidth: true
                    color: "#161b22"
                    border.color: "#30363d"
                    border.width: 1
                    radius: 8
                    padding: 12
                    ColumnLayout {
                        spacing: 8
                        Label {
                            text: "CAMPAIGN RANKS"
                            font.family: "JetBrains Mono"; font.pixelSize: 11; font.bold: true
                            color: "#4ecdc4"
                        }
                        Column {
                            spacing: 6
                            Repeater {
                                model: root.data.levels
                                delegate: LevelRow { levelData: modelData }
                            }
                        }
                    }
                }
            }

            // Leaderboards
            Repeater {
                model: root.data?.leaderboards && Object.keys(root.data.leaderboards).length > 0 ? 1 : 0
                Rectangle {
                    Layout.fillWidth: true
                    color: "#161b22"
                    border.color: "#30363d"
                    border.width: 1
                    radius: 8
                    padding: 12
                    ColumnLayout {
                        spacing: 8
                        Label {
                            text: "LOCAL BEST TIMES"
                            font.family: "JetBrains Mono"; font.pixelSize: 11; font.bold: true
                            color: "#ff6b9d"
                        }
                        Column {
                            spacing: 8
                            Repeater {
                                model: Object.keys(root.data.leaderboards)
                                delegate: LBRow { levelName: modelData, lbData: root.data.leaderboards[modelData] }
                            }
                        }
                    }
                }
            }

            // Error / Empty state
            Label {
                id: errorLabel
                visible: false
                text: "No data"
                color: "#8b949e"
                font.family: "JetBrains Mono"
            }
        }
    }
}

// ===== COMPONENTS =====

Component {
    id: DiffCell
    Rectangle {
        Layout.fillWidth: true
        color: "transparent"
        ColumnLayout { spacing: 2
            Label {
                text: diffName
                font.family: "JetBrains Mono"; font.pixelSize: 9; font.bold: true
                color: diffColors[diffIdx]
            }
            Label {
                text: wave > 0 ? "Wave " + wave : (kills > 0 ? kills + "K" : (style > 0 ? style + "S" : (time > 0 ? fmtTime(time) : "---")))
                font.family: "JetBrains Mono"; font.pixelSize: 11
                color: (wave > 0 || kills > 0 || style > 0 || time > 0) ? "#e6edf3" : "#8b949e"
            }
        }
        property var diffColors: ["#6bcb77", "#4ecdc4", "#ffd93d", "#ff9f43", "#ff6b6b", "#ff6b9d"]
    }
}

Component {
    id: LevelRow
    Rectangle {
        Layout.fillWidth: true
        color: "#0d1117"
        border.color: levelData.ranks.some(function(r) { return r !== "NONE" }) ? "#30363d" : "#30363d80"
        border.width: 1
        radius: 6
        padding: 8
        ColumnLayout { spacing: 4
            RowLayout {
                Label {
                    text: levelData.name
                    font.family: "JetBrains Mono"; font.pixelSize: 11; font.bold: true
                    color: levelData.ranks.some(function(r) { return r !== "NONE" }) ? "#e6edf3" : "#8b949e"
                }
                Label {
                    text: "SECRETS: " + levelData.secrets.filter(function(s) { return s }).length + "/" + levelData.secrets.length
                    font.family: "JetBrains Mono"; font.pixelSize: 9
                    color: "#4ecdc4"
                    Layout.alignment: Qt.AlignRight
                }
                Label {
                    text: levelData.challenge ? "★ CHALLENGE" : ""
                    font.family: "JetBrains Mono"; font.pixelSize: 9; font.bold: true
                    color: "#ff6b9d"
                }
            }
            RowLayout { spacing: 4
                Repeater {
                    model: 6
                    delegate: RankBox { rank: levelData.ranks[index], diffIdx: index }
                }
            }
        }
        property var rankColors: { "NONE": "#8b949e", "D": "#8b949e", "C": "#4ecdc4", "B": "#6bcb77", "A": "#ffd93d", "S": "#ff9f43", "P": "#ff6b9d" }
    }
}

Component {
    id: RankBox
    Rectangle {
        Layout.fillWidth: true
        color: rankColors[rank] + "22"
        border.color: rankColors[rank]
        border.width: 1
        radius: 4
        padding: 4
        Label {
            text: rank
            font.family: "JetBrains Mono"; font.pixelSize: 11; font.bold: true
            color: rankColors[rank]
            anchors.centerIn: parent
        }
        property var rankColors: { "NONE": "#8b949e", "D": "#8b949e", "C": "#4ecdc4", "B": "#6bcb77", "A": "#ffd93d", "S": "#ff9f43", "P": "#ff6b9d" }
    }
}

Component {
    id: LBRow
    Rectangle {
        Layout.fillWidth: true
        color: "#161b22"
        border.color: "#30363d"
        border.width: 1
        radius: 8
        padding: 10
        ColumnLayout { spacing: 6
            Label {
                text: levelName
                font.family: "JetBrains Mono"; font.pixelSize: 11; font.bold: true
                color: "#ff9f43"
            }
            RowLayout { spacing: 4
                Repeater {
                    model: 6
                    delegate: LBTimeCell {
                        diffIdx: index
                        anyTime: lbData.any[index]
                        pTime: lbData.p_rank[index]
                    }
                }
            }
        }
    }
}

Component {
    id: LBTimeCell
    ColumnLayout { spacing: 2
        Label { text: diffNames[diffIdx]; font.family: "JetBrains Mono"; font.pixelSize: 9; font.bold: true; color: diffColors[diffIdx] }
        Label { text: anyTime > 0 ? fmtTime(anyTime) : "--:--.--"; font.family: "JetBrains Mono"; font.pixelSize: 10; color: anyTime > 0 ? "#e6edf3" : "#8b949e" }
        Label { text: pTime > 0 ? fmtTime(pTime) : "--:--.--"; font.family: "JetBrains Mono"; font.pixelSize: 10; color: pTime > 0 ? "#e6edf3" : "#8b949e" }
    }
    property var diffNames: ["HARMLESS","LENIENT","STANDARD","VIOLENT","BRUTAL","UKMD"]
    property var diffColors: ["#6bcb77", "#4ecdc4", "#ffd93d", "#ff9f43", "#ff6b6b", "#ff6b9d"]
}
