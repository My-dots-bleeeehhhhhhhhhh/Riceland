import QtQuick
import Quickshell.Io
import qs
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.common.widgets.widgetCanvas
import qs.modules.ii.background.widgets

// The latest posts from a Discord announcements channel.
//
// cordannounce does the fetching and the new-post notification; this only
// renders what it prints. The bot token stays in a file it reads -- it is
// never passed as an argument, since argv is readable by any process on the
// machine, so the widget never handles the credential either.
AbstractBackgroundWidget {
    id: root

    configEntryName: "announcements"
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
        id: proc
        command: {
            const args = ["cordannounce",
                "--channel", root.configEntry.channel ?? "",
                "--count", String(root.configEntry.count ?? 3),
                "--width", String(root.configEntry.width ?? 52)];
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
        if ((root.configEntry.channel ?? "").length === 0) return;
        proc.running = false;
        proc.running = true;
    }

    Component.onCompleted: refresh()

    readonly property string settingsSignature: [
        root.configEntry.channel, root.configEntry.count,
        root.configEntry.width, root.configEntry.notify,
        root.configEntry.fontSize, root.configEntry.showPanel,
        root.configEntry.textColor
    ].join("|")
    onSettingsSignatureChanged: root.refresh()

    // Announcements are not time-critical and Discord rate-limits per route,
    // so this stays slow on purpose. A minute is already far more often than
    // anyone posts.
    Timer {
        interval: Math.max(30, root.configEntry.refreshSeconds ?? 120) * 1000
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
            text: root.output.length > 0 ? root.output : "announcements: loading..."
            color: root.themed(root.configEntry.textColor, "#ffffff")
            font {
                family: Appearance.font.family.monospace
                pixelSize: root.configEntry.fontSize ?? 14
                weight: Font.Medium
            }
            lineHeight: 1.15
        }
    }
}
