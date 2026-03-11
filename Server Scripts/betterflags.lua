
--Stuff to intitialize once

function initialization()
SIM = ac.getSim()
CAR = ac.getCar(SIM.focusedCar)

lastReadTime = 0
lastReadPoints = 0
currentReadPoints = 0 --declare rate of change variables for good measure
pointsRateOfChange = 0

isWarning = false
timeWarningStarted = 0 --Warning Variables

targetRateOfChange = 50
sampleTime = 0.5
displayWarningFor = 5 --Config Defaults. 

slowCarCooldown = 1000
lastSlowCarBroadcastAttempt = 0
lastSlowCarRecieve = 0
slowCarDistance = 0.2
slowCarFlagPersist = 5000

--ui init
windowWidth, windowHeight = ac.getSim().windowWidth,ac.getSim().windowHeight
uiScale = ac.getUI().uiScale
end
ac.onOnlineWelcome(function(message, config) --Reads the script config from the extra options
    parsedConfig = tostring(config)
    configCheck = config:mapSection("BETTERFLAGS", { NO_OVERTAKE_ZONE_1 = {0,0}, NO_OVERTAKE_ZONE_2 = {0,0}, NO_OVERTAKE_ZONE_3 = {0,0}})

    ac.debug("config", configCheck)

    noOvertake1_S,noOvertake1_E = config:get("BETTERFLAGS", "NO_OVERTAKE_ZONE_1", 0), config:get("BETTERFLAGS", "NO_OVERTAKE_ZONE_1", 0,2)
    noOvertake2_S,noOvertake2_E = config:get("BETTERFLAGS", "NO_OVERTAKE_ZONE_2", 0), config:get("BETTERFLAGS", "NO_OVERTAKE_ZONE_2", 0,2)
    noOvertake3_S,noOvertake3_E = config:get("BETTERFLAGS", "NO_OVERTAKE_ZONE_3", 0), config:get("BETTERFLAGS", "NO_OVERTAKE_ZONE_3", 0,2)
    meatballThreshold = config:get("BETTERFLAGS", "MEATBALL_THRESHOLD", 0.10)
end)


function makeFlags()

    startFlag = ui.ExtraCanvas(vec2(256,256)) 
    startFlag:setName("startFlag")
    startFlag:update(function (dt)
        ui.drawRaceFlag(ac.FlagType.Start)
    end)

    cautionFlag = ui.ExtraCanvas(vec2(256,256)) 
    cautionFlag:setName("cautionFlag")
    cautionFlag:update(function (dt)
        ui.drawRaceFlag(ac.FlagType.Caution)
    end)

    slipperyFlag = ui.ExtraCanvas(vec2(256,256)) 
    slipperyFlag:setName("slipperyFlag")
    slipperyFlag:update(function (dt)
        ui.drawRaceFlag(ac.FlagType.Slippery)
    end)

    blackFlag = ui.ExtraCanvas(vec2(256,256)) 
    blackFlag:setName("blackFlag")
    blackFlag:update(function (dt)
        ui.drawRaceFlag(ac.FlagType.Stop)
    end)

    whiteFlag = ui.ExtraCanvas(vec2(256,256)) 
    whiteFlag:setName("whiteFlag")
    whiteFlag:update(function (dt)
        ui.drawRaceFlag(ac.FlagType.SlowVehicle)
    end)

    ambulanceFlag = ui.ExtraCanvas(vec2(256,256)) 
    ambulanceFlag:setName("ambulanceFlag")
    ambulanceFlag:update(function (dt)
        ui.drawRaceFlag(ac.FlagType.Ambulance)
    end)

    blackWhiteFlag = ui.ExtraCanvas(vec2(256,256)) 
    blackWhiteFlag:setName("blackWhiteFlag")
    blackWhiteFlag:update(function (dt)
        ui.drawRaceFlag(ac.FlagType.ReturnToPits)
    end)

    meatballFlag = ui.ExtraCanvas(vec2(256,256)) 
    meatballFlag:setName("meatballFlag")
    meatballFlag:update(function (dt)
        ui.drawRaceFlag(ac.FlagType.MechanicalFailure)
    end)

    blueFlag = ui.ExtraCanvas(vec2(256,256)) 
    blueFlag:setName("blueFlag")
    blueFlag:update(function (dt)
        ui.drawRaceFlag(ac.FlagType.FasterCar)
    end)

    code60Flag = ui.ExtraCanvas(vec2(256,256)) 
    code60Flag:setName("code60Flag")
    code60Flag:update(function (dt)
        ui.drawRaceFlag(ac.FlagType.Code60)
    end)

    NoOver = {true,slipperyFlag}
    Slow = {true, whiteFlag}
    Meatball = {true, meatballFlag}
    Code60 = {false , code60Flag}

    currentFlags = {NoOver,Slow,Meatball,Code60}


