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
