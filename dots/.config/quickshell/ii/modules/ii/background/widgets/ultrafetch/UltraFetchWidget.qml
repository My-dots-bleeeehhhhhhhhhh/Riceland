import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import qs
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.common.widgets.widgetCanvas
import qs.modules.ii.background.widgets

// A neofetch-style readout with an animated ASCII logo, on the background
// layer. anifetch animates by repainting a terminal, which a layer-shell
// surface cannot host, so ultrafetch-build renders the frames ahead of time
// and this only cycles them -- nothing spawns ffmpeg or chafa on the desktop.
AbstractBackgroundWidget {
    id: root

    configEntryName: "ultrafetch"
    needsColText: false

    implicitWidth: backgroundShape.implicitWidth
    implicitHeight: backgroundShape.implicitHeight

    property string info: ""
    property var frames: []
    property real fps: 2
    property int frameIndex: 0
    readonly property string currentFrame: frames.length > 0 ? frames[frameIndex] : ""

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
    scale: (configEntry.grabEffect && draggable && containsPress) ? 1.05 : 1

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

    Process {
        id: infoProc
        command: ["ultrafetch", "--width", String(root.configEntry.infoWidth ?? 44)]
        stdout: StdioCollector {
            id: infoCollector
            onStreamFinished: {
                if (infoCollector.text.length > 0)
                    root.info = infoCollector.text.replace(/\n+$/, "");
            }
        }
    }

    Process {
        id: framesProc
        command: ["cat", root.configEntry.framesPath || ""]
        stdout: StdioCollector {
            id: framesCollector
            onStreamFinished: {
                try {
                    const doc = JSON.parse(framesCollector.text);
                    root.frames = doc.frames ?? [];
                    root.fps = doc.fps ?? 2;
                } catch (e) {
                    root.frames = [];
                }
            }
        }
    }

    function refresh() {
        infoProc.running = false; infoProc.running = true;
        if ((root.configEntry.framesPath || "").length > 0) {
            framesProc.running = false; framesProc.running = true;
        }
    }

    Component.onCompleted: refresh()

    readonly property string settingsSignature: [
        root.configEntry.fontSize, root.configEntry.showPanel,
        root.configEntry.textColor, root.configEntry.framesPath,
        root.configEntry.infoWidth
    ].join("|")
    onSettingsSignatureChanged: root.refresh()

    Timer {
        interval: (root.configEntry.refreshSeconds ?? 60) * 1000
        running: true; repeat: true
        onTriggered: root.refresh()
    }

    Timer {
        interval: Math.max(50, 1000 / Math.max(0.1, root.fps))
        running: root.frames.length > 1
        repeat: true
        onTriggered: root.frameIndex = (root.frameIndex + 1) % root.frames.length
    }

    StyledDropShadow { target: backgroundShape }

    Rectangle {
        id: backgroundShape
        anchors.fill: parent
        radius: Appearance.rounding.normal
        color: root.configEntry.showPanel
            ? ColorUtils.transparentize(Appearance.colors.colLayer0, 0.25)
            : "transparent"
        border.width: root.configEntry.borderWidth ?? 1
        border.color: root.configEntry.borderColor ?? "#ffffff"
        implicitWidth: content.implicitWidth + 40
        implicitHeight: content.implicitHeight + 32
        clip: true

        RowLayout {
            id: content
            anchors { left: parent.left; top: parent.top; leftMargin: 20; topMargin: 16 }
            spacing: 20

            StyledText {
                visible: root.currentFrame.length > 0
                text: root.currentFrame
                color: root.configEntry.textColor ?? "#ffffff"
                Layout.alignment: Qt.AlignTop
                font {
                    family: Appearance.font.family.monospace
                    pixelSize: root.configEntry.fontSize ?? 15
                }
                lineHeight: 1.0
            }

            StyledText {
                text: root.info.length > 0 ? root.info : "ultrafetch: no data"
                color: root.configEntry.textColor ?? "#ffffff"
                Layout.alignment: Qt.AlignTop
                font {
                    family: Appearance.font.family.monospace
                    pixelSize: root.configEntry.fontSize ?? 15
                    weight: Font.Medium
                }
                lineHeight: 1.15
            }
        }
    }
}
