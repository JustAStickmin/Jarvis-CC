-- ═══════════════════════════════════════════════════════
--  JARVIS SATELLITE CONFIG
-- ═══════════════════════════════════════════════════════
--  Edit this on a SATELLITE computer (not the main JARVIS).
--  Each satellite has a role (which animation it runs) and
--  a monitor.
--
--  SETUP:
--    1. Run:  labels                (shows monitor names)
--    2. Run:  edit satelliteconfig.lua
--    3. Set role + monitor below.
--    4. Save (Ctrl+S → Ctrl menu → Exit)
--    5. Run:  satellite
--
--  Note: this file is local to this computer. It is NOT
--  committed to GitHub, and `update` will not overwrite it.
-- ═══════════════════════════════════════════════════════

return {
    -- What this satellite does. Available roles:
    --   "campfire"  — animated campfire (toggle with `jarvis lite`)
    role = "campfire",

    -- Which monitor on this computer to draw on.
    -- Leave nil to auto-find the first monitor.
    -- Run 'labels' to see names like "monitor_0".
    monitor = nil,
}
