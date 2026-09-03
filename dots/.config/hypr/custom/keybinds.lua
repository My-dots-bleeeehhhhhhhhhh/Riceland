hl.bind("CTRL+SUPER+ALT+Slash", hl.dsp.exec_cmd("xdg-open ~/.config/hypr/custom/keybinds.lua"), { description = "Edit user keybinds" })
hl.bind("SUPER+mouse:276", hl.dsp.window.float({ action = "toggle" }), { mouse = true, description = "Window: Float/Tile (forward mouse button)" })

-- ############################################################################
-- Closing windows
-- ############################################################################
-- Stock dots bind these three ways:
--   SUPER + Q                 -> close (graceful)
--   SUPER + SHIFT + ALT + Q   -> `hyprctl kill`, a crosshair click-to-kill mode
--   ALT + F4                  -> a notification nagging you to use SUPER + Q
--                                (non_consuming, so the app still got Alt+F4 --
--                                deliberate, for Windows VMs and Wine)
--
-- Replaced with:
--   SUPER + C  -> close       graceful. Asks the app to close; you get save
--                             prompts, and only this window goes away.
--   ALT + F4   -> kill        forcekillactive. SIGKILLs the process, so every
--                             window that app owns dies with it and nothing is
--                             saved. This is the "zap", not a polite close.
--
-- SUPER + Q is left alone, so the old muscle memory still works.

hl.unbind("SUPER + C")   -- was: code editor (moved to SUPER + ALT + C below)
hl.unbind("ALT + F4")    -- was: the "wrong close keybind" notification

hl.bind("SUPER + C", hl.dsp.window.close(), { description = "Window: Close" })
hl.bind("ALT + F4", hl.dsp.window.kill(), { description = "Window: Force kill (zap)" })

-- Code editor, rehomed off SUPER + C. `codeEditor` is a global set in
-- hyprland/variables.lua, so it still picks the first editor you have installed.
hl.bind("SUPER + ALT + C", hl.dsp.exec_cmd(codeEditor), { description = "App: Code editor" })

-- ############################################################################
-- CTRL + SUPER + T fired twice
-- ############################################################################
-- The dots bind this key in two places:
--   hyprland/keybinds.lua:49  hl.dsp.global("quickshell:wallpaperSelectorToggle")
--   hyprland/keybinds.lua:55  exec_cmd("<is qs alive?> || .../colors/switchwall.sh")
--
-- Hyprland runs BOTH matching binds. Line 55 is only meant as a fallback for
-- when the shell is dead, but whenever its alive check misses -- during a shell
-- restart, or just under load -- switchwall.sh runs with no arguments, and that
-- path ends at `kdialog --getopenfilename`: the KDE file picker, opening on top
-- of the Quickshell selector. Keep only the shell's own selector.
--
-- Trade-off: if Quickshell is genuinely dead this key now does nothing. That is
-- fine -- a dead shell means no bar either, and CTRL + SUPER + R restarts it.
hl.unbind("CTRL + SUPER + T")
hl.bind("CTRL + SUPER + T", hl.dsp.global("quickshell:wallpaperSelectorToggle"),
    { description = "Shell: Change wallpaper" })

-- ############################################################################
-- Print = snip
-- ############################################################################
-- Stock binds Print to a whole-screen grab straight to the clipboard, so it
-- never opened the region selector. Snip is the common case; the full grab
-- moves to SHIFT + Print.
hl.unbind("Print")
hl.bind("Print", hl.dsp.global("quickshell:regionScreenshot"),
    { locked = true, description = "Utilities: Screen snip" })
hl.bind("Print", hl.dsp.exec_cmd(
    "pidof qs || pidof slurp || hyprshot --freeze --clipboard-only --mode region --silent"),
    { locked = true })
hl.bind("SHIFT + Print", hl.dsp.exec_cmd(
    "grim -o \"$(hyprctl activeworkspace -j | jq -r '.monitor')\" - | wl-copy"),
    { locked = true, description = "Utilities: Screenshot (whole screen) >> clipboard" })

-- ############################################################################
-- Release a captured cursor
-- ############################################################################
-- Games hold the pointer with a Wayland pointer constraint (or an X11 grab).
-- Hyprland has a dispatcher for handing it back; without a bind on it there is
-- no way to get the cursor out short of killing focus some other way.
hl.bind("SUPER + Escape", hl.dsp.release_input_capture(),
    { locked = true, description = "Input: Release captured cursor" })
