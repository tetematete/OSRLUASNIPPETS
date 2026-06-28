local cubic = require('shared/math/cubic')
ac.debug("!version", "attackmode v1")

--If you intend to modify this script, leave these in. 
ac.debug("URL", "https://github.com/tetematete/OSRLUASNIPPETS/tree/main")
ac.debug("Credit", "original script by tetematete, co-owner of OSR. \nTo race with us, support us, or find more scripts like this one,\n follow the link below.")
--I mean it :)

car = ac.getCar(0)
sim = ac.getSim()
local kersbutton = ac.ControlButton("KERS")
kersbutton:setDisabled(true)
ac.setKERS(false)

local paint = ac.TrackPaint()
local showDebug  
local chevron = ui.ExtraCanvas(500, 1):setName("chev"):update(function(dt)
    ui.pathLineTo(vec2(250, 250))
    ui.pathLineTo(vec2(500, 400))
    ui.pathLineTo(vec2(500, 250))
    ui.pathLineTo(vec2(250, 100))
    ui.pathLineTo(vec2(0, 250))
    ui.pathLineTo(vec2(0, 400))
    ui.pathFillConvex(rgbm.colors.white)
    --ui.pathStroke(rgbm.colors.red,false, 5)
end)

local encoded = chevron:encode()
local hitbox = 1
local offset = 0
local size = 1
local dist = 1
local spl = {}
local active = false
local tempConfig 

local function makePaint()
    paint:reset()
    local tab = {}
    for index, value in ipairs(spl) do
        table.insert(tab, spl[index].pos)
    end
    --ac.debug("points", tab)
    local pts = cubic.vec(tab)

    for i = 0, 1, (3*dist) / pts.length() do
        local degree = ac.getCompassAngle(pts.get(i) - pts.get(i + 0.001))
        --ac.log(degree)

        --paint:arrow(pts.get(i), vec2(1,1), degree+90)
        paint:image(ui.decodeImage(encoded), pts.get(i), 5*size, degree + 90, rgbm(0.4, 0.8, 1, 1))
    end
end

local testa = ac.INIConfig.parse([[
[ATTACKMODE]
POINT_0=112.65518188477,0.78796672821045,-842.85900878906
OFFSET=0
POINT_3=170.95404052734,1.1461935043335,-854.06195068359
POINT_2=160.42752075195,1.0953969955444,-850.65606689453
POINT_1=139.10534667969,0.95912742614746,-846.13781738281
HITBOX=1.3159999847412
SIZE = 1
DIST = 1
]], ac.INIFormat.Extended)


--==============================================================================
--      Load server spline settings
--==============================================================================
ac.onOnlineWelcome(function(message, config)
    --config = testa

    for index, key in config:iterateValues("ATTACKMODE", "POINT", true) do
        local pos = config:get("ATTACKMODE", key, vec3())
        table.insert(spl, { pos = pos, helper = render.PositioningHelper({ skipAxis = { 'y' } }), collected=false })
    end
    hitbox = config:get("ATTACKMODE", "HITBOX", 1)
    offset = config:get("ATTACKMODE", "OFFSET", 0)
    size = config:get("ATTACKMODE", "SIZE", 1)
    dist = config:get("ATTACKMODE", "SIZE", 1)
    
    --ac.log(config:serialize())
    if #spl > 3 then
        makePaint()
    end
    permittedUses = 3
    collectedPoints = 0

    active = true
end)


