-- update.lua  — pulls latest JARVIS code from GitHub
-- Run "wget run https://raw.githubusercontent.com/JustAStickmin/Jarvis-CC/main/update.lua"
-- once to install, then just run "update" anytime to refresh.

local repo   = "JustAStickmin/Jarvis-CC"
local branch = "main"

-- Add new filenames here as the project grows
local files = {
    "main.lua",
    "update.lua",
}

print("[JARVIS] Updating from "..repo.."@"..branch.."...")
for _, f in ipairs(files) do
    if fs.exists(f) then fs.delete(f) end
    local url = "https://raw.githubusercontent.com/"..repo.."/"..branch.."/"..f
    local ok = shell.run("wget", url, f)
    if ok then
        print("  [OK]    "..f)
    else
        print("  [FAIL]  "..f)
    end
end
print("[JARVIS] Update complete. Run 'main' to launch.")
