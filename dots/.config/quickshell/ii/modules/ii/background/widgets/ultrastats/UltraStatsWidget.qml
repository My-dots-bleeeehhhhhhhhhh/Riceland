import QtQuick
import Quickshell.Io
import qs
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.common.widgets.widgetCanvas
import qs.modules.ii.background.widgets

// A monospace readout of ULTRAKILL leaderboard standings, drawn straight onto
// the background layer: above the wallpaper, below every window, click-through
// and fixed where you drop it. The text is whatever `ultrastats --compact`
// prints, so the terminal command stays the single source of truth.
AbstractBackgroundWidget {
    id: root

    configEntryName: "ultrastats"
    needsColText: false

    // Which monitor this copy is on. Background.qml is a Variants over every
    // screen, so each one builds its own widget -- and they all read the same
    // configEntry.x/y, which is why they moved together. Positions are kept
    // per monitor name instead, falling back to the shared x/y for a screen
    // that has never been dragged.
    property string screenName: ""
    readonly property var positions: {
        try { return JSON.parse(root.configEntry.positions || "{}"); }
        catch (e) { return {}; }
    }
    readonly property var myPosition: positions[screenName] ?? null

    targetX: Math.max(0, Math.min(myPosition ? myPosition.x : configEntry.x,
                                  scaledScreenWidth - width))
    targetY: Math.max(0, Math.min(myPosition ? myPosition.y : configEntry.y,
                                  scaledScreenHeight - height))

    // The base scales to 1.05 while held, which shifts the thing you are
    // trying to line up. Off by default; grabEffect brings it back.
    scale: (configEntry.grabEffect && draggable && containsPress) ? 1.05 : 1

    // The base's own onReleased still runs and writes the shared x/y; this
    // adds the per-monitor record on top of it.
    Connections {
        target: root
        function onReleased() {
            if (root.screenName.length === 0) return;
            let all = {};
            try { all = JSON.parse(root.configEntry.positions || "{}"); } catch (e) {}
            all[root.screenName] = { x: root.x, y: root.y };
            root.configEntry.positions = JSON.stringify(all);
        }
    }

    implicitWidth: backgroundShape.implicitWidth
    implicitHeight: backgroundShape.implicitHeight

    property string output: ""
    property int refreshSeconds: configEntry.refreshSeconds ?? 300

    // `compact` is the short block; otherwise the full readout, optionally
    // trimmed to a few sections since all of it is 141 lines.
    Process {
        id: statsProc
        command: {
            if (root.configEntry.compact) return ["ultrastats", "--compact"];
            const args = ["ultrastats"];
            const sections = root.configEntry.sections ?? "";
            if (sections.length > 0) args.push("--sections", sections);
            if (root.configEntry.showLegacy) args.push("--legacy");
            return args;
        }
        stdout: StdioCollector {
            id: statsCollector
            onStreamFinished: {
                if (statsCollector.text.length > 0)
                    root.output = statsCollector.text.replace(/\n+$/, "");
            }
        }
    }

    function refresh() {
        statsProc.running = false;
        statsProc.running = true;
    }

    Component.onCompleted: refresh()
    readonly property string settingsSignature: [
        root.configEntry.compact, root.configEntry.sections,
        root.configEntry.fontSize, root.configEntry.showPanel,
        root.configEntry.showLegacy, root.configEntry.textColor
    ].join("|")
    onSettingsSignatureChanged: root.refresh()

    Timer {
        interval: root.refreshSeconds * 1000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }

    StyledDropShadow {
        target: backgroundShape
    }

    Rectangle {
        id: backgroundShape
        anchors.fill: parent
        radius: Appearance.rounding.normal
        color: root.configEntry.showPanel
            ? ColorUtils.transparentize(Appearance.colors.colLayer0, 0.25)
            : "transparent"
        border.width: root.configEntry.borderWidth ?? 1
        border.color: root.configEntry.borderColor ?? "#ffffff"
        implicitWidth: statsText.implicitWidth + 40
        implicitHeight: statsText.implicitHeight + 32

        clip: true

        StyledText {
            id: statsText
            anchors {
                left: parent.left
                top: parent.top
                leftMargin: 20
                topMargin: 16
            }
            horizontalAlignment: Text.AlignLeft
            color: root.configEntry.textColor ?? "#ffffff"
            text: root.output.length > 0 ? root.output : "ultrastats: no data"
            font {
                family: Appearance.font.family.monospace
                pixelSize: root.configEntry.fontSize ?? 15
                weight: Font.Medium
            }
            lineHeight: 1.15
        }
    }
}
