-- satellites/campfire.lua  —  Animated campfire for a satellite monitor.
-- States: burning → dousing → doused → lighting → burning.
-- Adapts to whatever monitor size is connected.
-- Toggle with M.toggle(); explicit M.setOn() / M.setOff().

local M = {}
M.fps = 8

-- ─── State ─────────────────────────────────────────────
local mon = nil
local W, H = 1, 1
local state = "burning"   -- burning | dousing | doused | lighting
local frame = 0           -- frames since current state began

-- Particle systems
local sparks = {}   -- {x, y, vx, vy, life, max}
local smoke  = {}
local drops  = {}   -- water droplets

-- Animation lengths (in frames)
local DOUSE_LENGTH = 32
local LIGHT_LENGTH = 18

-- ─── Init ──────────────────────────────────────────────
function M.init(monitor)
    mon = monitor
    if not mon then return end
    mon.setTextScale(0.5)
    W, H = mon.getSize()
    mon.setBackgroundColor(colors.black)
    mon.clear()
end

-- ─── State transitions ────────────────────────────────
function M.toggle()
    if state == "burning" or state == "lighting" then
        state = "dousing" ; frame = 0 ; drops = {}
    elseif state == "doused" or state == "dousing" then
        state = "lighting" ; frame = 0 ; smoke = {}
    end
end

function M.setOn()  state = "lighting" ; frame = 0 ; smoke = {} end
function M.setOff() state = "dousing"  ; frame = 0 ; drops = {} end

-- ─── Drawing helpers ──────────────────────────────────
local function px(x, y, char, fg, bg)
    x, y = math.floor(x), math.floor(y)
    if x < 1 or x > W or y < 1 or y > H then return end
    if bg then mon.setBackgroundColor(bg) end
    if fg then mon.setTextColor(fg)       end
    mon.setCursorPos(x, y)
    mon.write(char or " ")
end

local function clearScreen()
    mon.setBackgroundColor(colors.black)
    mon.clear()
end

-- ─── Particles: sparks (rising hot embers) ────────────
local function updateSparks(intensity)
    if math.random() < 0.5 * intensity then
        table.insert(sparks, {
            x = (W + 1) / 2 + (math.random() - 0.5) * (W * 0.4),
            y = H - 2,
            vx = (math.random() - 0.5) * 0.3,
            vy = -0.4 - math.random() * 0.5,
            life = 8 + math.random(0, 6),
            max = 14,
        })
    end
    for i = #sparks, 1, -1 do
        local s = sparks[i]
        s.x = s.x + s.vx
        s.y = s.y + s.vy
        s.vx = s.vx + (math.random() - 0.5) * 0.2
        s.life = s.life - 1
        if s.life <= 0 or s.y < 1 then table.remove(sparks, i) end
    end
end

local function drawSparks()
    for _, s in ipairs(sparks) do
        local frac = s.life / s.max
        local fg = frac > 0.6 and colors.yellow
                or frac > 0.3 and colors.orange
                or colors.red
        local ch = frac > 0.5 and "*" or "."
        px(s.x, s.y, ch, fg, colors.black)
    end
end

-- ─── Particles: smoke (drifting up) ──────────────────
local function updateSmoke(rate)
    rate = rate or 0.4
    if math.random() < rate then
        table.insert(smoke, {
            x = (W + 1) / 2 + (math.random() - 0.5) * (W * 0.5),
            y = H - 2,
            vx = (math.random() - 0.5) * 0.2,
            vy = -0.3,
            life = 18 + math.random(0, 10),
            max = 28,
        })
    end
    for i = #smoke, 1, -1 do
        local s = smoke[i]
        s.x = s.x + s.vx
        s.y = s.y + s.vy
        s.vx = s.vx + (math.random() - 0.5) * 0.15
        s.life = s.life - 1
        if s.life <= 0 or s.y < 1 then table.remove(smoke, i) end
    end
end

local function drawSmoke()
    for _, s in ipairs(smoke) do
        local frac = s.life / s.max
        local fg = frac > 0.6 and colors.lightGray
                or frac > 0.3 and colors.gray
                or colors.black
        local ch = frac > 0.6 and "%" or frac > 0.3 and "~" or "."
        px(s.x, s.y, ch, fg, colors.black)
    end
end

