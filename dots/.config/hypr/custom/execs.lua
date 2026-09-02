-- Start the systemd user session target for this graphical session.
--
-- xdg-desktop-portal.service has Requisite=graphical-session.target, and
-- nothing in a plain Hyprland login ever starts that target (Plasma and GNOME
-- start it from their session managers). Without it the portal never launches,
-- which silently breaks:
--   * opening links from Flatpak / Electron apps (OpenURI)
--   * Discord / Vesktop screen sharing (ScreenCast)
--   * global shortcuts in Electron apps (GlobalShortcuts)
--   * portal file pickers
--
-- hyprland-session.target lives in ~/.config/systemd/user/ and BindsTo
-- graphical-session.target, so starting it pulls the whole chain up.
hl.exec_cmd(
    "dbus-update-activation-environment --systemd "
    .. "WAYLAND_DISPLAY XDG_CURRENT_DESKTOP HYPRLAND_INSTANCE_SIGNATURE XDG_SESSION_TYPE "
    .. "&& systemctl --user start hyprland-session.target"
)
