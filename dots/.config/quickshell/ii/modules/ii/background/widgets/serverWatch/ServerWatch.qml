import QtQuick
import Quickshell.Io
import qs
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.common.widgets.widgetCanvas
import qs.modules.ii.background.widgets

// Minecraft server watcher. mcwatch does the Server List Ping and the change
// detection (including the desktop notification when someone joins); this only
// renders what it prints, on the same background layer as everything else.
AbstractBackgroundWidget {
    id: root

    configEntryName: "serverWatch"
    needsColText: false

    implicitWidth: backgroundShape.implicitWidth
    implicitHeight: backgroundShape.implicitHeight

    property string output: ""

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

    function themed(value, fallback) {
        if (value === "auto") return Appearance.colors.colOnLayer0;
        return value ?? fallback;
    }

    Process {
        id: watchProc
        command: {
            const args = ["mcwatch",
                "--host", root.configEntry.host ?? "",
                "--port", String(root.configEntry.port ?? 25565),
                "--width", String(root.configEntry.width ?? 46)];
            const who = root.configEntry.watch ?? "";
            if (who.length > 0) args.push("--watch", who);
            if (root.configEntry.notify) args.push("--notify");
            return args;
        }
        stdout: StdioCollector {
            id: collector
            onStreamFinished: {
                if (collector.text.length > 0)
                    root.output = collector.text.replace(/\n+$/, "");
            }
        }
    }

    function refresh() {
        if ((root.configEntry.host ?? "").length === 0) return;
        watchProc.running = false;
        watchProc.running = true;
    }

    Component.onCompleted: refresh()

    readonly property string settingsSignature: [
        root.configEntry.host, root.configEntry.port, root.configEntry.watch,
        root.configEntry.notify, root.configEntry.fontSize,
        root.configEntry.showPanel, root.configEntry.textColor
    ].join("|")
    onSettingsSignatureChanged: root.refresh()

    // A server list ping is a single short TCP round trip, so polling it every
    // half minute is cheap -- but it is still someone else's server, so this
    // stays well clear of anything that could look like hammering.
    Timer {
        interval: Math.max(15, root.configEntry.refreshSeconds ?? 30) * 1000
        running: true; repeat: true
        onTriggered: root.refresh()
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
        border.color: root.themed(root.configEntry.borderColor, "#ffffff")
        implicitWidth: text.implicitWidth + 40
        implicitHeight: text.implicitHeight + 32
        clip: true

        StyledText {
            id: text
            anchors { left: parent.left; top: parent.top
                      leftMargin: 20; topMargin: 16 }
            text: root.output.length > 0 ? root.output : "serverwatch: checking..."
            color: root.themed(root.configEntry.textColor, "#ffffff")
            font {
                family: Appearance.font.family.monospace
                pixelSize: root.configEntry.fontSize ?? 15
                weight: Font.Medium
            }
            lineHeight: 1.15
        }
    }
}
