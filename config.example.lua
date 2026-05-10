-- ═══════════════════════════════════════════════════════
--  JARVIS CONFIGURATION
-- ═══════════════════════════════════════════════════════
--  This file tells JARVIS which peripherals fill which roles.
--  It is loaded automatically at startup.
--
--  ─── HOW TO SET UP ────────────────────────────────────
--    1. Hook up all your peripherals to the computer.
--    2. In the CC terminal, run:   labels
--       Every monitor will display its peripheral name
--       (like "monitor_0", "monitor_3", etc.).
--    3. Walk around your base and note which physical
--       monitor shows which name.
--    4. Run:   edit config.lua
--       Replace each `nil` below with the peripheral name
--       in quotes, like:   helpMon = "monitor_3",
--       Save with Ctrl + S, exit with Ctrl menu → Exit.
--    5. Run:   main
--       JARVIS launches with your assignments.
--
--  ─── NOTES ────────────────────────────────────────────
--    • config.lua is local to THIS computer. It is NOT
--      committed to GitHub (it's in .gitignore), so each
--      computer keeps its own setup.
--    • Running `update` does NOT overwrite your config.lua.
--    • Any value left as nil will be auto-detected by
--      JARVIS where possible (monitors by aspect ratio,
--      single peripherals by their type name).
-- ═══════════════════════════════════════════════════════

return {
    -- ─── MONITORS ───────────────────────────────────────
    --  Suggested size │ Role
    monitors = {
        helpMon   = nil,  -- 4x5 squarish   : commands list
        faceMon   = nil,  -- 4x4 squarish   : JARVIS HUD with rings
        energyMon = nil,  -- 3x3 squarish   : AE2 energy bar
        lightsMon = nil,  -- 1x1 squarish   : lights status
        stoMon    = nil,  -- 2x6 portrait   : AE2 storage bar
        lastMon   = nil,  -- 1x3 portrait   : last response
        clockMon  = nil,  -- 2x1 very wide  : clock
    },

    -- ─── OTHER PERIPHERALS ──────────────────────────────
    --  Only set these if you have multiple of the same kind
    --  on the network and need to pick a specific one.
    --  Otherwise leave as nil and JARVIS finds them itself.
    chatBox  = nil,  -- e.g. "chatBox_0"
    meBridge = nil,  -- e.g. "meBridge_2"
    speaker  = nil,  -- e.g. "speaker_1"
}
