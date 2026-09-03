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

    // "auto" follows the rice's palette. The accent reads better than the
    // foreground for bars, which are shape rather than text.
    readonly property color barColor: {
        const v = root.config.color;
        if (v === "auto") return Appearance.colors.colPrimary;
        return v ?? "#ffffff";
    }

    // cava's ascii output is one line of `;`-separated integers per frame,
    // scaled to ascii_max_range.
    Process {
        id: cavaProc
        running: root.visible
        // cava's bar count comes from its config file, so it is generated from
        // the same number the Repeater uses. A static config silently caps the
        // audio at its own count and any bars beyond it stay flat forever.
        command: ["cava-bars",
            "--bars", String(Math.min(256, root.barCount)),
            "--low", String(root.config.lowerCutoff ?? 40),
            "--high", String(root.config.higherCutoff ?? 12000),
            "--noise", String(root.config.noiseReduction ?? 30),
            "--sens", String(root.config.sensitivity ?? 100),
            "--autosens", (root.config.autosens ?? true) ? "1" : "0",
            "--integral", String(root.config.integral ?? 77),
            "--gravity", String(root.config.gravity ?? 100),
            "--overshoot", String(root.config.overshoot ?? 20),
            "--monstercat", String(root.config.monstercat ?? 0),
            "--waves", String(root.config.waves ?? 0),
            "--eq", root.config.eq ?? "1,1,1,1,1"]
        stdout: SplitParser {
            onRead: data => {
                const points = data.split(";")
                    .map(p => parseFloat(p.trim()))
                    .filter(p => !isNaN(p));
                if (points.length > 0) root.values = points;
            }
        }
        onRunningChanged: if (!cavaProc.running) root.values = []

        readonly property string signature: command.join("|")
        onSignatureChanged: {
            root.values = [];
            cavaProc.running = false;
            cavaProc.running = Qt.binding(() => root.visible);
        }
    }

    // cava will not emit more than 256 values, so beyond that the bars are
    // resampled from what it does send rather than left flat. Interpolating
    // rather than repeating keeps the envelope smooth instead of stair-stepped.
    function sample(i) {
        const n = root.values.length;
        if (n === 0) return 0;
        if (n === 1) return root.values[0];
        const pos = i * (n - 1) / Math.max(1, root.barCount - 1);
        const lo = Math.floor(pos);
        const hi = Math.min(n - 1, lo + 1);
        const t = pos - lo;
        return (root.values[lo] ?? 0) * (1 - t) + (root.values[hi] ?? 0) * t;
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
                // gain scales everything; curve below 1 lifts the quiet end
                // harder than the loud end, so detail appears without the
                // peaks simply clipping flat against maxHeight.
                readonly property real value: {
                    const raw = root.sample(index) / (root.config.maxValue ?? 1000);
                    const gained = raw * (root.config.gain ?? 1.0);
                    const curve = root.config.curve ?? 1.0;
                    const shaped = curve === 1.0 ? gained
                                                 : Math.pow(Math.max(0, gained), curve);
                    return Math.min(1.0, shaped);
                }

                width: (barRow.width - barRow.spacing * (root.barCount - 1))
                       / root.barCount
                height: Math.max(root.config.minHeight ?? 2,
                                 value * (root.config.maxHeight ?? 140))
                anchors.bottom: parent.bottom
                radius: root.config.radius ?? 0
                color: root.barColor
                opacity: root.config.opacity ?? 0.85

                // cava already smooths in time (integral/gravity). Animating
                // here as well smooths a second time, rounding off exactly the
                // transients that make a beat visible. 0 disables it entirely
                // and lets cava's own response through unmodified.
                Behavior on height {
                    enabled: (root.config.animationMs ?? 0) > 0
                    NumberAnimation {
                        duration: root.config.animationMs ?? 0
                        easing.type: Easing.OutQuad
                    }
                }
            }
        }
    }
}
