-- ═══════════════════════════════════════════════════════
--  JARVIS CONFIGURATION
-- ═══════════════════════════════════════════════════════
--  This file tells a JARVIS computer what role it plays
--  (main vs satellite) and which peripherals to use.
--  It is loaded automatically at startup by main.lua and
--  satellite.lua.
--
--  ─── ROLES ────────────────────────────────────────────
--    "main"     : the main JARVIS computer. Uses the
--                 monitors / chatBox / meBridge / speaker
--                 fields below. Run with:  main
--    "campfire" : a satellite running the campfire
--                 animation. Uses the satellite section.
--                 Run with:  satellite
--    <future>   : add new satellite roles by dropping a
--                 satellites/<role>.lua module in the repo
--                 and setting role = "<role>" here.
--
--  ─── HOW TO SET UP A MAIN COMPUTER ────────────────────
--    1. role = "main" (already the default)
--    2. Run:  labels        (each monitor shows its name)
--    3. Run:  edit config.lua
--       Fill in the monitor names below.
--    4. Run:  main
--
--  ─── HOW TO SET UP A SATELLITE COMPUTER ──────────────
--    1. Place a separate computer with an ender modem and
--       a monitor on it.
--    2. wget run https://raw.githubusercontent.com/JustAStickmin/Jarvis-CC/main/update.lua
--    3. edit config.lua
--       Set  role = "campfire"  (or whatever satellite role)
--       Set  satellite.monitor = "<name>" if not auto-detected.
--    4. Run:  satellite
--
--  ─── NOTES ────────────────────────────────────────────
--    • config.lua is local to THIS computer and is NOT
--      committed to GitHub (it's in .gitignore). Each
--      computer keeps its own setup.
--    • Running `update` does NOT overwrite config.lua.
-- ═══════════════════════════════════════════════════════

return {
    -- ─── ROLE ───────────────────────────────────────────
    role = "main",

    -- ─── MAIN COMPUTER SETTINGS (used when role == "main") ───
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

    --  Set these only if you have multiple of the same kind
    --  on the network. Otherwise leave nil for auto-detect.
    chatBox  = nil,  -- e.g. "chatBox_0"
    meBridge = nil,  -- e.g. "meBridge_2"
    speaker  = nil,  -- e.g. "speaker_1"

    -- ─── SATELLITE SETTINGS (used when role != "main") ───
    satellite = {
        --  Which monitor on this satellite computer to draw on.
        --  Run 'labels' to see the names. Leave nil for auto-detect.
        monitor = nil,  -- e.g. "monitor_0", "back"
    },
}