--==============================================================================
--          Spline Creation and Export Tool
--==============================================================================
ui.registerOnlineExtra(ui.Icons.Pitlane, "attackMode", nil, function()
    local offtrue, hittrue, sizetrue, disttrue = false, false, false, false
    showDebug = true
    active = true
    --offset, offtrue = ui.slider("offset", offset, -1, 1)
    hitbox, hittrue = ui.slider("hitbox", hitbox, 0.5, 3)
    size, sizetrue = ui.slider("size", size, 0.5, 3)
    dist,disttrue = ui.slider("dist", dist, 0.5, 3)

    if sizetrue or disttrue then
        makePaint()
    end
    if ui.hotkeyShift() and ui.mouseClicked(ui.MouseButton.Left) then
        local ray = render.createMouseRay()
        local pos = vec3()
        if physics.raycastTrack(ray.pos, ray.dir, math.huge, pos) ~= -1 then
            ac.log(pos)
            table.insert(spl, { pos = pos, helper = render.PositioningHelper({ skipAxis = {'y'} }), collected=false })
            if #spl > 3 then
                makePaint()
            end
        end
    end

    if ui.button("Export Current") then
        local config = ac.INIConfig(ac.INIFormat.Extended, {ATTACKMODE={}})
        for index, value in ipairs(spl) do
            config:set("ATTACKMODE", "POINT_" .. index-1, value.pos)
        end
        config:set("ATTACKMODE", "HITBOX", hitbox)
        --config:set("ATTACKMODE", "OFFSET", offset)
        config:set("ATTACKMODE", "SIZE", size)
        config:set("ATTACKMODE", "DIST", dist)
        ac.log(config:serialize())
        ac.setClipboardText(config:serialize())
        tempConfig = config:serialize()
    end

    for index, value in ipairs(spl) do
        ui.text(index .. ": " .. tostring(value.pos))
        if ui.itemHovered(ui.HoveredFlags.None) then
            ui.itemUnderline()
        end

        if ui.itemClicked(ui.MouseButton.Left) then
            table.remove(spl, index)
            makePaint()
        end
    end


    if #spl > 3 then
    else
        ui.text("4 Points Required, shift + click to add a point")
    end
    ui.separator()

    if tempConfig ~= nil then 
        ui.inputText("CONFIG", tempConfig, ui.InputTextFlags.None, ui.availableSpace())
    end

end, function (okClicked)
    showDebug = false
    
end, ui.OnlineExtraFlags.Tool)
--==============================================================================
-- 3D Update function, for showing hitbox and positioning helpers
--==============================================================================
local helperGrabbed = false
function script.draw3D()
    if showDebug then
        for index, val in ipairs(spl) do
            local track = ac.worldCoordinateToTrack(val.pos)
            track.x = track.x + offset
            render.debugSphere(ac.trackCoordinateToWorld(track), hitbox, val.collected and rgbm.colors.green or nil)
            
        end
        for index, val in ipairs(spl) do
            val.helper:render(val.pos)
            render.debugText(val.pos, index)
        end
        
        render.debugText(car.position, "Car Hitbox")
        if not render.isPositioningHelperBusy() and helperGrabbed and #spl > 3 then
            makePaint()
        end

        helperGrabbed = render.isPositioningHelperBusy()
    end
end

--==============================================================================
-- Script Constant update Logic
--==============================================================================
local collectedPoints = 0
local permittedUses = 3
function script.update(dt)
--ac.debug("a", car.p2pStatus)
    if active and not (#spl == 0) then
        if collectedPoints == #spl then
            allCollected()
        else
            if collectedPoints < #spl and spl[collectedPoints + 1].pos:distance(car.position) < hitbox then
                spl[collectedPoints + 1].collected = true
                collectedPoints = collectedPoints + 1
            end
        end

        if car.p2pActivations < permittedUses and car.p2pStatus == 3 then --anticheat system, if a user has an external app to turn on push to pass when it is not permitted, force clutch to negate power gain
            physics.forceUserClutchFor(60, 0.4)
            permittedUses = permittedUses - 1
        end
    end
end

--==============================================================================
-- Reset, Complete Lap callbacks
--==============================================================================

function reset() --reset function, 

    ac.setKERS(false)
    setTimeout(function ()
    resetCollected()
    --[[local session = ac.getSession(sim.currentSessionIndex)  --This is all commented out because I realized that 1. the kersbutton setdisabled only works once for whatever reason. 2. There isnt even p2p in quali lmao
    if not(session.type == ac.SessionType.Race) then
        active = false
        ac.log(session.type)
        --kersbutton:setDisabled(false)
    else
        active = true
        --kersbutton:setDisabled(true)
    end]]
    end, 1, "reset")
    physics.forceUserClutchFor(0,1) --Disables any clutch forcing
end


ac.onSessionStart(function (sessionIndex, restarted)
reset()
end)
reset()


ac.onLapCompleted(0, function (carIndex, lapTime, valid, cuts, lapCount)
    resetCollected()
end)

function resetCollected()
    collectedPoints = 0
    for index, point in ipairs(spl) do
        point.collected = false
    end
end

function allCollected()   
    if car.p2pStatus == 2 then
        permittedUses = permittedUses - 1
        setTimeout(function()
            ac.setKERS(true)
        end, 1, "kersEnable")
        ac.log("all collected!")

        setTimeout(function()
            ac.setKERS(false)
        end, 5, "kersDisable")
    end
    resetCollected()
end

