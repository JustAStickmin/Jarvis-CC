-- labels.lua  —  Identify which monitor is which.
-- Displays each monitor's peripheral name ON the monitor,
-- so you can walk around and match physical → name → role.
-- Press any key to clear the labels and exit.

local labeled = {}
print("[JARVIS] Labeling monitors...")

for _, name in ipairs(peripheral.getNames()) do
    if peripheral.getType(name) == "monitor" then
        local m = peripheral.wrap(name)
        m.setTextScale(1)
        m.setBackgroundColor(colors.black)
        m.clear()
        local w, h = m.getSize()
        local mid = math.max(1, math.floor(h / 2))

        -- "[ JARVIS ]" header above the name (if there's room)
        if h >= 3 then
            local hint = "[ JARVIS ]"
            local hx = math.max(1, math.floor((w - #hint) / 2) + 1)
            m.setTextColor(colors.cyan)
            m.setCursorPos(hx, mid - 1)
            m.write(hint)
        end

        -- Peripheral name (the actual label)
        local label = name
        local lx = math.max(1, math.floor((w - #label) / 2) + 1)
        m.setTextColor(colors.yellow)
        m.setCursorPos(lx, mid)
        m.write(label)

        -- Size below (helps you pick the right role for it)
        if h >= 4 then
            local size = w.."x"..h
            local sx = math.max(1, math.floor((w - #size) / 2) + 1)
            m.setTextColor(colors.gray)
            m.setCursorPos(sx, mid + 1)
            m.write(size)
        end

        table.insert(labeled, name.." ("..w.."x"..h..")")
        print("  "..name.."  "..w.."x"..h)
    end
end

if #labeled == 0 then
    print("[JARVIS] No monitors found on the network.")
    print("[JARVIS] Make sure modems are wired and activated (right-click).")
    return
end

print("")
print("[JARVIS] "..#labeled.." monitor(s) labeled.")
print("Walk around and note which monitor shows which name.")
print("Then: edit config.lua")
print("Press any key to clear and exit...")

os.pullEvent("key")

-- Clear all monitors
for _, name in ipairs(peripheral.getNames()) do
    if peripheral.getType(name) == "monitor" then
        local m = peripheral.wrap(name)
        m.setBackgroundColor(colors.black)
        m.clear()
    end
end
print("[JARVIS] Cleared.")
