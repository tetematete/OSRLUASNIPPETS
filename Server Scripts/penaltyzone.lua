local cubic = require('shared/math/cubic')
ac.debug("!version", "penaltyZone v0.5")

--If you intend to modify this script, leave these in. 
ac.debug("URL", "https://github.com/tetematete/OSRLUASNIPPETS/tree/main")
ac.debug("Credit", "original script by tetematete, co-owner of OSR. \nTo race with us, support us, or find more scripts like this one,\n follow the link below.")
--I mean it :)

car = ac.getCar(0)
sim = ac.getSim()


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

--Zone Initialization
local encoded = chevron:encode()
local penaltyZoneSpeed = 80
local penZoneLength = 0
local hitbox = 2
local offset = 0
local size = 0.250
local dist = 2
local age = 0.5
local spl = {}
local noVisuals = false
local arrowColor = rgbm(1,1, 1, 1)
local active = false
local tempConfig 
local rotation = 90
local collecting = 0

--Cut Initialization
local cutWarnings = 0
local warnsPerDT = 3
local wheelsOut = 3
local minSpeed = 40
local cutCD = 2
local maxTime = 5
local slowDownRatio = 0.9
local bonusTime = 5
local warn
local bigZones = {
    --{pos=vec3(-128.31210327148,-3.1868286132813,-560.48510742188), size=40, speed=80, warns = 3, helper = render.PositioningHelper({ skipAxis = { 'y' } })},
    --{pos=vec3(-60.31210327148,-3.1868286132813,-560.48510742188), size=20, speed=80, warns = 3, helper = render.PositioningHelper({ skipAxis = { 'y' } })}
}

local function makePaint()
    
        paint:reset()
    if not noVisuals then
        paint:age(age)
        local tab = {}
        for index, value in ipairs(spl) do
            table.insert(tab, spl[index].pos)
        end
        --ac.debug("points", tab)
        local pts = cubic.vec(tab)
        penZoneLength = pts.length()
        for i = 0, 1, (3 * 0.01) / pts.length() do
            local degree = ac.getCompassAngle(pts.get(i) - pts.get(i + 0.001))
            --ac.log(degree)

            --paint:arrow(pts.get(i), vec2(1,1), degree+90)
            --paint:image(ui.decodeImage(encoded), pts.get(i), 5 * size, degree + rotation, arrowColor)
            paint:to(pts.get(i))
        end
        paint:strokeDash({0.5*dist,0.5*dist})
        paint:stroke(false, arrowColor, size)
    end
end

local testa = ac.INIConfig.parse([[

]], ac.INIFormat.Extended)


--==============================================================================
--      Load server spline settings
--==============================================================================
ac.onOnlineWelcome(function(message, config)
    --config = testa
    -------------------Penalty Zone Settings
    local sec = "ZONECONFIG"
    offset = config:get(sec, "OFFSET", 0)
    for index, key in config:iterateValues(sec, "POINT", true) do
        local pos = config:get(sec, key, vec3())
        local track = ac.worldCoordinateToTrack(pos)
            track.x = track.x + offset
            track = ac.trackCoordinateToWorld(track)
        table.insert(spl, { pos = pos, helper = render.PositioningHelper({ skipAxis = { 'y' } }), collected=false , hitpos=track})
    end
    hitbox = config:get(sec, "HITBOX", 2)
    size = config:get(sec, "SIZE", 0.250)
    dist = config:get(sec, "DIST", 2)
    age = config:get(sec, "AGE", 0.5)
    rotation = config:get(sec, "ROTATION", 90)
    arrowColor = config:get(sec, "COLOR", rgbm(1, 1, 1, 1))
    penaltyZoneSpeed = config:get(sec, "SPEED_LIMIT", 80)

    sec = "CUTSETTINGS"
    warnsPerDT= config:get(sec, "WARNS_PER_DT", 3)
    wheelsOut= config:get(sec, "WHEELS_ALLOWED_OUT", 3)
    minSpeed = config:get(sec, "MIN_SPEED", 40)
    cutCD = config:get(sec, "CUT_CD", 2)
    maxTime = config:get(sec, "CUT_TIMEOUT", 5)
    slowDownRatio = config:get(sec, "SLOWDOWN_RATIO", 0.9)
    bonusTime = config:get(sec, "BONUS_TIME", 2)

    sec = "CUTZONE"
    local tab = {}
    for index, key in config:iterateValues(sec, "POINT", true)do
        local pos = config:get(sec, key, vec3())
        local data = config:get(sec, "DATA_"..index-1, vec3())
        table.insert(bigZones, {pos = pos, size = data.x, speed = data.y, warns = data.z, helper = render.PositioningHelper({ skipAxis = { 'y' }})})
    end
    if #spl > 3 then
        makePaint()
    end
    permittedUses = 3
    collectedPoints = 0
    ---------------PENALTY CUT Settings


    active = true
end)


