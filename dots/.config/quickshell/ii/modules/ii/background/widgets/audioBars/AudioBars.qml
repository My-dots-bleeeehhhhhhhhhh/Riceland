import QtQuick
import Quickshell.Io
import qs
import qs.modules.common
import qs.modules.common.functions

// An audio spectrum strip across the bottom of the wallpaper.
//
// GLava was the obvious tool for this and it cannot be used: it needs X11's
// Xcomposite and a real root desktop window to draw onto, and under Wayland
// there is no such window for it to find. cava is already installed and the
// dots already parse its raw output for the media popup, so the bars are drawn
// here instead -- which also keeps them on the same layer as everything else,
// above the wallpaper and below every window.
Item {
    id: root

    required property real screenWidth
    property var config: Config.options.background.audioBars
    property int barCount: config.bars ?? 90
    property var values: []

    // cava's ascii output is one line of `;`-separated integers per frame,
    // scaled to ascii_max_range.
    Process {
        id: cavaProc
        running: root.visible
        command: ["cava", "-p",
            FileUtils.trimFileProtocol(Directories.scriptPath) + "/cava/bars_config.txt"]
        stdout: SplitParser {
            onRead: data => {
                const points = data.split(";")
                    .map(p => parseFloat(p.trim()))
                    .filter(p => !isNaN(p));
                if (points.length > 0) root.values = points;
            }
        }
        onRunningChanged: if (!cavaProc.running) root.values = []
    }

    Row {
        id: barRow
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            // Not simply the bar's height: with the bar at the bottom, its
            // layer-shell surface is taller than the panel you can see -- the
            // extra is transparent shadow padding above it. Clearing the full
            // layer height leaves the strip visibly floating, so this wants the
            // distance to the bar's *visible* top edge.
            bottomMargin: root.config.bottomMargin ?? 0
        }
        spacing: root.config.gap ?? 3

        Repeater {
            model: root.barCount

            Rectangle {
                required property int index
                readonly property real value:
                    (root.values[index] ?? 0) / (root.config.maxValue ?? 1000)

                width: (barRow.width - barRow.spacing * (root.barCount - 1))
                       / root.barCount
                height: Math.max(root.config.minHeight ?? 2,
                                 value * (root.config.maxHeight ?? 140))
                anchors.bottom: parent.bottom
                radius: root.config.radius ?? 0
                color: root.config.color ?? "#ffffff"
                opacity: root.config.opacity ?? 0.85

                Behavior on height {
                    NumberAnimation { duration: 45; easing.type: Easing.OutQuad }
                }
            }
        }
    }
}
