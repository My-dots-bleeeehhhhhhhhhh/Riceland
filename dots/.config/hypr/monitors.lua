-- Monitor layout, sourced by hyprland.lua (the nwg-displays hook).
-- Lives outside custom/ but is equally safe from `./setup install`.
--
-- Mirrors the arrangement from Plasma:
--   left   HDMI-A-2  ES-G27F2      1080p @165
--   centre DP-5      LG ULTRAGEAR  1440p @144, unscaled
--   right  DP-4      DELL S2522HG  1080p @240
--
-- Positions are LOGICAL pixels. DP-5 runs unscaled, so it occupies its full
-- 2560x1440 and the right monitor starts at 1920 + 2560 = 4480.
--
-- The y offset of 360 on the side monitors is 1440 - 1080: it lines their
-- bottom edges up with the taller centre screen, so the mouse crosses
-- between them without a vertical jump.

hl.monitor({
    output = "HDMI-A-2",
    mode = "1920x1080@165",
    position = "0x360",
    scale = 1
})

hl.monitor({
    output = "DP-5",
    mode = "2560x1440@143.97",
    position = "1920x0",
    scale = 1
})

-- Was running at 60Hz on autodetect; this panel does 239.76.
hl.monitor({
    output = "DP-4",
    mode = "1920x1080@239.76",
    position = "4480x360",
    scale = 1
})