--==============================================================================
--          Spline Creation and Export Tool
--==============================================================================
local selectedTab = 1

ui.registerOnlineExtra(ui.Icons.Pitlane, "Penalty Zone Maker", nil, function()
    local offtrue, hittrue, sizetrue, disttrue, agetrue,rotationtrue = false, false, false, false, false, false
    showDebug = true
    active = true
    ui.tabBar('Admin Panel', function()
        ui.tabItem("Zone Editor", function () -----------------------------------ZONE EDITOR
            selectedTab = 1
        
        ui.columns(2, true, "Columntest")
        offset, offtrue = ui.slider("offset", offset, -1, 1)
        --if ui.checkbox("No Visuals", noVisuals) then noVisuals = not noVisuals makePaint() end
        hitbox, hittrue = ui.slider("hitbox", hitbox, 0.5, 3)
        size, sizetrue = ui.slider("size", size, 0.05, 0.5)
        dist, disttrue = ui.slider("dist", dist, 0.01, 3)
        age, agetrue = ui.slider("age", age, 0, 1)
        penaltyZoneSpeed = ui.slider("Speed Limit", penaltyZoneSpeed, 25, 100, '%.0fKmh')
        --rotation, rotationtrue = ui.slider("rotation", rotation, 0, 360)
        if sizetrue or disttrue or agetrue or rotationtrue or offtrue then
            makePaint()
            for index, value in ipairs(spl) do
                local track = ac.worldCoordinateToTrack(value.pos)
                track.x = track.x + offset
                track = ac.trackCoordinateToWorld(track)
                value.hitpos = track
            end
        end

        if ui.hotkeyShift() and ui.mouseClicked(ui.MouseButton.Left) then
            local ray = render.createMouseRay()
            local pos = vec3()
            if physics.raycastTrack(ray.pos, ray.dir, math.huge, pos) ~= -1 then
                ac.log(pos)
                local track = ac.worldCoordinateToTrack(pos)
                track.x = track.x + offset
                track = ac.trackCoordinateToWorld(track)
                table.insert(spl,
                    { pos = pos, helper = render.PositioningHelper({ skipAxis = { 'y' } }), collected = false, hitpos =
                    track })
                if #spl > 3 then
                    makePaint()
                end
            end
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
        ui.nextColumn()
        if ui.colorPicker("Arrow Color", arrowColor, ui.ColorPickerFlags.AlphaBar) then makePaint() end
        ui.text("Estimated Drive Through Time:\n " .. math.round(penZoneLength / (penaltyZoneSpeed*0.2777778),2) .. " seconds\nLength: " .. math.round(penZoneLength,2) .."m"  )
        ui.nextColumn()

        end)
        ui.tabItem("Cut Settings", function () ----------------------- CUT SETTINGS
        local cutWarnings = 0
        warnsPerDT = ui.slider("Warns Per DT", warnsPerDT, 1, 10, '%.0f')
        wheelsOut = ui.slider("Wheels Allowed Out", wheelsOut, 1, 4, '%.0f')
        minSpeed = ui.slider("Minimum Cut Speed", minSpeed, 0,100, '%.0fKmh')
        cutCD = ui.slider("Cooldown Between Cuts", cutCD, 0, 10, '%.0f sec')
        maxTime = ui.slider("Cut Timeout", maxTime, 1,15, '%.0f sec')
        slowDownRatio = ui.slider("Slowdown Ratio", slowDownRatio, 0, 2, '%.2f * exit speed')
        bonusTime = ui.slider("Bonus Time", bonusTime, 0, 10, '%.0f sec')    
        end)


        ui.tabItem("Cut Editor", function () -------------------------------------------- CUT EDITOR
        
            selectedTab = 2
            ui.columns(2,true)
            for index, zone in ipairs(bigZones) do
                if ui.menuItem(index, index == ui.loadStoredNumber(1,1)) then
                    ui.storeNumber(1, index)
                end
                
            end
            ui.text("Shift+Click to add a zone!")
            ui.nextColumn()
            if #bigZones > 0 then
                local zoneRef = bigZones[ui.loadStoredNumber(1,1)]
                zoneRef.size = ui.slider("Zone Size", zoneRef.size, 1, 200, '%.1fm' )
                zoneRef.speed = ui.slider("Re-Entry Speed Override", zoneRef.speed, 0 ,200, '%.0f Kmh')
                zoneRef.warns = ui.slider("Warnings", zoneRef.warns, 0,12, '%.0f')
                if ui.button("Delete Zone") then
                    table.remove(bigZones, ui.loadStoredNumber(1,1))
                    ui.storeNumber(1,ui.loadStoredNumber(1,1)-1)
                end
            end
            
            
        if ui.hotkeyShift() and ui.mouseClicked(ui.MouseButton.Left) then
            local ray = render.createMouseRay()
            local pos = vec3()
            if physics.raycastTrack(ray.pos, ray.dir, math.huge, pos) ~= -1 then
                ac.log(pos)
                local track = ac.worldCoordinateToTrack(pos)
                track.x = track.x + offset
                track = ac.trackCoordinateToWorld(track)
                table.insert(bigZones,
                    { pos = pos, helper = render.PositioningHelper({ skipAxis = { 'y' } }), size = 20, warns = 3, speed=50 })
                    ui.storeNumber(1, #bigZones)
                    
            end
            
        end            
            
    
        end)


        ui.columns(1) ------------------------------------------------------------ CONFIG EXPORTER
        ui.separator()
        if ui.button("Export Current") then
            local config = ac.INIConfig(ac.INIFormat.Extended, { ZONECONFIG = {}, CUTSETTINGS={}, CUTZONE={} })

            local sec = "ZONECONFIG"
            for index, value in ipairs(spl) do
                config:set(sec, "POINT_" .. index - 1, value.pos)
            end
            config:set(sec, "HITBOX", hitbox)
            config:set(sec, "OFFSET", offset)
            config:set(sec, "COLOR", arrowColor)
            config:set(sec, "SIZE", size)
            config:set(sec, "DIST", dist)
            config:set(sec, "AGE", age)
            config:set(sec, "SPEED_LIMIT", penaltyZoneSpeed)

            sec = "CUTSETTINGS"
            config:set(sec, "WARNS_PER_DT", warnsPerDT)
            config:set(sec, "WHEELS_ALLOWED_OUT", wheelsOut)
            config:set(sec, "MIN_SPEED", minSpeed)
            config:set(sec, "CUT_CD", cutCD)
            config:set(sec, "CUT_TIMEOUT", maxTime)
            config:set(sec, "SLOWDOWN_RATIO", math.round(slowDownRatio,2))
            config:set(sec, "BONUS_TIME", bonusTime)
  
            sec = "CUTZONE"
            for index, value in ipairs(bigZones) do
                config:set(sec, "POINT_" .. index - 1, value.pos)
                config:set(sec, "DATA_" .. index - 1, vec3(value.size, value.speed, value.warns))
            end

            ac.log(config:serialize())
            ac.setClipboardText(config:serialize())
            tempConfig = config:serialize()
        end

        
        if tempConfig ~= nil then
            ui.inputText("##CONFIG", tempConfig, ui.InputTextFlags.None, ui.availableSpace())
        end

    end)
end, function (okClicked)
    showDebug = false
    
end, ui.OnlineExtraFlags.Tool)

--==============================================================================
-- Script Constant update Logic
--==============================================================================
local collectedPoints = 0
local permittedUses = 3
--[[local prevPos = ac.worldCoordinateToTrack(car.position)
prevPos.x = 0
prevPos = ac.trackCoordinateToWorld(prevPos)
        setInterval(function()
            local pos = ac.worldCoordinateToTrack(car.position)
            ac.debug("b", pos)
            pos.x = 0
            --ac.debug("ROC", ((car.splinePosition-prevPos)*sim.trackLengthM)*36 , 0,math.huge)
            pos = ac.trackCoordinateToWorld(pos)
            ac.debug("track", (pos:distance(prevPos) * 36)-car.speedKmh , 0,math.huge, 50)
            ac.debug("world", pos)
            prevPos = pos

        end, 0.1, "a")]]

local cutChecker = -1
local timeoutChecker = -1
local bonusChecker = -1
local isCut = false
local wasCut = false
local cutStatus = 1
local outSpeed = 0
local returnSpeed = 0
local canWarn = true
local bigZone = 0

local inZone = 0
function script.update(dt)

    --[[if car.wheelsOutside > wheelsOut then
        cutChecker = setInterval(function ()
        if car.wheelsOutside <= wheelsOut then
            setTimeout(function ()
                clearInterval(cutChecker)
                cutChecker = -1
            end, bonusTime, "cutKiller")
        end
        end, 0, "alwaysWatching")
        ac.debug("out", true)

    else
        ac.debug("out", false)
    end]]
    inZone = 0
    for index, zone in ipairs(bigZones) do
        if car.position:distance(zone.pos) < zone.size then
            inZone = index
        end
    end
    
    if ((car.wheelsOutside > wheelsOut and car.speedKmh > minSpeed) or inZone > 0) and ((not wasCut) and canWarn) then
        isCut = true
        canWarn = false
    end

    if isCut and not wasCut then

        clearTimeout(timeoutChecker)
        clearTimeout(bonusChecker)
        ac.log("Left Track")
        outSpeed = car.speedKmh
        returnSpeed = outSpeed*slowDownRatio
        warn = 1
        cutChecker = setInterval(function()
        if inZone > 0 then
            ac.markLapAsSpoiled()
            if bigZones[inZone].speed > 0 then
                returnSpeed = bigZones[inZone].speed 
            end
            warn = bigZones[inZone].warns
            clearTimeout(timeoutChecker)
        end

            if (car.wheelsOutside <= wheelsOut and inZone == 0) then
                
                if car.speedKmh <= returnSpeed then
                    ac.log("Back No Warning")
                    clearInterval(cutChecker)
                    isCut = false
                end
                bonusChecker = setTimeout(function()
                    clearInterval(cutChecker)
                    if not (car.speedKmh <= returnSpeed) and isCut then
                        ac.log("Warning!")
                        cutWarnings = cutWarnings + warn
                    end
                    isCut = false
                end, bonusTime, "BonusTimer")
            end
        end, 0, "weweweewewewe")

        timeoutChecker = setTimeout(function ()
            if car.wheelsOutside > wheelsOut then
                ac.log("Cut Timed Out")
                returnSpeed = 999   
            end
        end, maxTime, "timeout")
    end

         if wasCut and not isCut then
            setTimeout(function ()

                canWarn = true
            end, cutCD, "jfdkslfjsdkl")
        end

    wasCut = isCut
    --ac.debug("check", isCut)
    --ac.debug("outSpeed", outSpeed)
    --ac.debug("return", returnSpeed)


    if active and not (#spl == 0) and cutWarnings >= 3 then
        if collectedPoints == #spl then
            allCollected()
        else
            if collectedPoints < #spl and spl[collectedPoints+1].hitpos:distance(car.position) < hitbox then
                if (car.speedKmh < penaltyZoneSpeed + 3) then
                spl[collectedPoints + 1].collected = true
                collectedPoints = collectedPoints + 1
                else
                    
                end
                
            end
        end
    end

    
end
--==============================================================================
-- SCRIPT UI
--==============================================================================

local warnColor = { rgbm(1,1,1,1) , rgbm.colors.red, rgbm.colors.orange, rgbm.colors.green}

ac.log(winSize)

function script.drawUI()
    local winSize = ui.windowSize()
    local xScale = 300
    
    
    ui.drawRectFilled(vec2(winSize.x/2 - xScale, 0), vec2(winSize.x/2 + xScale, 75), warnColor(), 5)
    ui.setCursor(vec2(ui.windowWidth()/2 - 100 ,45))
    ui.pushFont(ui.Font.Monospace)
    ui.pushStyleColor(ui.StyleColor.Text, rgbm.colors.black)
    ui.beginScale()
    ui.text("WARNINGS: "..cutWarnings .. "   ZONES REMAINING: " .. math.floor(cutWarnings/warnsPerDT))
    ui.endScale(2)
    
end
--==============================================================================
---------------- 3D Update function, for showing hitbox and positioning helpers
--==============================================================================
local helperGrabbed = false
function script.draw3D()
    if showDebug then
        if selectedTab == 1 then
            for index, val in ipairs(spl) do
                local track = ac.worldCoordinateToTrack(val.pos)
                track.x = track.x + offset
                track = ac.trackCoordinateToWorld(track)
                render.debugSphere(track, hitbox, val.collected and rgbm.colors.green or nil)
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
        if selectedTab == 2 then
            for index, zone in ipairs(bigZones) do
                render.setDepthMode(render.DepthMode.Off)
                render.setCullMode(render.CullMode.None)
                render.circle(zone.pos, vec3(0,1,0), zone.size, rgbm(1,0,0,1))
                render.debugText(zone.pos, index .. ". Warns: ".. zone.warns .."\nSpeed: ".. zone.speed, rgbm.colors.white, 2)
                                zone.helper:render(zone.pos)
                render.debugText(zone.pos, index)
            end
        end
    end
end

--==============================================================================
-- Reset, Complete Lap callbacks
--==============================================================================
function warnColor()
    local color
    local difference = car.speedKmh-returnSpeed
    --ac.debug("col", 1-difference)
    
    if isCut then
        --color = rgbm(difference+0.5 ,2-difference*2 ,0 ,1)
        if difference > 20 then
            color = rgbm.colors.red
        elseif difference > 0 then
            color = rgbm.colors.yellow
        else
            color = rgbm.colors.green
        end
    elseif cutWarnings >= warnsPerDT then
        color = rgbm.colors.orange
    else


        color = rgbm.colors.gray
    end

    return color
end

function reset() --reset function, 

    setTimeout(function ()
        cutWarnings = 0
        resetCollected()
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
    cutWarnings = cutWarnings - 3   
    resetCollected()
end