end

initialization()
makeFlags()

ac.onSessionStart(function() initialization() end)

--Update Every Frame
function script.update(dt)
    
    valid = CAR.isDriftValid
    instantPoints = CAR.driftInstantPoints
    totalElapsedTime = SIM.currentSessionTime
    trackProgress = ac.worldCoordinateToTrackProgress(CAR.position)

    ac.debug('Elapsed totalElapsedTime', totalElapsedTime)


    physics.setCarAutopilot(false)  
        ac.debug('asconfig', parsedConfig)
--        ac.debug('Progress', ac.flagType.Ambulance)
        --ac.debug('speed', CAR.wheels[1].suspensionDamage)
        ac.debug('whatever', configChecks)
        --ac.debug('uiScale', uiScale)
        --ac.debug('mirrorscale', mirrorScale)    
        --ac.debug('windowHeight', image1posy) 
        ac.debug("batt", {lastSlowCarRecieve + slowCarFlagPersist, lastSlowCarBroadcastAttempt})

    flagHandler()
end

--Logic Functins
function flagHandler()

    if ((trackProgress > noOvertake1_S) and (trackProgress < noOvertake1_E)) or ((trackProgress > noOvertake2_S) and (trackProgress < noOvertake2_E) or ((trackProgress > noOvertake3_S) and (trackProgress < noOvertake3_E))) then
        currentFlags[1][1] = true
    else
        currentFlags[1][1] = false
    end

    if shouldSlowCar() then

    currentFlags[2][1] = true

    else
        currentFlags[2][1] = false
    end

    if shouldMeatball() then
        currentFlags[3][1] = true
    else
        currentFlags[3][1] = false
    end


end

function shouldSlowCar()
    if (CAR.speedKmh < 30) and not(CAR.isInPitlane) and (CAR.wheelsOutside < 3) and (SIM.timeToSessionStart < -10000) then
        if lastSlowCarBroadcastAttempt + slowCarCooldown < totalElapsedTime then
            lastSlowCarBroadcastAttempt = totalElapsedTime
            ac.broadcastSharedEvent("broadcastSlowCar", trackProgress)
        end

        return true
    elseif  lastSlowCarRecieve + slowCarFlagPersist > totalElapsedTime then
        return true
    else
        return false
    end

end

function shouldMeatball()
    if (CAR.wheels[0].suspensionDamage > meatballThreshold) or
    (CAR.wheels[1].suspensionDamage > meatballThreshold) or
    (CAR.wheels[2].suspensionDamage > meatballThreshold) or
    (CAR.wheels[3].suspensionDamage > meatballThreshold) or
    (CAR.wheels[4].suspensionDamage > meatballThreshold)   
    then
        return true
    else
        return false
    end
end


--Communication Between Scripts



--Recieving

--0.9 0.1 
ac.onSharedEvent("broadcastSlowCar", function(slowCarProgress)
    if ((slowCarProgress+0.01) > trackProgress-math.floor((trackProgress + slowCarDistance)) and (slowCarProgress < ((trackProgress + slowCarDistance)-math.floor((trackProgress + slowCarDistance))))) then
        lastSlowCarRecieve = totalElapsedTime
    end 
end)

--sending
ac.onChatMessage(function()
    --ac.broadcastSharedEvent("broadcastSlowCar", 0.3)

end)

--UI FUNCTIONSSS
ac.onResolutionChange(function()
    windowWidth, windowHeight = ac.getSim().windowWidth,ac.getSim().windowHeight
end)

function script.drawUI() --Draws a shitty UI for it.

        mirrorScale = windowHeight/1800
        

        vmirrorTop = (85/uiScale)
        vmirrorLeft = ((windowWidth/2)-(425.45525*mirrorScale)-2)/uiScale
        vmirrorBottom = ((213.78521*mirrorScale+83.3)/uiScale)
        vmirrorRight = ((windowWidth/2)+(425.45525*mirrorScale)+2)/uiScale
        --ui.drawRect(vec2(vmirrorLeft, vmirrorTop), vec2(vmirrorRight,vmirrorBottom), rgbm.colors.white)

        local blanks = 0
    for i = 1, #currentFlags do

        if currentFlags[i][1] then
            ui.drawImage(currentFlags[i][2],vec2((120*(i-blanks)),0),vec2(256+(120*(i-blanks)),256))
        else
            blanks = blanks + 1
        end
    end
end



