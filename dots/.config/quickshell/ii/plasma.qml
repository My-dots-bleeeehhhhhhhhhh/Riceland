pragma ComponentBehavior: Bound

// Background widgets, hosted for KDE Plasma.
//
// modules/ii/background/Background.qml cannot be reused here. It is not the
// layer that stops it -- it already sits on WlrLayer.Bottom, which is exactly
// the layer that wins against plasmashell's desktop view. What stops it is
// everything else it does: it paints the wallpaper itself and parallaxes it
// against the Hyprland workspace, and it reads Hyprland.workspaces,
// HyprlandData.windowList and Hyprland.monitorFor, none of which exist under
// KWin.
//
// So this is the same widgets with a different host: a transparent layer
// surface, no wallpaper of its own (Plasma draws that), no parallax, no
// compositor-specific imports. The widgets themselves needed no changes --
// none of them ever imported Quickshell.Hyprland.
//
// Run with:  qs -p ~/.config/quickshell/ii/plasma.qml

import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.widgets.widgetCanvas
import QtQuick
import Quickshell
import Quickshell.Wayland

import qs.modules.ii.background.widgets.ultrastats
import qs.modules.ii.background.widgets.ultrafetch
import qs.modules.ii.background.widgets.cordfetch
import qs.modules.ii.background.widgets.levelIntro
import qs.modules.ii.background.widgets.serverWatch
import qs.modules.ii.background.widgets.announcements
import qs.modules.ii.background.widgets.audioBars

ShellRoot {
    Variants {
        id: root
        model: Quickshell.screens

        PanelWindow {
            id: bgRoot

            required property var modelData
            screen: modelData

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }
            color: "transparent"

            // Bottom, not Background: KWin honours both, but plasmashell's
            // desktop view covers the background layer and not this one.
            WlrLayershell.layer: WlrLayer.Bottom
            WlrLayershell.namespace: "quickshell:plasma-widgets"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            exclusionMode: ExclusionMode.Ignore

            // Screen-filter helper, so a widget can be pinned to one monitor.
            function onThisScreen(entry) {
                return entry.enable
                    && (entry.screens.length === 0
                        || entry.screens.split(",").map(s => s.trim())
                            .includes(bgRoot.modelData.name));
            }

            Loader {
                anchors.fill: parent
                active: bgRoot.onThisScreen(Config.options.background.audioBars)
                sourceComponent: AudioBars { screenWidth: bgRoot.screen.width }
            }

            WidgetCanvas {
                id: widgetCanvas
                width: parent.width
                height: parent.height

                FadeLoader {
                    shown: bgRoot.onThisScreen(Config.options.background.widgets.announcements)
                    sourceComponent: Announcements {
                        screenName: bgRoot.modelData.name
                        screenWidth: bgRoot.screen.width
                        screenHeight: bgRoot.screen.height
                        scaledScreenWidth: bgRoot.screen.width
                        scaledScreenHeight: bgRoot.screen.height
                        wallpaperScale: 1
                    }
                }

                FadeLoader {
                    shown: bgRoot.onThisScreen(Config.options.background.widgets.serverWatch)
                    sourceComponent: ServerWatch {
                        screenName: bgRoot.modelData.name
                        screenWidth: bgRoot.screen.width
                        screenHeight: bgRoot.screen.height
                        scaledScreenWidth: bgRoot.screen.width
                        scaledScreenHeight: bgRoot.screen.height
                        wallpaperScale: 1
                    }
                }

                FadeLoader {
                    shown: bgRoot.onThisScreen(Config.options.background.widgets.levelIntro)
                    sourceComponent: LevelIntro {
                        screenName: bgRoot.modelData.name
                        screenWidth: bgRoot.screen.width
                        screenHeight: bgRoot.screen.height
                        scaledScreenWidth: bgRoot.screen.width
                        scaledScreenHeight: bgRoot.screen.height
                        wallpaperScale: 1
                    }
                }

                FadeLoader {
                    shown: bgRoot.onThisScreen(Config.options.background.widgets.cordfetch)
                    sourceComponent: CordFetchWidget {
                        screenName: bgRoot.modelData.name
                        screenWidth: bgRoot.screen.width
                        screenHeight: bgRoot.screen.height
                        scaledScreenWidth: bgRoot.screen.width
                        scaledScreenHeight: bgRoot.screen.height
                        wallpaperScale: 1
                    }
                }

                FadeLoader {
                    shown: bgRoot.onThisScreen(Config.options.background.widgets.ultrafetch)
                    sourceComponent: UltraFetchWidget {
                        screenName: bgRoot.modelData.name
                        screenWidth: bgRoot.screen.width
                        screenHeight: bgRoot.screen.height
                        scaledScreenWidth: bgRoot.screen.width
                        scaledScreenHeight: bgRoot.screen.height
                        wallpaperScale: 1
                    }
                }

                FadeLoader {
                    shown: bgRoot.onThisScreen(Config.options.background.widgets.ultrastats)
                    sourceComponent: UltraStatsWidget {
                        screenName: bgRoot.modelData.name
                        screenWidth: bgRoot.screen.width
                        screenHeight: bgRoot.screen.height
                        scaledScreenWidth: bgRoot.screen.width
                        scaledScreenHeight: bgRoot.screen.height
                        wallpaperScale: 1
                    }
                }
            }
        }
    }
}
