-- update.lua  — pulls latest JARVIS code from GitHub
-- Run "wget run https://raw.githubusercontent.com/JustAStickmin/Jarvis-CC/main/update.lua"
-- once to install, then just run "update" anytime to refresh.
--
-- Your local config.lua is NEVER overwritten by this updater.

local repo   = "JustAStickmin/Jarvis-CC"
local branch = "main"

-- Add new filenames here as the project grows
local files = {
    "main.lua",
    "update.lua",
    "labels.lua",
    "config.example.lua",
}

print("[JARVIS] Updating from "..repo.."@"..branch.."...")
local failed = 0
for _, f in ipairs(files) do
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

-- Bootstrap config.lua from the example on first install only
if fs.exists("config.example.lua") and not fs.exists("config.lua") then
    local src = fs.open("config.example.lua", "r")
    local dst = fs.open("config.lua", "w")
    if src and dst then
        dst.write(src.readAll())
        src.close()
        dst.close()
        print("[JARVIS] Created config.lua from config.example.lua.")
        print("[JARVIS] Run 'labels' then 'edit config.lua' to assign monitors.")
    end
end

if failed == 0 then
    print("[JARVIS] Update complete. Run 'main' to launch.")
else
    print("[JARVIS] Update finished with "..failed.." failure(s). Check the URL above is reachable.")
end
