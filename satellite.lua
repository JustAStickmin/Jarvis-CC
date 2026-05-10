-- satellite.lua  —  Runs on a satellite computer (separate from main JARVIS).
-- Loads config.lua to get its role + monitor, opens all modems for rednet,
-- and runs the animation/program for that role while listening for commands.
--
-- Setup on a satellite computer:
--   1. wget run https://raw.githubusercontent.com/JustAStickmin/Jarvis-CC/main/update.lua
--   2. edit config.lua   -- set role = "campfire" and (if needed) satellite.monitor
--   3. satellite

-- ─── Load config ────────────────────────────────────────
local function loadConfig()
    if not fs.exists("config.lua") then
        print("[SATELLITE] No config.lua. Run 'update' first, then edit config.lua.")
        return nil
    end
    local fn, err = loadfile("config.lua")
    if not fn then print("[SATELLITE] config.lua syntax error: "..tostring(err)) ; return nil end
    local ok, result = pcall(fn)
    if not ok or type(result) ~= "table" then
        print("[SATELLITE] config.lua did not return a table.")
        return nil
    end
    return result
end

local config = loadConfig()
if not config then return end

local role = config.role
if not role or role == "main" then
    print("[SATELLITE] config.lua role is '"..tostring(role).."'.")
    print("[SATELLITE] Set role to a satellite role like \"campfire\" in config.lua.")
    return
end

local satCfg = config.satellite or {}

-- ─── Open all modems ────────────────────────────────────
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

-- ─── Find monitor ───────────────────────────────────────
local mon
if satCfg.monitor then
    mon = peripheral.wrap(satCfg.monitor)
    if not mon then
        print("[SATELLITE] Monitor '"..satCfg.monitor.."' not found. Check config.lua.")
        return
    end
else
    mon = peripheral.find("monitor")
end
if not mon then
    print("[SATELLITE] No monitor connected.")
    print("[SATELLITE] Attach one and run 'labels' to get its peripheral name,")
    print("[SATELLITE] then set satellite.monitor in config.lua.")
    return
end

-- ─── Load the role's animation module ──────────────────
local modulePath = "satellites/"..role..".lua"
if not fs.exists(modulePath) then
    print("[SATELLITE] Animation '"..role.."' not found at "..modulePath..".")
    print("[SATELLITE] Run 'update' to pull it, or check the role name in config.lua.")
    return
end
local ok, mod = pcall(dofile, modulePath)
if not ok or type(mod) ~= "table" then
    print("[SATELLITE] Failed to load "..modulePath..": "..tostring(mod))
    return
end

-- ─── Initialise ────────────────────────────────────────
if mod.init then mod.init(mon, satCfg) end
print("[SATELLITE] Online.")
print("  Role:    "..role)
print("  ID:      "..os.getComputerID())
print("  Module:  "..modulePath)

-- Announce ourselves to JARVIS
rednet.broadcast({type = "hello", role = role, id = os.getComputerID()}, "jarvis")

-- ─── Loops ─────────────────────────────────────────────
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
