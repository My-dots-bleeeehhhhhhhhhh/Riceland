-- Clicking within a few pixels of a window's edge resizes it, with no modifier
-- held. In a game running windowed that reads as the window randomly jumping
-- or resizing when you meant to click in the world -- the pointer is near an
-- edge far more often than on a desktop. SUPER + right-drag still resizes.
hl.config({
    general = {
        resize_on_border = false,
    },
})

-- ############################################################################
-- Keybinds inside apps that grab the keyboard
-- ############################################################################
-- X11 apps (Minecraft and most games, via XWayland) can take an exclusive
-- keyboard grab. Hyprland honours that by default, so SUPER never reaches the
-- compositor and nothing you press does anything -- which is why the shell
-- would not open and the cursor stayed captured. With this on, Hyprland's own
-- binds are processed first and the grab only gets what is left.
hl.config({
    binds = {
        disable_keybind_grabbing = true,
    },
})