-- ─── Flame body ───────────────────────────────────────
-- Draws a flame body with peak intensity 0..1.
local function drawFlames(intensity)
    if intensity <= 0 then return end
    local flameBase   = H - 1
    local flameHeight = math.max(2, math.floor(H * 0.65 * intensity))
    local flameTop    = math.max(1, flameBase - flameHeight + 1)
    local cx          = (W + 1) / 2

    for y = flameTop, flameBase do
        local heightFromBase = flameBase - y
        local heightFrac     = heightFromBase / math.max(1, flameHeight)
        local maxRadius      = (W * 0.5) * (1 - heightFrac * 0.55)

        for x = 1, W do
            local dx       = math.abs(x - cx)
            local distFrac = (maxRadius > 0) and (dx / maxRadius) or 1
            if distFrac <= 1 then
                local lit = math.random() < (1 - distFrac * 0.7) * intensity
                if lit then
                    local color
                    if heightFrac > 0.7 then
                        color = math.random() < 0.5 and colors.yellow or colors.orange
                    elseif heightFrac > 0.4 then
                        color = colors.orange
                    else
                        color = math.random() < 0.7 and colors.red or colors.orange
                    end
                    px(x, y, " ", colors.yellow, color)
                end
            end
        end
    end
end

-- ─── Logs (bottom row) ────────────────────────────────
local function drawLogs(wet)
    local bg = wet and colors.gray or colors.brown
    mon.setCursorPos(1, H)
    mon.setBackgroundColor(bg)
    mon.setTextColor(colors.black)
    mon.write(string.rep("=", W))
    -- Embers on dry logs
    if not wet then
        for x = 1, W do
            if math.random() < 0.22 then
                local fg = math.random() < 0.5 and colors.red or colors.orange
                px(x, H, math.random() < 0.5 and "*" or "+", fg, colors.brown)
            end
        end
    end
end

-- ─── State drawers ────────────────────────────────────
local function drawBurning()
    clearScreen()
    drawFlames(1.0)
    updateSparks(1.0) ; drawSparks()
    drawLogs(false)
end

local function drawDoused()
    clearScreen()
    updateSmoke(0.35) ; drawSmoke()
    drawLogs(true)
end

local function drawDousing()
    clearScreen()
    -- Spawn falling water drops in the first 60% of the dousing animation
    if frame < DOUSE_LENGTH * 0.6 and math.random() < 0.65 then
        table.insert(drops, {
            x = (W + 1) / 2 + (math.random() - 0.5) * (W * 0.7),
            y = 1,
            vy = 0.8 + math.random() * 0.6,
        })
    end
    -- Update + draw drops, splash → steam when they hit the logs
    for i = #drops, 1, -1 do
        local d = drops[i]
        d.y = d.y + d.vy
        if d.y >= H - 1 then
            for _ = 1, 2 + math.random(0, 2) do
                table.insert(smoke, {
                    x = d.x + (math.random() - 0.5) * 2,
                    y = H - 2,
                    vx = (math.random() - 0.5) * 0.5,
                    vy = -0.35,
                    life = 14 + math.random(0, 8),
                    max = 22,
                })
            end
            table.remove(drops, i)
        else
            px(d.x, d.y, "|", colors.lightBlue, colors.black)
        end
    end
    -- Diminishing flames
    local flameIntensity = math.max(0, 1 - (frame / (DOUSE_LENGTH * 0.7)))
    drawFlames(flameIntensity)
    -- Sparks fading
    updateSparks(flameIntensity * 0.6) ; drawSparks()
    -- Smoke (existing + spawned by splashes)
    updateSmoke(0.1) ; drawSmoke()
    -- Logs darken as the fire dies
    drawLogs(flameIntensity < 0.3)

    if frame >= DOUSE_LENGTH then
        state = "doused" ; frame = 0 ; drops = {}
    end
end

local function drawLighting()
    clearScreen()
    local intensity = math.min(1, frame / LIGHT_LENGTH)
    drawFlames(intensity)
    updateSparks(intensity * 0.7 + 0.3) ; drawSparks()
    drawLogs(false)
    if frame >= LIGHT_LENGTH then
        state = "burning" ; frame = 0
    end
end

-- ─── Public draw ──────────────────────────────────────
function M.draw()
    if not mon then return end
    if     state == "burning"  then drawBurning()
    elseif state == "dousing"  then drawDousing()
    elseif state == "doused"   then drawDoused()
    elseif state == "lighting" then drawLighting()
    end
    frame = frame + 1
end

return M
