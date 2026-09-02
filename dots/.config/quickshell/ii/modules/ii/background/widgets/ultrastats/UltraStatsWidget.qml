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
    needsColText: true

    implicitWidth: backgroundShape.implicitWidth
    implicitHeight: backgroundShape.implicitHeight

    property string output: ""
    property int refreshSeconds: configEntry.refreshSeconds ?? 300

    Process {
        id: statsProc
        command: ["ultrastats", "--compact"]
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
        implicitWidth: statsText.implicitWidth + 40
        implicitHeight: statsText.implicitHeight + 32

        StyledText {
            id: statsText
            anchors.centerIn: parent
            horizontalAlignment: Text.AlignLeft
            color: root.colText
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
