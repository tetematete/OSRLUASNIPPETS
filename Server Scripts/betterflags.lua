local SIM = ac.getSim()
local CAR = ac.getCar(SIM.focusedCar)

local betterFlagSettings = ac.storage({
    flagWindowX=0,
    flagWindowY=0,
    flagWindowScale=1,
    flagWindowPos=vec2(0,0),
    flagWindowPinned=false
})
--betterFlagSettings.flagWindowPos = vec2(0,0)
local isWarning = false
local timeWarningStarted = 0 --Warning Variables
local slowCar = false
local slowCarTimer = 0
--ui init
local settingsOverride = false
local windowWidth, windowHeight = ac.getSim().windowWidth,ac.getSim().windowHeight
local uiScale = ac.getUI().uiScale
local testGameState = false
local code60Timing = 0
local code60Grace = 0
local enabled = false
local selfCar = ac.getCar(0)

local flagDragging = false
local flagStartPos = betterFlagSettings.flagWindowPos


local tempSettings = betterFlagSettings

ac.blockSystemMessages("$CSP0:")

ac.onOnlineWelcome(function(message, config) --Reads the script config from the extra options

    parsedConfig = tostring(config)
    configCheck = config:mapSection("BETTERFLAGS", { NO_OVERTAKE_ZONE_1 = {0,0}, NO_OVERTAKE_ZONE_2 = {0,0}, NO_OVERTAKE_ZONE_3 = {0,0}})

    --ac.debug("config", configCheck)

    noOvertake1_S,noOvertake1_E = config:get("BETTERFLAGS", "NO_OVERTAKE_ZONE_1", 0), config:get("BETTERFLAGS", "NO_OVERTAKE_ZONE_1", 0,2)
    noOvertake2_S,noOvertake2_E = config:get("BETTERFLAGS", "NO_OVERTAKE_ZONE_2", 0), config:get("BETTERFLAGS", "NO_OVERTAKE_ZONE_2", 0,2)
    noOvertake3_S,noOvertake3_E = config:get("BETTERFLAGS", "NO_OVERTAKE_ZONE_3", 0), config:get("BETTERFLAGS", "NO_OVERTAKE_ZONE_3", 0,2)
    noOvertakeZones = config:tryGetLut("BETTERFLAGS", "NO_OVERTAKE") if noOvertakeZones == nil then noOvertakeZones = ac.DataLUT11():add(noOvertake1_S, 1):add(noOvertake1_E, 0):add(noOvertake2_S, 1):add(noOvertake2_E, 0):add(noOvertake3_S, 1):add(noOvertake3_E, 0) end
    meatballThreshold = config:get("BETTERFLAGS", "MEATBALL_THRESHOLD", 0.10)
    slowCarFlagPersist = (config:get("BETTERFLAGS", "SLOW_CAR_FLAG_PERSIST", 1.1))*1000
    slowCarDistanceBehind, slowCarDistanceAhead = (config:get("BETTERFLAGS", "SLOW_CAR_WARN_DISTANCE", 500,1)), (config:get("BETTERFLAGS", "SLOW_CAR_WARN_DISTANCE", 100,2))
    slowCarSpeed = (config:get("BETTERFLAGS", "SLOW_CAR_SPEED", 35))
    slowCarPenalties, code60Timer = (config:get("BETTERFLAGS", "SLOW_CAR_PENALTY", -1,1)),(config:get("BETTERFLAGS", "SLOW_CAR_PENALTY", 5,2)) -- -1 for none, 0 for chat warning, above for drive through in n laps. Above -1 makes the flag code60 instead.
    enablePhysicsFlags = config:get("BETTERFLAGS", "ENABLE_PHYSICS_FLAGS", 1)

    --ac.log("Slow Car Test Stuff:")
    --ac.log(slowCarDistanceBehind, slowCarDistanceAhead)
    --ac.log(slowCarPenalties, code60Timer)

    enabled = true
end)

ac.debug("!version", "betterflags v0.8")

if sim.isTripleMode then 
        tripleOffset = -(ac.getSim().windowWidth*ac.getTripleConfiguration().screens[1].xWidth)
    ac.debug("a", ac.getTripleConfiguration().screens[1].xWidth)
    ac.debug("screen", tripleOffset)
else
    tripleOffset = 0
end


