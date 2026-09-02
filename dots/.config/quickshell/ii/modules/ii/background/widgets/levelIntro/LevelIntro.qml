import QtQuick
import QtQuick.Layouts
import qs
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.common.widgets.widgetCanvas
import qs.modules.ii.background.widgets

// The ULTRAKILL level-intro card, as desktop text: a small spaced-out layer
// line above a large title. No panel and no border -- this is meant to read as
// part of the wallpaper rather than as a widget sitting on it.
AbstractBackgroundWidget {
    id: root

    configEntryName: "levelIntro"
    needsColText: false

    implicitWidth: column.implicitWidth
    implicitHeight: column.implicitHeight

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

    readonly property string fontFamily:
        (root.configEntry.fontFamily && root.configEntry.fontFamily.length > 0)
            ? root.configEntry.fontFamily
            : Appearance.font.family.main

    ColumnLayout {
        id: column
        anchors.centerIn: parent
        spacing: root.configEntry.lineGap ?? 2

        StyledText {
            text: root.configEntry.topText ?? ""
            visible: text.length > 0
            color: root.configEntry.textColor ?? "#ffffff"
            Layout.alignment: root.configEntry.centered ? Qt.AlignHCenter : Qt.AlignLeft
            font {
                family: root.fontFamily
                pixelSize: root.configEntry.topFontSize ?? 24
                letterSpacing: root.configEntry.topLetterSpacing ?? 4
            }
            style: Text.Raised
            styleColor: "#66000000"
        }

        StyledText {
            text: root.configEntry.bottomText ?? ""
            visible: text.length > 0
            color: root.configEntry.textColor ?? "#ffffff"
            Layout.alignment: root.configEntry.centered ? Qt.AlignHCenter : Qt.AlignLeft
            font {
                family: root.fontFamily
                pixelSize: root.configEntry.bottomFontSize ?? 52
                letterSpacing: root.configEntry.bottomLetterSpacing ?? 6
            }
            style: Text.Raised
            styleColor: "#66000000"
        }
    }
}
