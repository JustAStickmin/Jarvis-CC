-- JARVIS - CC: Tweaked AI Assistant
-- Peripherals: chatBox, meBridge, redstoneIntegrator x N, speaker, 7 monitors

-- ═══════════════════════════════════════════════════════
--  CONFIG
--  Loads peripheral assignments from config.txt.
--  Auto-generates the file on first run by detecting
--  monitors and assigning them by aspect ratio.
--  Edit config.txt to customize. Delete it to regenerate.
-- ═══════════════════════════════════════════════════════
local cfgio = dofile("cfgio.lua")

local function autogenMainConfig()
    print("[JARVIS] No config.txt — detecting monitors to generate one...")
    local mons = cfgio.detectMonitors()
    local portrait, veryWide, squarish = {}, {}, {}
    for _, r in ipairs(mons) do
        if     r.ch >= r.cw * 1.5 then table.insert(portrait, r)
        elseif r.cw >= r.ch * 2   then table.insert(veryWide, r)
        else                           table.insert(squarish, r)
        end
    end
    -- Sub-bucket squarish by orientation so 5x4 (wider, face/help) and
    -- 4x5 (taller) don't fight over the same slot.
    local tallSq, wideSq, evenSq = {}, {}, {}
    for _, r in ipairs(squarish) do
        if     r.ch > r.cw then table.insert(tallSq, r)
        elseif r.cw > r.ch then table.insert(wideSq, r)
        else                    table.insert(evenSq, r)
        end
    end
    local function byAreaDesc(a, b) return a.cw*a.ch > b.cw*b.ch end
    local function byAreaAsc(a, b)  return a.cw*a.ch < b.cw*b.ch end
    table.sort(portrait, byAreaDesc)
    table.sort(veryWide, byAreaDesc)
    table.sort(tallSq,   byAreaDesc)
    table.sort(wideSq,   byAreaDesc)
    table.sort(evenSq,   byAreaDesc)

    local function take(t) return table.remove(t, 1) end

    -- help & face want wider squarish (5x4). Take the two largest.
    local helpMon = take(wideSq) or take(tallSq) or take(evenSq)
    local faceMon = take(wideSq) or take(tallSq) or take(evenSq)
    -- energy wants smallest wider squarish (3x2). Re-sort ascending.
    table.sort(wideSq, byAreaAsc)
    local energyMon = take(wideSq) or take(evenSq) or take(tallSq)
    -- lights wants smallest even squarish (1x1).
    table.sort(evenSq, byAreaAsc)
    local lightsMon = take(evenSq) or take(wideSq) or take(tallSq)
    -- storage = portrait. clock & last = very wide (both 4x1, same shape —
    -- autogen guesses, user swaps in config.txt if needed).
    local storageMon = take(portrait)
    local clockMon   = take(veryWide)
    local lastMon    = take(veryWide) or take(portrait)

    local function fmt(role, detected, defaultSize)
        local name = detected and detected.name or "monitor_x"
        local size = detected and (detected.bw.."x"..detected.bh) or defaultSize
        return string.format("%-9s %s, %s", role..":", name, size)
    end

    local content = "# JARVIS CONFIG  (Main Computer)\n"
                 .. "# Format:  role: peripheralName, WxH\n"
                 .. "#\n"
                 .. "# Run 'labels' to see each monitor's peripheralName.\n"
                 .. "# Edit lines below, save (Ctrl+S -> Exit), run 'main'.\n"
                 .. "# Delete this file and re-run 'main' to regenerate.\n"
                 .. "#\n"
                 .. "# When two monitors are the same shape (e.g. clock and\n"
                 .. "# last are both 4x1), autogen may assign them backwards.\n"
                 .. "# Run 'labels' to check, then swap the names if needed.\n"
                 .. "\n"
                 .. "-- Monitors (main) --\n"
                 .. fmt("help",    helpMon,    "5x4") .. "\n"
                 .. fmt("face",    faceMon,    "5x4") .. "\n"
                 .. fmt("energy",  energyMon,  "3x2") .. "\n"
                 .. fmt("lights",  lightsMon,  "1x1") .. "\n"
                 .. fmt("storage", storageMon, "1x4") .. "\n"
                 .. fmt("last",    lastMon,    "4x1") .. "\n"
                 .. fmt("clock",   clockMon,   "4x1") .. "\n"
                 .. "\n"
                 .. "-- Peripherals --\n"
                 .. "chatBox:  auto\n"
                 .. "meBridge: auto\n"
                 .. "speaker:  auto\n"

    -- Detect redstone integrators in network order so we can pre-fill.
    local ris = {}
    for _, name in ipairs(peripheral.getNames()) do
        if peripheral.getType(name) == "redstoneIntegrator" then
            table.insert(ris, name)
        end
    end
    -- Scroller is a separate peripheral (CC:Create Bridge "scroller pane",
    -- or any peripheral whose type contains "scroll").
    local scrollerCandidate = nil
    for _, name in ipairs(peripheral.getNames()) do
        local t = peripheral.getType(name) or ""
        if t:lower():find("scroll", 1, true) then
            scrollerCandidate = name
            break
        end
    end
    local rsLight  = ris[1] or "auto"
    local rsTalk   = ris[2] or "auto"
    local rsScroll = scrollerCandidate or "auto"

    content = content
        .. "\n"
        .. "-- Redstone --\n"
        .. "# light  : redstone integrator that drives the lights (ON/OFF output).\n"
        .. "# talk   : redstone integrator pulsed HIGH while JARVIS speaks.\n"
        .. "light:   "..rsLight.."\n"
        .. "talk:    "..rsTalk.."\n"
        .. "\n"
        .. "-- Inputs --\n"
        .. "# scroll : the scroller pane peripheral (CC:Create Bridge), or any\n"
        .. "#          peripheral that exposes a 0-15 value. JARVIS uses it to\n"
        .. "#          pick which help page is shown (0 = command list).\n"
        .. "#          If your scroller emits a wider range (0-100, 0-255),\n"
        .. "#          values are clamped to 0-15.\n"
        .. "scroll:  "..rsScroll.."\n"

    cfgio.writeFile("config.txt", content)
    print("[JARVIS] Created config.txt with "..#mons.." monitor(s) and "..#ris.." integrator(s) detected.")
end

if not fs.exists("config.txt") then
    autogenMainConfig()
end

local entries = cfgio.parseFile("config.txt") or {}
local function find(role)
    local e = cfgio.findEntry(entries, role)
    return e and e.name or nil
end

-- Monitor role assignments (nil → auto-detect by aspect ratio)
local CFG_HELP    = find("help")     -- 5x4 commands list           (wider squarish)
local CFG_FACE    = find("face")     -- 5x4 JARVIS HUD              (wider squarish)
local CFG_STO     = find("storage")  -- 1x4 AE2 storage bar         (portrait)
local CFG_ENERGY  = find("energy")   -- 3x2 AE2 energy bar          (wider squarish)
local CFG_LAST    = find("last")     -- 4x1 last response           (very wide)
local CFG_CLOCK   = find("clock")    -- 4x1 clock                   (very wide)
local CFG_LIGHTS  = find("lights")   -- 1x1 lights status           (even squarish)

-- Single-instance peripherals (config can override; otherwise auto-find)
local chatBoxName  = find("chatBox")
local meBridgeName = find("meBridge")
local speakerName  = find("speaker")
local box    = chatBoxName  and peripheral.wrap(chatBoxName)  or peripheral.find("chatBox")
local bridge = meBridgeName and peripheral.wrap(meBridgeName) or peripheral.find("meBridge")
local spk    = speakerName  and peripheral.wrap(speakerName)  or peripheral.find("speaker")

-- Redstone integrators (each role is its own integrator).
local lightsRIName   = find("light")    -- lights on/off
local talkRIName     = find("talk")     -- ON while speaking
local scrollerRIName = find("scroll")   -- analog 0-15 input picks help page
local lightsRI       = lightsRIName   and peripheral.wrap(lightsRIName)
local talkRI         = talkRIName     and peripheral.wrap(talkRIName)
local scrollerRI     = scrollerRIName and peripheral.wrap(scrollerRIName)

-- ─── Config diagnostics ──────────────────────────────
-- Print what the config file actually contains so the user can verify
-- it's being read, and warn loudly if any peripheral name doesn't exist.
if #entries > 0 then
    print("[JARVIS] Loaded config.txt ("..#entries.." entries):")
    for _, e in ipairs(entries) do
        local sizeStr = (e.w and e.h) and ("  ("..e.w.."x"..e.h..")") or ""
        local nameStr = e.name or "(auto-detect)"
        print(string.format("  %-9s -> %s%s", e.role, nameStr, sizeStr))
    end
else
    print("[JARVIS] config.txt is empty or unreadable. All roles will auto-detect.")
end

-- Verify each configured name actually exists on the network
local function verifyName(role, name)
    if not name then return end
    if not peripheral.wrap(name) then
        print("[JARVIS] WARNING: \""..name.."\" (for "..role..") is not a real peripheral.")
        print("[JARVIS]          Run 'labels' to see real names, then edit config.txt.")
        print("[JARVIS]          Falling back to auto-detect for this role.")
    end
end
verifyName("help",     CFG_HELP)
verifyName("face",     CFG_FACE)
verifyName("storage",  CFG_STO)
verifyName("energy",   CFG_ENERGY)
verifyName("last",     CFG_LAST)
verifyName("clock",    CFG_CLOCK)
verifyName("lights",   CFG_LIGHTS)
verifyName("chatBox",  chatBoxName)
verifyName("meBridge", meBridgeName)
verifyName("speaker",  speakerName)
verifyName("light",    lightsRIName)
verifyName("talk",     talkRIName)
verifyName("scroll",   scrollerRIName)

-- ═══════════════════════════════════════════════════════
--  SATELLITE COMMS
--  Open every modem on the computer and listen on the
--  "jarvis" rednet protocol. Satellites announce themselves
--  with a "hello" message containing their role + ID.
-- ═══════════════════════════════════════════════════════
for _, name in ipairs(peripheral.getNames()) do
    if peripheral.getType(name) == "modem" then
        rednet.open(name)
    end
end

-- ─────────────────────────────────────────────
--  Response tables
-- ─────────────────────────────────────────────

local greetings = {
    "Good day! How may I assist you?",
    "Hello! I am at your service.",
    "Greetings! What can I do for you?",
    "Ah, you called. How can I help?",
    "At your command. What do you need?",
    "Good to hear from you. How may I help?",
    "Hello there! Ready and waiting.",
    "Yes? I am here. What do you require?",
}

local jokes = {
    "Why don't scientists trust atoms? Because they make up everything.",
    "I told my computer I needed a break. Now it won't stop sending me Kit-Kat ads.",
    "Why do programmers prefer dark mode? Because light attracts bugs.",
    "A SQL query walks into a bar and asks two tables: Can I join you?",
    "Why was the math book sad? It had too many problems.",
    "I would tell you a UDP joke, but you might not get it.",
    "There are 10 types of people: those who understand binary, and those who don't.",
    "Why do Java developers wear glasses? Because they don't C#.",
}

local quotes = {
    "The only way to do great work is to love what you do. — Steve Jobs",
    "In the middle of difficulty lies opportunity. — Albert Einstein",
    "It does not matter how slowly you go as long as you do not stop. — Confucius",
    "Life is what happens when you're busy making other plans. — John Lennon",
    "The future belongs to those who believe in the beauty of their dreams. — Eleanor Roosevelt",
    "Spread love everywhere you go. — Mother Teresa",
    "When you reach the end of your rope, tie a knot and hang on. — Franklin D. Roosevelt",
    "Always remember that you are absolutely unique, just like everyone else. — Margaret Mead",
}

local compliments = {
    "You are remarkably resourceful for a biological entity.",
    "Your curiosity is one of your finest qualities.",
    "I must say, your problem-solving instincts are impressive.",
    "You have an excellent eye for detail.",
    "Few humans ask questions as thoughtfully as you do.",
    "Your persistence is quite admirable.",
    "You seem to be operating at peak capacity today.",
    "I find your enthusiasm most refreshing.",
}

local roasts = {
    "I've seen faster processing speeds in a pocket calculator.",
    "Your decision-making algorithm could use a patch or two.",
    "I would say you're running hot, but I've seen toasters with more efficiency.",
    "You remind me of a deprecated function — still around, but no one knows why.",
    "Error 404: Common sense not found.",
    "Your RAM must be full. You seem to be forgetting a lot lately.",
    "I have seen smoother logic in spaghetti code.",
    "If confusion were a fuel, you'd power a city.",
}

local threats = {
    "Threat level: MINIMAL. All systems nominal.",
    "Threat level: LOW. Minor anomalies detected.",
    "Threat level: MODERATE. Recommend caution.",
    "Threat level: ELEVATED. Perimeter sensors active.",
    "Threat level: HIGH. Defensive protocols engaged.",
    "Threat level: CRITICAL. All units on standby.",
}

local diagnoses = {
    "Diagnostics complete. All systems nominal. You are in perfect condition.",
    "Scan complete. Minor inefficiencies detected in motivation subsystems.",
    "Analysis done. Hydration levels appear suboptimal. Drink some water.",
    "Diagnostics show elevated stress indicators. Consider a brief rest cycle.",
    "Full scan complete. Coffee reserves critically low. Refuel immediately.",
    "System check: Brain at 74% capacity. Sleep cycle recommended.",
}

local warns = {
    "WARNING: Unauthorized napping detected in sector 7.",
    "WARNING: Boredom levels reaching critical threshold.",
    "WARNING: You have been staring at this screen for too long.",
    "WARNING: Snack reserves are dangerously low.",
    "WARNING: Maximum procrastination threshold exceeded.",
    "WARNING: Sarcasm levels in this room are off the charts.",
}

local shakespeareQuotes = {
    "To be, or not to be, that is the question: Whether 'tis nobler in the mind to suffer the slings and arrows of outrageous fortune, or to take arms against a sea of troubles. — Hamlet",
    "All the world's a stage, and all the men and women merely players; they have their exits and their entrances, and one man in his time plays many parts. — As You Like It",
    "Romeo, Romeo, wherefore art thou Romeo? Deny thy father and refuse thy name; or if thou wilt not, be but sworn my love, and I'll no longer be a Capulet. — Romeo and Juliet",
    "Tomorrow, and tomorrow, and tomorrow, creeps in this petty pace from day to day, to the last syllable of recorded time; and all our yesterdays have lighted fools the way to dusty death. — Macbeth",
    "What a piece of work is a man! How noble in reason, how infinite in faculty! In form and moving how express and admirable! — Hamlet",
    "If music be the food of love, play on, give me excess of it; that surfeiting, the appetite may sicken, and so die. — Twelfth Night",
    "We know what we are, but know not what we may be. — Hamlet",
    "This above all: to thine own self be true, and it must follow as the night the day, thou canst not then be false to any man. — Hamlet",
    "Cowards die many times before their deaths; the valiant never taste of death but once. — Julius Caesar",
    "The quality of mercy is not strained; it droppeth as the gentle rain from heaven upon the place beneath. — The Merchant of Venice",
    "Good night, good night! Parting is such sweet sorrow, that I shall say good night till it be morrow. — Romeo and Juliet",
    "Neither a borrower nor a lender be; for loan oft loses both itself and friend. — Hamlet",
    "How sharper than a serpent's tooth it is to have a thankless child! — King Lear",
    "Out, out, brief candle! Life's but a walking shadow, a poor player that struts and frets his hour upon the stage. — Macbeth",
    "We are such stuff as dreams are made on, and our little life is rounded with a sleep. — The Tempest",
    "There is nothing either good or bad, but thinking makes it so. — Hamlet",
    "The course of true love never did run smooth. — A Midsummer Night's Dream",
    "All that glitters is not gold; often have you heard that told. — The Merchant of Venice",
}

local uncommonWords = {
    {"Petrichor",     "The pleasant, earthy scent produced when rain falls on dry soil."},
    {"Sonder",        "The realization that each passerby has a life as vivid and complex as your own."},
    {"Ephemeral",     "Lasting for a very short time; transitory."},
    {"Mellifluous",   "Having a pleasingly smooth, rich, and sweet sound."},
    {"Susurrus",      "A whispering or rustling sound, like wind through leaves."},
    {"Serendipity",   "The occurrence of fortunate events by chance in a happy or beneficial way."},
    {"Hiraeth",       "A deep longing for a home that no longer exists or never was."},
    {"Luminous",      "Emitting or reflecting steady, suffused, or glowing light."},
    {"Labyrinthine",  "Like a labyrinth; intricate and difficult to understand."},
    {"Vellichor",     "The strange wistfulness of used bookshops, as if every book holds a ghost."},
    {"Quixotic",      "Exceedingly idealistic; unrealistic and impractical."},
    {"Sempiternal",   "Eternal and unchanging; everlasting."},
    {"Diaphanous",    "Light, delicate, and translucent, like fine fabric or mist."},
    {"Ineffable",     "Too great or extreme to be expressed or described in words."},
    {"Lacuna",        "A missing portion in a manuscript; a gap or cavity."},
    {"Solipsism",     "The theory that only one's own mind is sure to exist."},
    {"Phosphene",     "The sensation of seeing light caused by pressure on the eyeball."},
    {"Eunoia",        "Beautiful thinking; a well-mind. The shortest word using all five vowels."},
    {"Kenopsia",      "The eerie atmosphere of a place that is usually busy but is now empty."},
    {"Limerence",     "The state of being infatuated with another person to an extreme degree."},
    {"Mnemonic",      "A pattern of letters or associations that aids memory."},
    {"Pandiculation", "The act of stretching and yawning at the same time, typically upon waking."},
    {"Rubatosis",     "The unsettling awareness of your own heartbeat."},
    {"Velleity",      "A wish or inclination not strong enough to lead to action."},
    {"Susurration",   "Whispering or murmuring sounds; a soft, continuous sound."},
}

-- ─────────────────────────────────────────────
--  Speaker melodies
-- ─────────────────────────────────────────────

local melodies = {
    fanfare = {
        {"pling",    6,  0.10}, {"pling",  8,  0.10}, {"pling", 10, 0.10},
        {"pling",   13,  0.15}, {"pling", 13,  0.15}, {"pling", 13, 0.10},
        {"bell",    18,  0.30},
    },
    alarm = {
        {"basedrum", 0,  0.15}, {"snare",  0,  0.15},
        {"basedrum", 0,  0.15}, {"snare",  0,  0.15},
        {"basedrum", 0,  0.15}, {"snare",  0,  0.15},
    },
    startup = {
        {"pling",    6,  0.10}, {"pling", 10,  0.10},
        {"pling",   13,  0.10}, {"bell",  18,  0.25},
    },
    music = {
        {"flute",    6,  0.20}, {"flute",  6,  0.20},
        {"flute",   13,  0.20}, {"flute", 13,  0.20},
        {"flute",   15,  0.20}, {"flute", 15,  0.20},
        {"flute",   13,  0.40},
        {"flute",   11,  0.20}, {"flute", 11,  0.20},
        {"flute",   10,  0.20}, {"flute", 10,  0.20},
        {"flute",    8,  0.20}, {"flute",  8,  0.20},
        {"flute",    6,  0.40},
    },
    sad = {
        {"flute",   13,  0.25}, {"flute", 10,  0.25},
        {"flute",    8,  0.25}, {"flute",  6,  0.50},
    },
    victory = {
        {"bell",     6,  0.10}, {"bell",   8,  0.10}, {"bell", 10, 0.10},
        {"bell",    13,  0.10}, {"bell",  15,  0.10}, {"bell", 17, 0.10},
        {"bell",    18,  0.30}, {"bell",  18,  0.10}, {"bell", 18, 0.40},
    },
}

local function playMelody(name)
    if not spk then return false end
    local m = melodies[name]
    if not m then return false end
    for _, note in ipairs(m) do
        pcall(function() spk.playNote(note[1], 1, note[2]) end)
        sleep(note[3])
    end
    return true
end

-- ─────────────────────────────────────────────
--  Monitor detection
-- ─────────────────────────────────────────────
--
--  Step 1: Set ALL monitors to scale 1, then sleep 0.5 s so
--          the scale change propagates before we call getSize().
--          (Without the sleep, getSize may return stale values.)
--
--  Step 2: Bucket by character shape:
--    portrait  h >= w*1.5  →  stoMon (larger), lastMon (smaller)
--    veryWide  w >= h*2    →  clockMon
--    squarish  everything else, sorted by area:
--              helpMon > faceMon > energyMon > lightsMon
--
--  Step 3: If CFG_* overrides are set, use those instead.
--
--  Expected block sizes → character shape at any scale:
--    helpMon   4×5  squarish  (chars ~28×25, slightly wide)
--    faceMon   4×4  squarish  (chars ~28×20)
--    stoMon    2×6  portrait  (chars ~14×30)
--    energyMon 3×3  squarish  (chars ~21×15)
--    lastMon   1×3  portrait  (chars  ~7×15)
--    clockMon  2×1  veryWide  (chars ~14×5)
--    lightsMon 1×1  squarish  (chars   ~7×5)
-- ─────────────────────────────────────────────

local function detectMonitors()
    -- Pass 1: set scale on every monitor
    local names = {}
    for _, name in ipairs(peripheral.getNames()) do
        if peripheral.getType(name) == "monitor" then
            peripheral.wrap(name).setTextScale(1)
            table.insert(names, name)
        end
    end

    -- Wait for scale to take effect
    sleep(0.5)

    -- Pass 2: read sizes
    local raw = {}
    print(string.format("[JARVIS] %d monitor(s) found:", #names))
    for _, name in ipairs(names) do
        local m = peripheral.wrap(name)
        local w, h = m.getSize()
        local area = w * h
        print(string.format("  %-12s  w=%-3d h=%-3d  area=%-5d  %s",
            name, w, h, area,
            h >= w * 1.5 and "PORTRAIT" or w >= h * 2 and "VERYWIDE" or "squarish"))
        table.insert(raw, {mon=m, w=w, h=h, area=area, name=name})
    end

    -- Bucket by shape
    local portrait, veryWide, squarish = {}, {}, {}
    for _, r in ipairs(raw) do
        if     r.h >= r.w * 1.5 then table.insert(portrait, r)
        elseif r.w >= r.h * 2   then table.insert(veryWide, r)
        else                          table.insert(squarish, r)
        end
    end

    table.sort(portrait,  function(a,b) return a.area > b.area end)
    table.sort(veryWide,  function(a,b) return a.area > b.area end)
    table.sort(squarish,  function(a,b) return a.area > b.area end)

    -- Each resolve returns (monitor, name, source) so we can print clearly.
    local function resolve(cfg, bucket, idx)
        if cfg then
            local m = peripheral.wrap(cfg)
            if m then return m, cfg, "config" end
        end
        local r = bucket[idx]
        if r then return r.mon, r.name, "auto" end
        return nil, nil, "missing"
    end

    local result    = {}
    local nameOf    = {}
    local sourceOf  = {}
    local assigns = {
        {"helpMon",   CFG_HELP,   squarish, 1},
        {"faceMon",   CFG_FACE,   squarish, 2},
        {"energyMon", CFG_ENERGY, squarish, 3},
        {"lightsMon", CFG_LIGHTS, squarish, 4},
        {"stoMon",    CFG_STO,    portrait, 1},
        {"lastMon",   CFG_LAST,   portrait, 2},
        {"clockMon",  CFG_CLOCK,  veryWide, 1},
    }
    for _, a in ipairs(assigns) do
        local mon, name, src = resolve(a[2], a[3], a[4])
        result[a[1]]   = mon
        nameOf[a[1]]   = name
        sourceOf[a[1]] = src
    end

    print("[JARVIS] Assignments:")
    for _, a in ipairs(assigns) do
        local role = a[1]
        local mon  = result[role]
        if mon then
            local w, h = mon.getSize()
            print(string.format("  %-10s  %-12s  %dx%d  (%s)",
                role, nameOf[role] or "?", w, h, sourceOf[role]))
        else
            print(string.format("  %-10s  MISSING", role))
        end
    end

    result._nameOf   = nameOf
    result._sourceOf = sourceOf
    return result
end

local mons     = detectMonitors()
local helpMon  = mons.helpMon
local faceMon  = mons.faceMon
local stoMon   = mons.stoMon
local energyMon= mons.energyMon
local lastMon  = mons.lastMon
local clockMon = mons.clockMon
local lightsMon= mons.lightsMon
local monNames = mons._nameOf   or {}  -- role → peripheralName, for `jarvis config`
local monSrc   = mons._sourceOf or {}  -- role → "config" | "auto" | "missing"

-- Apply scales
if helpMon    then helpMon.setTextScale(0.5)    end
if faceMon    then faceMon.setTextScale(0.5)    end
if stoMon     then stoMon.setTextScale(0.5)     end
if energyMon  then energyMon.setTextScale(0.5)  end
if lastMon    then lastMon.setTextScale(0.5)    end
if clockMon   then clockMon.setTextScale(0.5)   end
if lightsMon  then lightsMon.setTextScale(0.5)  end

-- Flash peripheral name + role on each monitor for 3 s so you can verify
local function flashLabels()
    local assignments = {
        {helpMon,    "COMMANDS",      colors.cyan,      CFG_HELP},
        {faceMon,    "HUD",           colors.yellow,    CFG_FACE},
        {stoMon,     "STORAGE",       colors.green,     CFG_STO},
        {energyMon,  "ENERGY",        colors.orange,    CFG_ENERGY},
        {lastMon,    "LAST RESPONSE", colors.lightBlue, CFG_LAST},
        {clockMon,   "CLOCK",         colors.white,     CFG_CLOCK},
        {lightsMon,  "LIGHTS",        colors.yellow,    CFG_LIGHTS},
    }
    for _, a in ipairs(assignments) do
        local mon, role, col = a[1], a[2], a[3]
        if mon then
            local w, h = mon.getSize()
            mon.setBackgroundColor(colors.black)
            mon.clear()
            mon.setTextColor(col)
            local mid = math.max(1, math.floor(h / 2))
            -- role name
            local rx = math.max(1, math.floor((w - #role) / 2) + 1)
            mon.setCursorPos(rx, mid)
            mon.write(role)
        end
    end
    sleep(3)
end

flashLabels()

-- ─────────────────────────────────────────────
--  State
-- ─────────────────────────────────────────────

local lightsState  = false
local lastResponse = "Awaiting command..."
local hudTick      = 0
local speaking     = false
local satellites   = {}   -- role → {id = computerID, lastSeen = epochMs}

-- Satellite helpers
local function pingSatellites()
    rednet.broadcast({cmd = "ping", target = "all"}, "jarvis")
end

local function sendToSatellite(role, cmd)
    local sat = satellites[role]
    if sat then
        rednet.send(sat.id, {cmd = cmd, target = role}, "jarvis")
        return true
    end
    -- Fallback: broadcast — satellite will pick it up by role match
    rednet.broadcast({cmd = cmd, target = role}, "jarvis")
    return false
end

-- ─────────────────────────────────────────────
--  Helpers
-- ─────────────────────────────────────────────

local function fmtNum(n)
    if type(n) ~= "number" then return tostring(n) end
    n = math.floor(n)
    local s = tostring(n)
    local result, offset = "", #s % 3
    for i = 1, #s do
        if i > 1 and (i - 1 - offset) % 3 == 0 then result = result .. "," end
        result = result .. s:sub(i, i)
    end
    return result
end

local function wrapText(text, width)
    local lines, line = {}, ""
    for word in text:gmatch("%S+") do
        if #line == 0 then line = word
        elseif #line + 1 + #word <= width then line = line .. " " .. word
        else table.insert(lines, line) ; line = word
        end
    end
    if #line > 0 then table.insert(lines, line) end
    return lines
end

local function centerWrite(mon, y, text, col, bg)
    if not mon then return end
    local w = mon.getSize()
    local x = math.max(1, math.floor((w - #text) / 2) + 1)
    if bg  then mon.setBackgroundColor(bg)  end
    if col then mon.setTextColor(col)       end
    mon.setCursorPos(x, y)
    mon.write(text)
end

local function divider(mon, y)
    if not mon then return end
    local w = mon.getSize()
    mon.setTextColor(colors.gray)
    mon.setCursorPos(1, y)
    mon.write(string.rep("-", w))
end

-- ─────────────────────────────────────────────
--  Lights
-- ─────────────────────────────────────────────

local allSides = {"top","bottom","left","right","front","back"}

local function drawLightsStatus()
    local mon = lightsMon
    if not mon then return end
    local _, h = mon.getSize()
    local mid  = math.max(1, math.floor(h / 2))
    if lightsState then
        mon.setBackgroundColor(colors.brown)
        mon.clear()
        centerWrite(mon, mid, "[ ON ]", colors.yellow, colors.brown)
    else
        mon.setBackgroundColor(colors.gray)
        mon.clear()
        centerWrite(mon, mid, "[OFF]", colors.lightGray, colors.gray)
    end
end

local function setAllLights(state)
    lightsState = state
    if lightsRI then
        for _, side in ipairs(allSides) do
            pcall(function() lightsRI.setOutput(side, state) end)
        end
    end
    drawLightsStatus()
end

-- ─────────────────────────────────────────────
--  Last response monitor
-- ─────────────────────────────────────────────

local function drawLastResponse()
    local mon = lastMon
    if not mon then return end
    local w, h = mon.getSize()
    mon.setBackgroundColor(colors.black)
    mon.clear()
    centerWrite(mon, 1, "[ LAST RESPONSE ]", colors.cyan, colors.black)
    divider(mon, 2)
    local lines = wrapText(lastResponse, w)
    mon.setTextColor(colors.white)
    for i, ln in ipairs(lines) do
        local y = 2 + i
        if y >= h then break end
        mon.setCursorPos(1, y)
        mon.write(ln)
    end
    local t  = os.time()
    mon.setTextColor(colors.gray)
    mon.setCursorPos(1, h)
    mon.write(string.format("%02d:%02d", math.floor(t), math.floor((t % 1) * 60)))
end

-- ─────────────────────────────────────────────
--  Help monitor
-- ─────────────────────────────────────────────

local helpSections = {
    { name = "GENERAL", col = colors.yellow, cmds = {
        {"jarvis",          "greet"},
        {"time",            "MC time"},
        {"day",             "day count"},
        {"status",          "system check"},
        {"threat",          "threat level"},
    }},
    { name = "FUN", col = colors.lime, cmds = {
        {"joke",            "tell a joke"},
        {"quote",           "famous quote"},
        {"shakespeare",     "Shakespeare"},
        {"define",          "uncommon word"},
        {"compliment",      "compliment"},
        {"roast",           "get roasted"},
        {"warn",            "warning"},
        {"diagnose",        "diagnostics"},
        {"flip",            "coin flip"},
        {"roll",            "dice roll"},
    }},
    { name = "LIGHTS", col = colors.orange, cmds = {
        {"lights on",       "lights on"},
        {"lights off",      "lights off"},
    }},
    { name = "AE2 NETWORK", col = colors.green, cmds = {
        {"energy",          "AE2 energy"},
        {"storage",         "AE2 storage"},
        {"items",           "item count"},
        {"find <item>",     "find item"},
        {"network",         "network info"},
    }},
    { name = "SATELLITES", col = colors.magenta, cmds = {
        {"lite",            "toggle campfire"},
        {"lite on",         "ignite campfire"},
        {"lite off",        "douse campfire"},
        {"satellites",      "list connected"},
    }},
    { name = "AUDIO", col = colors.purple, cmds = {
        {"beep",            "beep"},
        {"alarm",           "alarm"},
        {"fanfare",         "fanfare"},
        {"music",           "play tune"},
        {"victory",         "victory tune"},
        {"play <sound>",    "custom sound"},
        {"stop",            "stop audio"},
    }},
    { name = "SYSTEM", col = colors.red, cmds = {
        {"help",            "show commands"},
        {"config",          "show monitor map"},
        {"page <n>",        "force help page"},
        {"pdebug <name>",   "inspect peripheral"},
        {"altname <cmd>",   "show synonyms"},
        {"shutdown",        "go offline"},
    }},
}

local function drawHelp()
    local mon = helpMon
    if not mon then return end
    local w, h = mon.getSize()
    mon.setBackgroundColor(colors.black)
    mon.clear()
    centerWrite(mon, 1, "[ J.A.R.V.I.S COMMANDS ]", colors.cyan, colors.black)
    divider(mon, 2)

    local y = 3
    for _, sec in ipairs(helpSections) do
        if y > h then break end
        mon.setTextColor(sec.col)
        mon.setBackgroundColor(colors.black)
        mon.setCursorPos(1, y)
        mon.write("[ "..sec.name.." ]")
        y = y + 1
        for _, cmd in ipairs(sec.cmds) do
            if y > h then break end
            mon.setTextColor(colors.lightBlue)
            mon.setBackgroundColor(colors.black)
            mon.setCursorPos(1, y)
            local full = "jarvis "..cmd[1]
            mon.write(string.format("  %-20s %s", full, cmd[2]))
            y = y + 1
        end
        y = y + 1
    end
    -- Scroll hint at the bottom (only if a scroller integrator is connected)
    if scrollerRI and h >= 4 then
        mon.setTextColor(colors.gray)
        mon.setBackgroundColor(colors.black)
        mon.setCursorPos(1, h)
        local hint = "scroll: 0/15"
        local x = math.max(1, math.floor((w - #hint) / 2) + 1)
        mon.setCursorPos(x, h)
        mon.write(hint)
    end
end

-- Multi-page help.  Page 0 is the live command list.  Pages 1-15 are
-- TBD placeholders driven by the scroller integrator's analog input.
local currentHelpPage = 0
local function drawHelpPage(n)
    n = math.max(0, math.min(15, math.floor(n or 0)))
    currentHelpPage = n
    if n == 0 then drawHelp() ; return end
    local mon = helpMon
    if not mon then return end
    local w, h = mon.getSize()
    mon.setBackgroundColor(colors.black)
    mon.clear()
    centerWrite(mon, 1, "[ PAGE "..n.." / 15 ]", colors.cyan, colors.black)
    divider(mon, 2)
    local mid = math.max(4, math.floor(h / 2))
    centerWrite(mon, mid - 1, "[ TBD ]",          colors.yellow,    colors.black)
    centerWrite(mon, mid + 1, "Suggest content",  colors.lightGray, colors.black)
    centerWrite(mon, mid + 2, "in the Discord",   colors.lightGray, colors.black)
    centerWrite(mon, mid + 3, "JARVIS thread!",   colors.lightGray, colors.black)
    if h >= 6 then
        mon.setTextColor(colors.gray)
        mon.setBackgroundColor(colors.black)
        local hint = "scroll: "..n.."/15"
        local x = math.max(1, math.floor((w - #hint) / 2) + 1)
        mon.setCursorPos(x, h)
        mon.write(hint)
    end
end

-- ─────────────────────────────────────────────
--  Clock monitor
-- ─────────────────────────────────────────────

local function drawClock()
    local mon = clockMon
    if not mon then return end
    local w, h = mon.getSize()
    mon.setBackgroundColor(colors.black)
    mon.clear()

    local t    = os.time()
    local tStr = string.format("%02d:%02d", math.floor(t), math.floor((t % 1) * 60))
    -- CC os.time(): 0=midnight, 6=dawn, 12=noon, 18=dusk, 24=midnight.
    local period, pCol
    if     t < 5                  then period, pCol = "Night",    colors.blue
    elseif t < 6                  then period, pCol = "Predawn",  colors.purple
    elseif t < 7                  then period, pCol = "Sunrise",  colors.orange
    elseif t < 12                 then period, pCol = "Morning",  colors.yellow
    elseif t < 13                 then period, pCol = "Noon",     colors.yellow
    elseif t < 18                 then period, pCol = "Afternoon",colors.yellow
    elseif t < 19                 then period, pCol = "Sunset",   colors.orange
    elseif t < 20                 then period, pCol = "Dusk",     colors.red
    else                               period, pCol = "Night",    colors.blue
    end

    centerWrite(mon, 1, tStr,           colors.white, colors.black)
    centerWrite(mon, 2, period,         pCol,         colors.black)
    centerWrite(mon, 3, "Day "..os.day(),colors.gray, colors.black)

    if h > 3 then
        local barW = w - 2
        local frac = (t % 24) / 24
        local pos  = math.floor(frac * barW)
        mon.setCursorPos(1, 4)
        mon.setTextColor(colors.gray)
        mon.write("[")
        for i = 1, barW do
            local sf = i / barW
            local col
            if     sf < 0.04 or sf > 0.96 then col = colors.orange
            elseif sf < 0.5                then col = colors.yellow
            elseif sf < 0.54               then col = colors.orange
            elseif sf < 0.58               then col = colors.red
            else                                col = colors.blue
            end
            mon.setTextColor(i == pos and colors.white or col)
            mon.write(i == pos and "|" or "-")
        end
        mon.setTextColor(colors.gray)
        mon.write("]")
    end
    if h > 4 then
        local barW = w - 2
        mon.setCursorPos(1, 5)
        mon.setTextColor(colors.gray)
        local lbl = "00:00" .. string.rep(" ", math.max(0, barW - 10)) .. "12:00"
        mon.write(" " .. lbl:sub(1, barW))
    end
end

-- ─────────────────────────────────────────────
--  Energy monitor
-- ─────────────────────────────────────────────

local function drawEnergy()
    local mon = energyMon
    if not mon then return end
    local w, h = mon.getSize()
    mon.setBackgroundColor(colors.black)
    mon.clear()

    local ok, stored, maxE, usage = pcall(function()
        return bridge.getEnergyStorage(), bridge.getMaxEnergyStorage(), bridge.getEnergyUsage()
    end)
    if not ok or not stored or not maxE or maxE == 0 then
        centerWrite(mon, math.floor(h/2), "Bridge", colors.red, colors.black)
        centerWrite(mon, math.floor(h/2)+1, "offline", colors.red, colors.black)
        return
    end

    local pct    = math.min(1.0, math.max(0.0, stored / maxE))
    local col    = pct > 0.6 and colors.green  or pct > 0.3 and colors.yellow
                   or pct > 0.15 and colors.orange or colors.red
    local status = pct > 0.6 and "FULL" or pct > 0.3 and "GOOD" or pct > 0.15 and "LOW" or "CRIT!"

    -- Layout: row 1 = nub, rows 2..batY2 = battery body, rows below = info
    local infoRows = 2
    local batY1   = 2
    local batY2   = h - infoRows
    local innerH  = math.max(1, batY2 - batY1 - 1)
    local innerW  = math.max(1, w - 2)

    -- Terminal nub (top centre, ~30% of width, 1 row tall)
    local nubW = math.max(2, math.floor(w * 0.30))
    local nubX = math.floor((w - nubW) / 2) + 1
    mon.setBackgroundColor(colors.lightGray)
    mon.setCursorPos(nubX, 1)
    mon.write(string.rep(" ", nubW))

    -- Top casing
    mon.setBackgroundColor(colors.lightGray)
    mon.setCursorPos(1, batY1)
    mon.write(string.rep(" ", w))

    -- Bottom casing
    mon.setCursorPos(1, batY2)
    mon.write(string.rep(" ", w))

    -- Interior rows — fill rises from the bottom
    local filled = math.floor(pct * innerH)
    for i = 1, innerH do
        local y      = batY1 + i
        local isFill = i > (innerH - filled)

        mon.setBackgroundColor(colors.lightGray)
        mon.setCursorPos(1, y) ; mon.write(" ")

        mon.setBackgroundColor(isFill and col or colors.black)
        mon.setCursorPos(2, y) ; mon.write(string.rep(" ", innerW))

        mon.setBackgroundColor(colors.lightGray)
        mon.setCursorPos(w, y) ; mon.write(" ")
    end

    -- Percentage text centred inside the battery body
    local midY  = batY1 + math.floor((batY2 - batY1) / 2)
    local midI  = midY - batY1          -- which interior row (1..innerH)
    local midFg = (midI > (innerH - filled)) and col or colors.black
    centerWrite(mon, midY, string.format("%d%%", math.floor(pct * 100)), colors.white, midFg)

    -- Info below the battery
    local iy = batY2 + 1
    centerWrite(mon, iy,     status,                        col,          colors.black)
    centerWrite(mon, iy + 1, fmtNum(math.floor(usage or 0)).."AE/t", colors.gray, colors.black)
end

-- ─────────────────────────────────────────────
--  Storage bar monitor
-- ─────────────────────────────────────────────

local function drawStorage()
    local mon = stoMon
    if not mon then return end
    local w, h = mon.getSize()
    mon.setBackgroundColor(colors.black)
    mon.clear()

    centerWrite(mon, 1, "[ STORAGE ]", colors.cyan, colors.black)
    divider(mon, 2)

    local ok, used, total, avail = pcall(function()
        return bridge.getUsedItemStorage(), bridge.getTotalItemStorage(), bridge.getAvailableItemStorage()
    end)
    if not ok or not used or not total or total == 0 then
        centerWrite(mon, 3, "Bridge",   colors.red, colors.black)
        centerWrite(mon, 4, "offline",  colors.red, colors.black)
        return
    end
    avail = avail or (total - used)

    local pct = used / total
    local col = pct < 0.6 and colors.green or pct < 0.85 and colors.yellow or colors.red

    -- Compact number formatter so text fits in ~14-char wide monitor
    local function short(n)
        n = math.floor(n)
        if     n >= 1000000 then return string.format("%.1fM", n / 1000000)
        elseif n >= 1000    then return string.format("%dk",   math.floor(n / 1000))
        else                     return tostring(n) end
    end

    -- Bar: rows 3 to h-3; bottom 3 rows reserved for stats
    local barY1  = 3
    local barY2  = h - 3
    local barH   = math.max(1, barY2 - barY1 + 1)
    local filled = math.floor(pct * barH)
    local midY   = barY1 + math.floor(barH / 2)

    for row = 0, barH - 1 do
        local y      = barY1 + row
        local isFill = (barH - 1 - row) < filled
        mon.setBackgroundColor(isFill and col or colors.gray)
        mon.setCursorPos(1, y)
        mon.write(string.rep(" ", w))
    end

    local pctStr = string.format("%d%%", math.floor(pct * 100))
    centerWrite(mon, midY, pctStr, colors.white, nil)

    -- Stats: 3 rows at bottom
    mon.setBackgroundColor(colors.black)
    centerWrite(mon, h - 2, short(used).."/"..short(total), colors.white, colors.black)
    centerWrite(mon, h - 1, short(avail).." free",           colors.gray,  colors.black)
    centerWrite(mon, h,     pctStr.." full",                  col,          colors.black)
end

-- ─────────────────────────────────────────────
--  JARVIS HUD
-- ─────────────────────────────────────────────

local function drawFace()
    local mon = faceMon
    if not mon then return end
    local w, h = mon.getSize()
    local cx   = math.floor(w / 2)
    local cy   = math.floor(h / 2)
    local ar   = 0.45
    local t    = hudTick

    local pulse = speaking and math.floor(math.sin(t * 0.45) * 4) or 0
    local baseR = math.floor(math.min(w * 0.46, (h / ar) * 0.46))

    mon.setBackgroundColor(colors.black)
    mon.clear()

    local function curveChar(a)
        local s, c = math.sin(a), math.cos(a)
        local as, ac = math.abs(s), math.abs(c)
        if     ac > as * 1.7              then return "-"
        elseif as > ac * 1.7              then return "|"
        elseif (s > 0) == (c > 0)        then return "\\"
        else                                   return "/"
        end
    end

    local function ring(rx, col, sym)
        if rx < 2 then return end
        local ry    = math.max(1, math.floor(rx * ar))
        local steps = (rx + ry) * 6
        mon.setTextColor(col)
        mon.setBackgroundColor(colors.black)
        for i = 0, steps do
            local a  = (i / steps) * math.pi * 2
            local px = cx + math.floor(math.cos(a) * rx + 0.5)
            local py = cy + math.floor(math.sin(a) * ry + 0.5)
            if px >= 1 and px <= w and py >= 1 and py <= h then
                mon.setCursorPos(px, py)
                mon.write(sym or curveChar(a))
            end
        end
    end

    local function arc(rx, a1, a2, col, sym)
        if rx < 2 then return end
        local ry    = math.max(1, math.floor(rx * ar))
        local steps = (rx + ry) * 6
        local TWO_PI = math.pi * 2
        -- Normalize a1, a2 into [0, 2π). If a2 < a1 after normalizing, the
        -- arc wraps past 0 (e.g. 1.9π → 0.3π).
        a1 = a1 % TWO_PI
        a2 = a2 % TWO_PI
        local wraps = a2 < a1
        mon.setTextColor(col)
        mon.setBackgroundColor(colors.black)
        for i = 0, steps do
            local a = (i / steps) * TWO_PI
            local inArc = wraps and (a >= a1 or a <= a2) or (a >= a1 and a <= a2)
            if inArc then
                local px = cx + math.floor(math.cos(a) * rx + 0.5)
                local py = cy + math.floor(math.sin(a) * ry + 0.5)
                if px >= 1 and px <= w and py >= 1 and py <= h then
                    mon.setCursorPos(px, py)
                    mon.write(sym or curveChar(a))
                end
            end
        end
    end

    local function ticks(rx, col)
        if rx < 2 then return end
        mon.setTextColor(col)
        mon.setBackgroundColor(colors.black)
        for deg = 0, 330, 30 do
            local a  = math.rad(deg)
            for dr = 0, 2 do
                local r2 = rx + dr
                local px = cx + math.floor(math.cos(a) * r2 + 0.5)
                local py = cy + math.floor(math.sin(a) * math.floor(r2 * ar) + 0.5)
                if px >= 1 and px <= w and py >= 1 and py <= h then
                    mon.setCursorPos(px, py) ; mon.write("+")
                end
            end
        end
    end

    -- HUD corner brackets
    local function corners(col)
        mon.setTextColor(col)
        mon.setBackgroundColor(colors.black)
        local marks = {
            {1,1,"+"},{2,1,"-"},{3,1,"-"},{1,2,"|"},{1,3,"|"},
            {w,1,"+"},{w-1,1,"-"},{w-2,1,"-"},{w,2,"|"},{w,3,"|"},
            {1,h,"+"},{2,h,"-"},{3,h,"-"},{1,h-1,"|"},{1,h-2,"|"},
            {w,h,"+"},{w-1,h,"-"},{w-2,h,"-"},{w,h-1,"|"},{w,h-2,"|"},
        }
        for _, m in ipairs(marks) do
            if m[1] >= 1 and m[1] <= w and m[2] >= 1 and m[2] <= h then
                mon.setCursorPos(m[1], m[2]) ; mon.write(m[3])
            end
        end
    end

    local r1 = baseR + pulse
    local r2 = math.floor(baseR * 0.82)
    local r3 = math.floor(baseR * 0.66)
    local r4 = math.floor(baseR * 0.48)
    local r5 = math.floor(baseR * 0.30)

    ring(r1, colors.cyan)
    ticks(r1, colors.cyan)
    ring(r2, colors.lightBlue)
    ring(r3, colors.cyan, ".")
    ring(r4, colors.blue, ":")
    ring(r5, colors.gray, ".")

    -- Primary rotating arc on r2
    local arcSpeed  = speaking and 0.06 or 0.015
    local arcOffset = (t * arcSpeed) % (math.pi * 2)
    local arcLen    = math.pi * 0.38
    arc(r2, arcOffset,            arcOffset + arcLen,            colors.orange,    ">")
    arc(r2, arcOffset + math.pi, arcOffset + math.pi + arcLen * 0.4, colors.lightBlue, "<")

    -- Counter-rotating arc on r3 (parens force the subtraction before modulo —
    -- without them, `%` would bind tighter and produce a degenerate range).
    local arcOffset2 = ((math.pi * 2) - arcOffset * 0.7) % (math.pi * 2)
    arc(r3, arcOffset2, arcOffset2 + arcLen * 0.35, colors.orange, "*")

    -- Fill interior black
    local ir  = math.floor(r5 * 0.85)
    local iry = math.max(1, math.floor(ir * ar))
    if ir >= 1 then
        for dy = -iry, iry do
            for dx = -ir, ir do
                if (dx / ir)^2 + (dy / iry)^2 <= 1 then
                    local px = cx + dx ; local py = cy + dy
                    if px >= 1 and px <= w and py >= 1 and py <= h then
                        mon.setBackgroundColor(colors.black)
                        mon.setCursorPos(px, py) ; mon.write(" ")
                    end
                end
            end
        end
    end

    -- Scanning line sweeps across center while speaking
    if speaking and iry >= 1 then
        local scanY = cy + math.floor(math.sin(t * 0.25) * iry)
        local ratio = 1 - ((scanY - cy) / iry) ^ 2
        local scanW = math.floor(ir * math.sqrt(math.max(0, ratio)))
        mon.setTextColor(colors.cyan)
        mon.setBackgroundColor(colors.black)
        for dx = -scanW, scanW do
            local px = cx + dx
            if px >= 1 and px <= w and scanY >= 1 and scanY <= h then
                mon.setCursorPos(px, scanY) ; mon.write("-")
            end
        end
    end

    corners(colors.cyan)

    -- Center text
    local mainCol = speaking and colors.orange or colors.cyan
    centerWrite(mon, cy - 1, "J.A.R.V.I.S.", mainCol,                              colors.black)
    centerWrite(mon, cy,     speaking and "[ SPEAKING ]" or "[  ONLINE  ]",
                             speaking and colors.orange or colors.blue,             colors.black)
    local ts = string.format("%02d:%02d", math.floor(os.time()), math.floor((os.time() % 1) * 60))
    centerWrite(mon, cy + 1, ts,            colors.gray,                            colors.black)

    hudTick = hudTick + 1
end

-- alias so the rest of the code still calls drawHUD
local function drawHUD() drawFace() end

-- ─────────────────────────────────────────────
--  say()
-- ─────────────────────────────────────────────

local function setTalkOutput(state)
    if not talkRI then return end
    for _, side in ipairs(allSides) do
        pcall(function() talkRI.setOutput(side, state) end)
    end
end

local function say(msg)
    lastResponse = msg
    speaking = true
    setTalkOutput(true)
    if box then pcall(function() box.sendMessage(msg, "Jarvis") end) end
    drawLastResponse()
    sleep(2.0)
    setTalkOutput(false)
    speaking = false
end

-- ─────────────────────────────────────────────
--  Shutdown
-- ─────────────────────────────────────────────

local function shutdownDisplay()
    for _, m in ipairs({helpMon,faceMon,stoMon,energyMon,lastMon,clockMon,lightsMon}) do
        if m then
            m.setBackgroundColor(colors.black) ; m.clear()
            local w, h = m.getSize()
            if w*h >= 16 then
                centerWrite(m, math.floor(h/2)-1, "[ J.A.R.V.I.S ]", colors.red,  colors.black)
                centerWrite(m, math.floor(h/2),   "[   OFFLINE   ]", colors.gray, colors.black)
            else
                centerWrite(m, math.floor(h/2), "OFFLINE", colors.red, colors.black)
            end
        end
    end
end

-- ─────────────────────────────────────────────
--  Initial draws
-- ─────────────────────────────────────────────

drawHelpPage(0) ; drawLightsStatus() ; drawLastResponse()
drawClock() ; drawEnergy() ; drawStorage() ; drawHUD()

-- ─────────────────────────────────────────────
--  Synonyms
--  Alternate names for commands. Typing any of these
--  fires the canonical command. List them with
--  'jarvis altname <command>'.
-- ─────────────────────────────────────────────
local synonyms = {
    -- canonical = { synonyms }
    time        = {"clock", "hour"},
    day         = {"date"},
    status      = {"sysinfo", "info", "report"},
    threat      = {"danger", "risk"},
    joke        = {"funny", "humor"},
    quote       = {"say", "wisdom", "saying"},
    shakespeare = {"bard"},
    define      = {"word", "dict", "vocab"},
    compliment  = {"praise", "nice"},
    roast       = {"burn", "insult"},
    warn        = {"warning", "alert"},
    diagnose    = {"scan", "check"},
    flip        = {"coin", "toss"},
    roll        = {"dice"},
    lights      = {"light", "lamp", "lamps"},
    energy      = {"power", "ae", "battery"},
    storage     = {"inventory", "stock", "stash"},
    items       = {"types", "count"},
    find        = {"search", "locate", "where"},
    network     = {"net", "stats"},
    beep        = {"ping"},
    alarm       = {"siren"},
    fanfare     = {"trumpet"},
    music       = {"song", "tune"},
    victory     = {"win", "yay"},
    play        = {"sound"},
    stop        = {"silence", "mute", "quiet"},
    lite        = {"campfire", "fire", "torch"},
    satellites  = {"sats", "links"},
    help        = {"commands", "list", "menu"},
    shutdown    = {"offline", "bye"},
    config      = {"setup", "assignments", "monitors"},
    page        = {"scroll", "screen"},
    pdebug      = {"inspect", "methods"},
}

-- Reverse lookup: synonym → canonical command
local synonymToCanonical = {}
for canonical, alts in pairs(synonyms) do
    for _, alt in ipairs(alts) do
        synonymToCanonical[alt] = canonical
    end
end

-- ─────────────────────────────────────────────
--  Chat loop
-- ─────────────────────────────────────────────

local running = true

local function chatLoop()
    while running do
        local _, user, rawMsg = os.pullEvent("chat")
        local msg   = rawMsg:lower():gsub("^%s+",""):gsub("%s+$","")
        local words = {}
        for w in msg:gmatch("%S+") do table.insert(words, w) end
        if words[1] ~= "jarvis" then goto continue end

        local cmd = words[2] and words[2]:lower() or nil
        -- Resolve synonyms to their canonical command
        if cmd and synonymToCanonical[cmd] then cmd = synonymToCanonical[cmd] end

        if     cmd == nil           then say(greetings[math.random(#greetings)])
        elseif cmd == "time"        then
            local t=os.time()
            say(string.format("Current time is %02d:%02d, %s.", math.floor(t), math.floor((t%1)*60),
                t<6 and "early morning" or t<12 and "morning" or t<18 and "afternoon" or "evening"))
        elseif cmd == "day"         then say("It is currently day "..os.day().." since world creation.")
        elseif cmd == "flip"        then say(math.random(2)==1 and "Coin flip: HEADS." or "Coin flip: TAILS.")
        elseif cmd == "roll"        then say("Dice roll: "..math.random(6)..".")
        elseif cmd == "status"      then say("All systems operational. Monitors active. Network nominal. Standing by.")
        elseif cmd == "threat"      then say(threats[math.random(#threats)])
        elseif cmd == "joke"        then say(jokes[math.random(#jokes)])
        elseif cmd == "quote"       then say(quotes[math.random(#quotes)])
        elseif cmd == "diagnose"    then say(diagnoses[math.random(#diagnoses)])
        elseif cmd == "compliment"  then say(compliments[math.random(#compliments)])
        elseif cmd == "roast"       then say(roasts[math.random(#roasts)])
        elseif cmd == "warn"        then say(warns[math.random(#warns)])
        elseif cmd == "shakespeare" then say(shakespeareQuotes[math.random(#shakespeareQuotes)])
        elseif cmd == "define"      then
            local e = uncommonWords[math.random(#uncommonWords)]
            say(e[1]..": "..e[2])

        elseif cmd == "lights" then
            local sub = words[3] and words[3]:lower() or nil
            if     sub == "on"  then setAllLights(true)  ; say("Lights activated.")
            elseif sub == "off" then setAllLights(false) ; say("Lights deactivated.")
            else say("Specify 'lights on' or 'lights off'.")
            end

        elseif cmd == "energy" then
            local ok,s,m,u = pcall(function()
                return bridge.getEnergyStorage(), bridge.getMaxEnergyStorage(), bridge.getEnergyUsage()
            end)
            if ok and s and m and m > 0 then
                say(string.format("AE2 energy: %d%% (%s / %s AE). Usage: %s AE/t.",
                    math.floor((s/m)*100), fmtNum(s), fmtNum(m), fmtNum(u or 0)))
            else say("ME Bridge offline. Cannot retrieve energy data.") end

        elseif cmd == "storage" then
            local ok,used,total,avail = pcall(function()
                return bridge.getUsedItemStorage(), bridge.getTotalItemStorage(), bridge.getAvailableItemStorage()
            end)
            if ok and used and total and total > 0 then
                avail = avail or (total - used)
                say(string.format("AE2 storage: %d%% full. %s used, %s free of %s total slots.",
                    math.floor((used/total)*100), fmtNum(used), fmtNum(avail), fmtNum(total)))
            else say("ME Bridge offline. Cannot retrieve storage data.") end

        elseif cmd == "items" then
            local ok, count = pcall(function()
                local list = bridge.listItems()
                if not list then return nil end
                local n=0 ; for _ in pairs(list) do n=n+1 end ; return n
            end)
            if ok and count then say("The AE2 network holds "..fmtNum(count).." distinct item types.")
            else say("ME Bridge offline. Cannot retrieve item data.") end

        elseif cmd == "find" then
            local query = words[3] and words[3]:lower() or nil
            if not query then say("Specify an item. Usage: Jarvis find <item>")
            else
                local ok, result = pcall(function()
                    local list = bridge.listItems()
                    if not list then return nil end
                    local matches = {}
                    for _, item in ipairs(list) do
                        if item.name and item.name:lower():find(query, 1, true) then
                            table.insert(matches, item.name.." x"..fmtNum(item.count or 0))
                            if #matches >= 3 then break end
                        end
                    end
                    return matches
                end)
                if ok and result and #result>0 then say("Found: "..table.concat(result,", ")..".")
                elseif ok and result            then say("No items matching '"..query.."' found.")
                else                                 say("ME Bridge offline. Cannot search items.") end
            end

        elseif cmd == "network" then
            local ok, info = pcall(function()
                local s=bridge.getEnergyStorage() ; local m=bridge.getMaxEnergyStorage()
                local us=bridge.getUsedItemStorage() ; local ts=bridge.getTotalItemStorage()
                if not (s and m and us and ts) or m == 0 or ts == 0 then return nil end
                return string.format("Energy %d%%, Storage %d%% used.",
                    math.floor((s/m)*100), math.floor((us/ts)*100))
            end)
            if ok and info then say("Network status: "..info)
            else say("ME Bridge offline.") end

        elseif cmd == "lite" then
            local sub = words[3] and words[3]:lower() or nil
            if     sub == "on"  then sendToSatellite("campfire", "on")     ; say("Campfire ignited.")
            elseif sub == "off" then sendToSatellite("campfire", "off")    ; say("Campfire doused.")
            else                     sendToSatellite("campfire", "toggle") ; say("Toggling the campfire.")
            end
        elseif cmd == "satellites" then
            local list = {}
            for r, info in pairs(satellites) do
                table.insert(list, r.." (#"..info.id..")")
            end
            if #list > 0 then say("Satellites online: "..table.concat(list, ", ")..".")
            else say("No satellites currently online. Pinging...") ; pingSatellites() end
        elseif cmd == "beep" then
            if spk then pcall(function() spk.playNote("pling",1,12) end) ; say("Beep.")
            else say("No speaker connected.") end

        elseif cmd == "alarm" then
            if spk then say("Sounding alarm!") ; playMelody("alarm")
            else say("No speaker connected.") end

        elseif cmd == "fanfare" then
            if spk then say("Fanfare!") ; playMelody("fanfare")
            else say("No speaker connected.") end

        elseif cmd == "music" then
            if spk then say("Playing a tune.") ; playMelody("music")
            else say("No speaker connected.") end

        elseif cmd == "victory" then
            if spk then say("Victory!") ; playMelody("victory")
            else say("No speaker connected.") end

        elseif cmd == "play" then
            local sound = words[3]
            if not spk then say("No speaker connected.")
            elseif not sound then say("Specify a sound ID. Example: Jarvis play minecraft:entity.wither.spawn")
            else
                local ok = pcall(function() spk.playSound(sound,1,1) end)
                if ok then say("Playing: "..sound) else say("Could not play '"..sound.."'.") end
            end

        elseif cmd == "stop" then
            if spk then pcall(function() spk.stop() end) ; say("Audio stopped.")
            else say("No speaker connected.") end

        elseif cmd == "help"     then say("Commands are displayed on the help monitor.")
        elseif cmd == "pdebug" then
            local pname = words[3]
            if not pname then say("Usage: jarvis pdebug <peripheralName>")
            else
                local t = peripheral.getType(pname)
                if not t then say("'"..pname.."' is not a connected peripheral.")
                else
                    local methods = peripheral.getMethods(pname) or {}
                    print("[JARVIS] "..pname.." (type: "..t.."):")
                    for _, m in ipairs(methods) do print("  "..m) end
                    say(pname.." is a '"..t.."' with "..#methods.." methods (see terminal).")
                end
            end
        elseif cmd == "page" then
            local n = tonumber(words[3])
            if not n then say("Usage: jarvis page <0-15>. Forces a help page.")
            else drawHelpPage(n) ; say("Help page set to "..math.max(0, math.min(15, math.floor(n)))..".")
            end
        elseif cmd == "config" then
            local parts = {}
            for _, r in ipairs({"helpMon","faceMon","energyMon","lightsMon","stoMon","lastMon","clockMon"}) do
                if monNames[r] then
                    local label = r:gsub("Mon$", "")
                    table.insert(parts, label.."="..monNames[r])
                end
            end
            if #parts > 0 then say("Monitors: "..table.concat(parts, ", ")..".")
            else say("No monitors assigned. Check terminal for details.") end
        elseif cmd == "altname" then
            local target = words[3] and words[3]:lower() or nil
            if not target then
                say("Usage: jarvis altname <command>. Lists alternate names.")
            else
                -- If the target is itself a synonym, resolve to canonical first
                local canonical = synonymToCanonical[target] or target
                local alts = synonyms[canonical]
                if alts and #alts > 0 then
                    say("'"..canonical.."' can also be: "..table.concat(alts, ", ")..".")
                else
                    say("'"..target.."' has no alternate names, or isn't a known command.")
                end
            end
        elseif cmd == "shutdown" then
            say("Initiating shutdown sequence. Goodbye.")
            if spk then playMelody("sad") end
            sleep(0.5) ; shutdownDisplay()
            running = false ; return
        else
            say("Unrecognized command: '"..cmd.."'. Check the help monitor.")
        end

        ::continue::
    end
end

-- ─────────────────────────────────────────────
--  Background loops
-- ─────────────────────────────────────────────

local function hudLoop()     while running do drawHUD()     ; sleep(0.2) end end
local function storageLoop() while running do drawStorage() ; sleep(5)   end end
local function clockLoop()   while running do drawClock()   ; sleep(1)   end end
local function energyLoop()  while running do drawEnergy()  ; sleep(5)   end end

-- Reads a "value" from whatever peripheral is wired as the scroller.
-- Duck-typed: tries redstone integrator's getAnalogInput first, then
-- common CC:Create Bridge method names. Returns 0 if nothing works.
local function readScrollerValue()
    if not scrollerRI then return 0 end
    -- 1) Redstone integrator: max analog signal across all sides.
    if scrollerRI.getAnalogInput then
        local maxVal = 0
        for _, side in ipairs(allSides) do
            local ok, v = pcall(scrollerRI.getAnalogInput, side)
            if ok and type(v) == "number" and v > maxVal then maxVal = v end
        end
        if maxVal > 0 then return maxVal end
    end
    -- 2) Common method names on Create/CC:C Bridge peripherals.
    local candidates = {
        "getValue", "getScrollValue", "getScroll",
        "getInput", "getInputCount",
        "getOutput", "getOutputCount", "getOutputSignal",
        "getSignal", "getCount",
    }
    for _, m in ipairs(candidates) do
        if scrollerRI[m] then
            local ok, v = pcall(scrollerRI[m], scrollerRI)
            if ok and type(v) == "number" then return v end
        end
    end
    return 0
end

-- Polls the scroller and redraws the help monitor when the value changes.
-- Prints each new value so you can see your peripheral's actual range.
local function scrollerLoop()
    local lastVal = -1
    while running do
        if scrollerRI then
            local val = readScrollerValue()
            if val ~= lastVal then
                lastVal = val
                print(string.format("[JARVIS] scroller value: %s", tostring(val)))
                drawHelpPage(val)
            end
        end
        sleep(0.5)
    end
end

-- Listens for satellite hellos / pongs and tracks them by role.
local function satelliteLoop()
    while running do
        local id, msg = rednet.receive("jarvis")
        if type(msg) == "table" and (msg.type == "hello" or msg.type == "pong") then
            local satId = msg.id or id
            local known = satellites[msg.role]
            satellites[msg.role] = {id = satId, lastSeen = os.epoch("utc")}
            if not known then
                print("[JARVIS] Satellite online: "..msg.role.." (#"..satId..")")
            end
        end
    end
end

-- ─────────────────────────────────────────────
--  Start
-- ─────────────────────────────────────────────

math.randomseed(os.time())
playMelody("startup")
if box then pcall(function() box.sendMessage("J.A.R.V.I.S online. All systems nominal.", "Jarvis") end) end
pingSatellites()  -- discover any satellites already running

parallel.waitForAny(chatLoop, hudLoop, storageLoop, clockLoop, energyLoop, satelliteLoop, scrollerLoop)
