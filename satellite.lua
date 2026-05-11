-- satellite.lua  —  Runs on a satellite computer (separate from main JARVIS).
-- Reads satelliteconfig.txt for its role + monitor, opens all modems for
-- rednet, and runs the per-role animation while listening for commands.
--
-- First run with no satelliteconfig.txt → autogenerates one with
-- role="campfire" and the first detected monitor.
--
-- Setup on a satellite computer:
--   1. wget run https://raw.githubusercontent.com/JustAStickmin/Jarvis-CC/main/update.lua
--   2. satellite                          (creates satelliteconfig.txt)
--   3. edit satelliteconfig.txt           (change role/monitor if needed)
--   4. satellite                          (launch)

local cfgio = dofile("cfgio.lua")

-- ─── Autogen satelliteconfig.txt if missing ─────────────
local function autogenSatelliteConfig()
    print("[SATELLITE] No satelliteconfig.txt — detecting monitor...")
    local mons = cfgio.detectMonitors()
    local first = mons[1]
    local nameStr = first and first.name  or "monitor_x"
    local sizeStr = first and (first.bw.."x"..first.bh) or "3x3"

    local content = "# JARVIS SATELLITE CONFIG\n"
                 .. "# Format:  role: peripheralName, WxH\n"
                 .. "#\n"
                 .. "# Available roles: campfire\n"
                 .. "# Run 'labels' to verify the monitor name.\n"
                 .. "# Edit, save (Ctrl+S -> Exit), run 'satellite'.\n"
                 .. "# Delete this file and re-run to regenerate.\n"
                 .. "\n"
                 .. "-- Monitors (satellites) --\n"
                 .. string.format("%-9s %s, %s\n", "campfire:", nameStr, sizeStr)

    cfgio.writeFile("satelliteconfig.txt", content)
    print("[SATELLITE] Created satelliteconfig.txt with "..#mons.." monitor(s) detected.")
end

if not fs.exists("satelliteconfig.txt") then
    autogenSatelliteConfig()
end

-- ─── Parse config ──────────────────────────────────────
local entries = cfgio.parseFile("satelliteconfig.txt") or {}

-- A satellite has exactly one role; take the first entry under any section.
local entry = entries[1]
if not entry then
    print("[SATELLITE] No role entry in satelliteconfig.txt.")
    print("[SATELLITE] Edit it and add e.g.   campfire: monitor_0, 3x3")
    return
end

local role = entry.role
local monitorName = entry.name

-- ─── Open all modems ───────────────────────────────────
local opened = {}
for _, name in ipairs(peripheral.getNames()) do
    if peripheral.getType(name) == "modem" then
        rednet.open(name)
        table.insert(opened, name)
    end
end
if #opened == 0 then
    print("[SATELLITE] No modem found. Attach an ender modem.")
    return
end
print("[SATELLITE] Opened modem(s): "..table.concat(opened, ", "))

-- ─── Find monitor ──────────────────────────────────────
local mon
if monitorName then
    mon = peripheral.wrap(monitorName)
    if not mon then
        print("[SATELLITE] Monitor '"..monitorName.."' not found.")
        print("[SATELLITE] Run 'labels' and edit satelliteconfig.txt.")
        return
    end
else
    mon = peripheral.find("monitor")
end
if not mon then
    print("[SATELLITE] No monitor connected.")
    return
end

-- ─── Load the role's animation module ──────────────────
local modulePath = "satellites/"..role..".lua"
if not fs.exists(modulePath) then
    print("[SATELLITE] Animation '"..role.."' not found at "..modulePath..".")
    print("[SATELLITE] Run 'update' to pull it, or check the role name.")
    return
end
local ok, mod = pcall(dofile, modulePath)
if not ok or type(mod) ~= "table" then
    print("[SATELLITE] Failed to load "..modulePath..": "..tostring(mod))
    return
end

-- ─── Initialise ───────────────────────────────────────
if mod.init then mod.init(mon, entry) end
print("[SATELLITE] Online.")
print("  Role:    "..role)
print("  Monitor: "..tostring(monitorName or "(auto)"))
print("  ID:      "..os.getComputerID())

rednet.broadcast({type = "hello", role = role, id = os.getComputerID()}, "jarvis")

-- ─── Loops ────────────────────────────────────────────
local running = true

local function listenLoop()
    while running do
        local id, msg = rednet.receive("jarvis")
        if type(msg) == "table" then
            if msg.target == role or msg.target == "all" then
                if     msg.cmd == "toggle" and mod.toggle then mod.toggle()
                elseif msg.cmd == "on"     and mod.setOn  then mod.setOn()
                elseif msg.cmd == "off"    and mod.setOff then mod.setOff()
                elseif msg.cmd == "ping" then
                    rednet.send(id, {type = "pong", role = role, id = os.getComputerID()}, "jarvis")
                elseif mod.handleCommand then
                    mod.handleCommand(msg, id)
                end
            end
        end
    end
end

local function animLoop()
    local fps = mod.fps or 8
    local dt  = 1 / fps
    while running do
        if mod.draw then
            local ok, err = pcall(mod.draw)
            if not ok then print("[SATELLITE] draw error: "..tostring(err)) end
        end
        sleep(dt)
    end
end

parallel.waitForAny(listenLoop, animLoop)
