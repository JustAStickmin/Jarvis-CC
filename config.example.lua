-- ═══════════════════════════════════════════════════════
--  JARVIS CONFIG  (main computer)
-- ═══════════════════════════════════════════════════════
--  Tells JARVIS which monitor is for what.
--
--  SETUP:
--    1. Run:  labels         (each monitor displays its name)
--    2. Run:  edit config.lua
--    3. Replace each nil with the name in quotes, e.g.:
--         helpMon = "monitor_3",
--    4. Save (Ctrl+S → Ctrl menu → Exit)
--    5. Run:  main
--
--  Note: this file is local to this computer. It is NOT
--  committed to GitHub, and `update` will not overwrite it.
-- ═══════════════════════════════════════════════════════

return {
    monitors = {
        helpMon   = nil,   -- 4x5  : commands list
        faceMon   = nil,   -- 4x4  : JARVIS HUD with rings
        energyMon = nil,   -- 3x3  : AE2 energy bar
        lightsMon = nil,   -- 1x1  : lights status
        stoMon    = nil,   -- 2x6  : AE2 storage bar (tall)
        lastMon   = nil,   -- 1x3  : last response (tall)
        clockMon  = nil,   -- 2x1  : clock (wide)
    },

    -- Advanced — only set these if you have multiple of the
    -- same kind on the network. Otherwise leave commented out.
    -- chatBox  = "chatBox_0",
    -- meBridge = "meBridge_0",
    -- speaker  = "speaker_0",
}