local function makeFlags()

    startFlag = ui.ExtraCanvas(vec2(256,256))
    --startFlag = ui.ExtraCanvas(ac.getSim().windowSize)
    startFlag:setName("startFlag")
    startFlag:update(function (dt)
        ui.beginTransformMatrix()
        ui.drawRaceFlag(ac.FlagType.Start)
        ui.endTransformMatrix(mat3x3(vec3(1,0, tripleOffset),vec3(0,1,0),vec3(0,0,1)))
    end)

    cautionFlag = ui.ExtraCanvas(vec2(256,256)) 
    cautionFlag:setName("cautionFlag")
    cautionFlag:update(function (dt)
        ui.beginTransformMatrix()
        ui.drawRaceFlag(ac.FlagType.Caution)
        ui.endTransformMatrix(mat3x3(vec3(1,0, tripleOffset),vec3(0,1,0),vec3(0,0,1)))
    end)

    slipperyFlag = ui.ExtraCanvas(vec2(256,256)) 
    slipperyFlag:setName("slipperyFlag")
    slipperyFlag:update(function (dt)
        ui.beginTransformMatrix()
        ui.drawRaceFlag(ac.FlagType.Slippery)
        ui.endTransformMatrix(mat3x3(vec3(1,0, tripleOffset),vec3(0,1,0),vec3(0,0,1)))
    end)

    blackFlag = ui.ExtraCanvas(vec2(256,256)) 
    blackFlag:setName("blackFlag")
    blackFlag:update(function (dt)
        ui.beginTransformMatrix()
        ui.drawRaceFlag(ac.FlagType.Stop)
        ui.endTransformMatrix(mat3x3(vec3(1,0, tripleOffset),vec3(0,1,0),vec3(0,0,1)))
    end)

    whiteFlag = ui.ExtraCanvas(vec2(256,256)) 
    whiteFlag:setName("whiteFlag")
    whiteFlag:update(function (dt)
        ui.beginTransformMatrix()
        ui.drawRaceFlag(ac.FlagType.SlowVehicle)
        ui.endTransformMatrix(mat3x3(vec3(1,0, tripleOffset),vec3(0,1,0),vec3(0,0,1)))
    end)

    ambulanceFlag = ui.ExtraCanvas(vec2(256,256)) 
    ambulanceFlag:setName("ambulanceFlag")
    ambulanceFlag:update(function (dt)
        ui.beginTransformMatrix()
        ui.drawRaceFlag(ac.FlagType.Ambulance)
        ui.endTransformMatrix(mat3x3(vec3(1,0, tripleOffset),vec3(0,1,0),vec3(0,0,1)))
    end)

    blackWhiteFlag = ui.ExtraCanvas(vec2(256,256)) 
    blackWhiteFlag:setName("blackWhiteFlag")
    blackWhiteFlag:update(function (dt)
        ui.beginTransformMatrix()
        ui.drawRaceFlag(ac.FlagType.ReturnToPits)
        ui.endTransformMatrix(mat3x3(vec3(1,0, tripleOffset),vec3(0,1,0),vec3(0,0,1)))
    end)

    meatballFlag = ui.ExtraCanvas(vec2(256,256)) 
    meatballFlag:setName("meatballFlag")
    meatballFlag:update(function (dt)
        ui.beginTransformMatrix()
        ui.drawRaceFlag(ac.FlagType.MechanicalFailure)
        ui.endTransformMatrix(mat3x3(vec3(1,0, tripleOffset),vec3(0,1,0),vec3(0,0,1)))
    end)

    blueFlag = ui.ExtraCanvas(vec2(256,256)) 
    blueFlag:setName("blueFlag")
    blueFlag:update(function (dt)
        ui.beginTransformMatrix()
        ui.drawRaceFlag(ac.FlagType.FasterCar)
        ui.endTransformMatrix(mat3x3(vec3(1,0, tripleOffset),vec3(0,1,0),vec3(0,0,1)))
    end)

    code60Flag = ui.ExtraCanvas(vec2(256,256)) 
    code60Flag:setName("code60Flag")
    code60Flag:update(function (dt)
        ui.beginTransformMatrix()
        ui.drawRaceFlag(ac.FlagType.Code60)
        ui.endTransformMatrix(mat3x3(vec3(1,0, tripleOffset),vec3(0,1,0),vec3(0,0,1)))
    end)

    --flagsWindow = ui.ExtraCanvas(vec2(windowWidth,windowHeight))
    --flagsWindow:setName("FlagWindow")

    NoOver = {true,slipperyFlag}
    Slow = {true, whiteFlag}
    Meatball = {true, meatballFlag}
    Code60 = {false , code60Flag}

    currentFlags = {NoOver,Slow,Meatball,Code60}


