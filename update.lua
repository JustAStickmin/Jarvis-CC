-- update.lua  — pulls latest JARVIS code from GitHub
-- Run "wget run https://raw.githubusercontent.com/JustAStickmin/Jarvis-CC/main/update.lua"
-- once to install, then just run "update" anytime to refresh.
--
-- Your local config.lua and satelliteconfig.lua are NEVER overwritten.

local repo   = "JustAStickmin/Jarvis-CC"
local branch = "main"

-- Add new filenames here as the project grows.
-- Subdirectories (e.g. "satellites/foo.lua") are auto-created.
local files = {
    "main.lua",
    "update.lua",
    "labels.lua",
    "config.example.lua",
    "satelliteconfig.example.lua",
    "satellite.lua",
    "satellites/campfire.lua",
}

print("[JARVIS] Updating from "..repo.."@"..branch.."...")
local failed = 0
for _, f in ipairs(files) do
    local dir = fs.getDir(f)
    if dir ~= "" and not fs.exists(dir) then
        fs.makeDir(dir)
    end
    if fs.exists(f) then fs.delete(f) end
    local url = "https://raw.githubusercontent.com/"..repo.."/"..branch.."/"..f
    local ok = shell.run("wget", url, f)
    if ok then
        print("  [OK]    "..f)
    else
        print("  [FAIL]  "..f)
        failed = failed + 1
    end
end

-- Bootstrap configs from their examples on first install only.
local function bootstrap(example, target)
    if fs.exists(example) and not fs.exists(target) then
        local src = fs.open(example, "r")
        local dst = fs.open(target, "w")
        if src and dst then
            dst.write(src.readAll())
            src.close() ; dst.close()
            print("[JARVIS] Created "..target.." from "..example..".")
            return true
        end
    end
    return false
end

local madeMain = bootstrap("config.example.lua",          "config.lua")
local madeSat  = bootstrap("satelliteconfig.example.lua", "satelliteconfig.lua")
if madeMain or madeSat then
    print("[JARVIS] Edit your configs to assign monitors / roles, then run:")
    print("  Main computer       : main")
    print("  Satellite computer  : satellite")
end

if failed == 0 then
    print("[JARVIS] Update complete.")
else
    print("[JARVIS] Update finished with "..failed.." failure(s). Check the URL is reachable.")
end
