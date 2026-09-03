-- ############################################################################
-- Dialogs and popups
-- ############################################################################
-- The stock rules in hyprland/rules.lua float dialogs by matching their TITLE
-- ("Open File", "Save As", "File Upload", ...). That only works for the exact
-- English strings someone thought to list, so anything else -- browser auth
-- popups, "Are you sure?" boxes, app preference windows -- opens tiled, gets
-- shoved into the layout, and never lands on top.
--
-- Hyprland can match the window's own declaration instead of guessing from its
-- title. `modal = true` matches any window the app marked as a modal dialog,
-- which is what almost every popup actually is.

hl.window_rule({ match = { modal = true }, float  = true })
hl.window_rule({ match = { modal = true }, center = true })




-- Portal-provided dialogs (file pickers, "open with", print). Your portal
-- config routes FileChooser to the KDE backend, so these carry that class.
hl.window_rule({ match = { class = "^(org\\.freedesktop\\.impl\\.portal\\.desktop\\..*)$" }, float  = true })
hl.window_rule({ match = { class = "^(org\\.freedesktop\\.impl\\.portal\\.desktop\\..*)$" }, center = true })
hl.window_rule({ match = { class = "^(tf2_linux)$" }, float})

-- Common dialog titles the stock list misses.
local dialog_titles = {
    "^(Open)$",
    "^(Save)$",
    "^(Save File)(.*)$",
    "^(Import)(.*)$",
    "^(Export)(.*)$",
    "^(Preferences)$",
    "^(Settings)$",
    "^(Properties)(.*)$",
    "^(Authentication Required)(.*)$",
    "^(Sign in)(.*)$",
    "^(.*)( - Sign In)$",
    "^(Confirm)(.*)$",
    "^(Warning)(.*)$",
    "^(Error)(.*)$",
    "^(About)( .*)?$",
}
for _, t in ipairs(dialog_titles) do
    hl.window_rule({ match = { title = t }, float  = true })
    hl.window_rule({ match = { title = t }, center = true })
end

-- ############################################################################
-- wallpaperSelector blur
-- ############################################################################
-- The dots blur every quickshell layer, but with `ignore_alpha = 0.79`, meaning
-- anything more transparent than that is left sharp. The wallpaper selector's
-- scrim is deliberately see-through, so it fell under the threshold and the
-- desktop behind it stayed perfectly readable -- the overlay read as leftover
-- window chrome instead of a dimmed backdrop.
--
-- These rules come after the stock ones, so they win for this namespace only.
hl.layer_rule({ match = { namespace = "quickshell:wallpaperSelector" }, blur = true })
hl.layer_rule({ match = { namespace = "quickshell:wallpaperSelector" }, ignore_alpha = 0.05 })

-- ############################################################################
-- Steam notification toasts
-- ############################################################################
-- Steam draws its "friend started a game" toasts as ordinary X11 toplevels
-- with no position hint, so the compositor tiles them wherever the layout
-- happens to put them. Pinning them to a corner and denying focus makes them
-- behave like notifications instead of windows.
local steam_toast = { class = "^(steam)$", title = "^(notificationtoasts_.*)$" }
hl.window_rule({ match = steam_toast, float = true })
hl.window_rule({ match = steam_toast, no_initial_focus = true })
-- move takes a table of two values, not a string, and expressions are written
-- with monitor_w / window_w rather than percentages -- the stock rules in
-- hyprland/rules.lua are the reference. A malformed move is not rejected; the
-- window just lands at the default position, which is what put the toast in
-- the far-left corner.
hl.window_rule({ match = steam_toast,
                 move = { "(monitor_w-window_w-30)", "(monitor_h-window_h-90)" } })