end

makeFlags()

ac.onSessionStart(function() slowCar = false end)

--Update Every Frame
function script.update(dt)

    if enabled then
        flagHandler(dt)
        penalties(dt)    
    end

end

function penalties(dt)
    if currentFlags[4][1] == true and slowCarPenalties > -1 then
        code60Timing = code60Timing - dt
    else
        code60Timing = code60Timer
    end
    if code60Timing <= 0 and selfCar.speedKmh > 61 then
        code60Grace = code60Grace - dt
    else
        slowCarPenaltySet = false
        code60Grace = 0.5
    end
    if code60Grace <= 0 and not slowCarPenaltySet then
        slowCarPenaltySet = true
        ac.log("smite Thee")
        if slowCarPenalties == 0 then
            ac.sendChatMessage(selfCar:driverName() .. " violated a code60 zone at: " .. ac.lapTimeToString(SIM.currentSessionTime,true))
        elseif slowCarPenalties > 0 then
            physics.setCarPenalty(ac.PenaltyType.MandatoryPits, slowCarPenalties)
        end
    end
    
    ac.debug("ac", sim.timeToSessionStart)
    if slowCarTimer < 0 and sim.timeToSessionStart < -5000 then
        shouldSlowCar()
        slowCarTimer = 0.5
    else
        slowCarTimer = slowCarTimer - dt
    end

    --ac.debug("a", code60Timing)
end
--Logic Functins
function flagHandler(dt)
    --ac.debug("roc", noOvertakeZones:get(selfCar.splinePosition)-noOvertakeZones:get(selfCar.splinePosition-0.001))
    --ac.debug("pos", car.splinePosition)
    
    if (noOvertakeZones:get(selfCar.splinePosition)-noOvertakeZones:get(selfCar.splinePosition-0.0001)) < 0 or settingsOverride then
        currentFlags[1][1] = true
        
    else
        currentFlags[1][1] = false
    end

    if slowCarPenalties == -1 and slowCar or settingsOverride then
        currentFlags[2][1] = true
    else
        currentFlags[2][1] =  false
    end

    if shouldMeatball() or settingsOverride then
        currentFlags[3][1] = true
    else
        currentFlags[3][1] = false
    end

    if slowCarPenalties > -1 and slowCar or settingsOverride then
        currentFlags[4][1] = true
    else
        currentFlags[4][1] =  false
    end

    if (currentFlags[4][1] or currentFlags[2][1]) and enablePhysicsFlags == 1 then
        physics.overrideRacingFlag(ac.FlagType.Caution)
    else
        physics.overrideRacingFlag(ac.FlagType.None)
    end
end

function shouldSlowCar()
    --[[if (CAR.speedKmh < 30) and not(CAR.isInPitlane) and (CAR.wheelsOutside < 3) and (SIM.timeToSessionStart < -10000) then
        if lastSlowCarBroadcastAttempt + slowCarCooldown < totalElapsedTime then
            lastSlowCarBroadcastAttempt = totalElapsedTime
            --ac.broadcastSharedEvent("broadcastSlowCar", selfCar.splinePosition)
            --slowCarEvent({slowCarProgress=selfCar.splinePosition})
        end

        return true
    elseif  lastSlowCarRecieve + slowCarFlagPersist > totalElapsedTime then
        return true
    else
        return false
    end]]
            slowCar = false

    for cari, carNo in ac.iterateCars.ordered() do
        
      if (ac.getCar.ordered(cari-1) ~= nil and --[[cari ~= 0 and]] not selfCar.isInPitlane) and cari < 20 then
        local nearestSlowCar = math.round((carNo.splinePosition-selfCar.splinePosition)*SIM.trackLengthM,1)
        if carNo.speedKmh < slowCarSpeed and not carNo.isInPitlane and math.round((carNo.splinePosition-selfCar.splinePosition)*SIM.trackLengthM,1) < slowCarDistanceBehind and math.round((carNo.splinePosition-selfCar.splinePosition)*SIM.trackLengthM,1) > -1*slowCarDistanceAhead then
            slowCar = true
        end
      end

    end


end

function shouldMeatball()
    if (CAR.wheels[0].suspensionDamage > meatballThreshold) or
    (CAR.wheels[1].suspensionDamage > meatballThreshold) or
    (CAR.wheels[2].suspensionDamage > meatballThreshold) or
    (CAR.wheels[3].suspensionDamage > meatballThreshold) or
    CAR.wheels[0].isBlown or
    CAR.wheels[1].isBlown or
    CAR.wheels[2].isBlown or
    CAR.wheels[3].isBlown
    then
        return true
    else
        return false
    end
