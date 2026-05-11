-- cfgio.lua  —  Parse & write JARVIS config.txt files.
--
-- Format:
--     # comment lines start with hash
--     -- Section Name --              (section header)
--     role: peripheralName, WxH       (entry — size optional)
--     role: auto                      (entry — leave for auto-detect)
--
-- Both main.lua and satellite.lua dofile this module.
-- Returns the module table.

local M = {}

-- Parse a config.txt string. Returns an ordered list of entries:
--   { {role="face", name="monitor_3", w=4, h=4, section="Monitors (main)"}, ... }
function M.parse(text)
    local entries = {}
    local currentSection = nil
    for line in (text or ""):gmatch("[^\r\n]+") do
        -- Strip inline comments
        local hashPos = line:find("#")
        if hashPos then line = line:sub(1, hashPos - 1) end
        line = line:gsub("^%s+", ""):gsub("%s+$", "")

        if line ~= "" then
            local section = line:match("^%-%-%s*(.-)%s*%-%-$")
            if section then
                currentSection = section
            else
                local key, value = line:match("^([%w_]+)%s*:%s*(.+)$")
                if key then
                    local parts = {}
                    for p in value:gmatch("[^,]+") do
                        -- Parens discard gsub's second return (count); without
                        -- them table.insert treats it as a position arg and errors.
                        table.insert(parts, (p:gsub("^%s+", ""):gsub("%s+$", "")))
                    end
                    local entry = {role = key:lower(), section = currentSection}
                    entry.name = parts[1]
                    if not entry.name or entry.name == ""
                       or entry.name:lower() == "auto"
                       or entry.name == "-"
                       or entry.name:lower() == "nil" then
                        entry.name = nil
                    end
                    if parts[2] then
                        local sizeStr = parts[2]:gsub("^size%s+", "")
                        local w, h = sizeStr:match("(%d+)%s*x%s*(%d+)")
                        if w and h then
                            entry.w = tonumber(w)
                            entry.h = tonumber(h)
                        end
                    end
                    table.insert(entries, entry)
                end
            end
        end
    end
    return entries
end

-- Find the first entry for a role (case-insensitive).
function M.findEntry(entries, role)
    role = role:lower()
    for _, e in ipairs(entries) do
        if e.role == role then return e end
    end
    return nil
end

-- Read + parse a file in one call. Returns nil if file doesn't exist.
function M.parseFile(path)
    if not fs.exists(path) then return nil end
    local f = fs.open(path, "r")
    if not f then return nil end
    local content = f.readAll()
    f.close()
    return M.parse(content)
end

-- Write a string to a file.
function M.writeFile(path, content)
    local f = fs.open(path, "w")
    if not f then return false end
    f.write(content)
    f.close()
    return true
end

-- Compute a monitor's block size (in physical Minecraft blocks).
-- CC: Tweaked at scale=1, charW = blockW*8 - 1, charH = blockH*6 - 1
-- (so a 4x4 block monitor has 31x23 chars at scale 1).
function M.blockSize(monitor)
    monitor.setTextScale(1)
    local cw, ch = monitor.getSize()
    if cw == 0 or ch == 0 then return 0, 0 end
    local bw = math.floor((cw + 1) / 8 + 0.5)
    local bh = math.floor((ch + 1) / 6 + 0.5)
    return bw, bh
end

-- Detect all monitors on the network. Returns a list of
--   { {name="monitor_0", cw=31, ch=23, bw=4, bh=4}, ... }
-- Sleeps 0.5s so setTextScale takes effect before getSize.
function M.detectMonitors()
    -- Pass 1: set scale 1 on every monitor
    for _, name in ipairs(peripheral.getNames()) do
        if peripheral.getType(name) == "monitor" then
            peripheral.wrap(name).setTextScale(1)
        end
    end
    sleep(0.5)
    -- Pass 2: read sizes
    local mons = {}
    for _, name in ipairs(peripheral.getNames()) do
        if peripheral.getType(name) == "monitor" then
            local m = peripheral.wrap(name)
            local cw, ch = m.getSize()
            local bw = math.floor((cw + 1) / 8 + 0.5)
            local bh = math.floor((ch + 1) / 6 + 0.5)
            table.insert(mons, {name = name, cw = cw, ch = ch, bw = bw, bh = bh})
        end
    end
    return mons
end

return M