end


--UI FUNCTIONSSS
ac.onResolutionChange(function()
    windowWidth, windowHeight = ac.getSim().windowWidth,ac.getSim().windowHeight
        mirrorScale = windowHeight/1800
        vmirrorTop = (85/uiScale)
        vmirrorLeft = ((windowWidth/2)-(425.45525*mirrorScale)-2)/uiScale
        vmirrorBottom = ((213.78521*mirrorScale+83.3)/uiScale)
        vmirrorRight = ((windowWidth/2)+(425.45525*mirrorScale)+2)/uiScale
        --flagsWindow = ui.ExtraCanvas(vec2(windowWidth,windowHeight))
        
end)

ui.registerOnlineExtra(ui.Icons.Flag, "BetterFlags Settings", function() return true end,
    function() --UiCallback
        settingsOverride = true
        if ui.button("Reset Window Position") then
            betterFlagSettings.flagWindowPos = vec2(0,0)
        end
        --[[tempSettings.flagWindowX = ui.slider("Flag Left/Right",tempSettings.flagWindowX, 0,1)
        tempSettings.flagWindowY = ui.slider("Flag Up/Down",tempSettings.flagWindowY, 0,1)
        if ui.modernButton("Apply Settings",vec2(200,50), ui.ButtonFlags.None, ui.Icons.Save) then
            betterFlagSettings = tempSettings
            return true
        end]]
        
    end,
    function(cancel) --CloseCallback
        settingsOverride = false
end, ui.OnlineExtraFlags.Tool)



function script.drawUI() --Draws a shitty UI for it.

--ui.text(code60Timing .. " " .. code60Grace)

--[[if settingsOverride then
    --ui.setCursor(vec2(tempSettings.flagWindowX*windowWidth, tempSettings.flagWindowY*windowHeight))
    windowPos = vec2(tempSettings.flagWindowX*windowWidth, tempSettings.flagWindowY*windowHeight)
else
    --ui.setCursor(vec2(betterFlagSettings.flagWindowX*windowWidth, betterFlagSettings.flagWindowY*windowHeight))
    windowPos = betterFlagSettings.flagWindowPos
end]]
--betterFlagSettings.flagWindowPos = vec2(10,10)

    ui.transparentWindow("flagsWindow", betterFlagSettings.flagWindowPos - vec2(tripleOffset, 0), vec2(620, 120), true,
        true, function()
        local blanks = 0
        for i = 1, #currentFlags do
            if currentFlags[i][1] then
                ui.drawImage(currentFlags[i][2], vec2((120 * (i - blanks)), 0), vec2(256 + (120 * (i - blanks)), 256))
            else
                blanks = blanks + 1
            end
        end

        if ui.windowHovered(ui.HoveredFlags.RectOnly) then
            ui.drawRectFilled(vec2(0, 0), ui.windowSize(), rgbm(0, 0, 0, 0.1))
            ui.setCursor(vec2(600, 0))
            ui.drawIcon(ui.Icons.Pin, vec2(600, 0), vec2(620, 20))
            if ui.checkbox("Pin", betterFlagSettings.flagWindowPinned) then betterFlagSettings.flagWindowPinned = not
                betterFlagSettings.flagWindowPinned end
            if ui.isMouseDragging(ui.MouseButton.Left) and not flagDragging and not betterFlagSettings.flagWindowPinned then
                flagStartPos = ui.windowPos()
                flagDragging = true
            end
        end
        if flagDragging and ui.mouseDragDelta(ui.MouseButton.Left) ~= vec2(0, 0) then
            settingsOverride = true
            betterFlagSettings.flagWindowPos = flagStartPos + ui.mouseDragDelta() + vec2(tripleOffset, 0)
        else
            settingsOverride = false
            flagDragging = false
        end
    end)
--[[flagsWindow:clear()
flagsWindow:update(function(dt)
        local blanks = 0
    for i = 1, #currentFlags do

        if currentFlags[i][1] then
            ui.drawImage(currentFlags[i][2],vec2((120*(i-blanks))-tripleOffset,0),vec2(256+(120*(i-blanks))-tripleOffset,256))
        else
            blanks = blanks + 1
        end
    end
end)
ui.image(flagsWindow, vec2(windowWidth,windowHeight))

ui.setCursor(vec2(0,0))]]
end
