-- #### TeTeMaTeTe's awesome hold brakes reminder online script ####
-- Is your server populated by people who don't know how to hold their brakes after a spin?
-- Worry no more! This online script gives them a gentle reminder to hold their brakes shortly after losing control of their 2 ton death machine.
-- 
-- IMPORTANT CONFIG STUFF
-- Put the following into your AC server CSP EXTRA OPTIONS: (without the dashes)
--
-- [HOLDBRAKES]
-- TARGET_RATE_OF_CHANGE=50
-- SAMPLE_TIME=0.5
-- DISPLAY_WARNING_FOR=5
-- 
-- This will:
-- Set the Target points rate of change to 50. This is an arbitrary number, and is also affected by the sample rate. Change this in proportion with the sample rate.
-- so target 50 and sample 0.5 would activate at roughly the same time as target 25 and sample 0.25
-- 
-- Set the Sample Rate to 0.5 seconds between samples. 
-- 
-- Set the warning display time to 5 seconds.
-- 
-- To add to your server, place the following into the CSP Extra Options. (This was tested on CSP 2.11, no guarantees this functions on any other versions)
-- [SCRIPT_...]
-- SCRIPT = "(Github Raw Link Here.)"
-- 
-- if youre still stuck check here: https://github.com/ac-custom-shaders-patch/acc-extension-config/wiki/Misc-%E2%80%93-Server-extra-options#online-scripts


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

--ui init
settingsOverride = false
windowWidth, windowHeight = ac.getSim().windowWidth,ac.getSim().windowHeight
uiScale = ac.getUI().uiScale
testGameState = false

betterFlagSettings = ac.storage({
    flagWindowX=0,flagWindowY=0,flagWindowScale=1
})

tempSettings = betterFlagSettings

end
ac.onOnlineWelcome(function(message, config) --Reads the script config from the extra options
    parsedConfig = tostring(config)
    configCheck = config:mapSection("BETTERFLAGS", { NO_OVERTAKE_ZONE_1 = {0,0}, NO_OVERTAKE_ZONE_2 = {0,0}, NO_OVERTAKE_ZONE_3 = {0,0}})

    ac.debug("config", configCheck)

    noOvertake1_S,noOvertake1_E = config:get("BETTERFLAGS", "NO_OVERTAKE_ZONE_1", 0), config:get("BETTERFLAGS", "NO_OVERTAKE_ZONE_1", 0,2)
    noOvertake2_S,noOvertake2_E = config:get("BETTERFLAGS", "NO_OVERTAKE_ZONE_2", 0), config:get("BETTERFLAGS", "NO_OVERTAKE_ZONE_2", 0,2)
    noOvertake3_S,noOvertake3_E = config:get("BETTERFLAGS", "NO_OVERTAKE_ZONE_3", 0), config:get("BETTERFLAGS", "NO_OVERTAKE_ZONE_3", 0,2)
    meatballThreshold = config:get("BETTERFLAGS", "MEATBALL_THRESHOLD", 0.10)
    slowCarFlagPersist = (config:get("BETTERFLAGS", "SLOW_CAR_FLAG_PERSIST", 1))*1000
end)

slowCarEvent = ac.OnlineEvent({
  -- message structure layout:
  key = ac.StructItem.key('slowCarEvent'),
  slowCarProgress = ac.StructItem.float(),
}, function (sender, data)

  ac.debug('Got message: from'  , sender and sender.index or -1)
  ac.debug('Got message: text', data.slowCarProgress)
      if ((data.slowCarProgress+0.01) > trackProgress-math.floor((trackProgress + slowCarDistance)) and (data.slowCarProgress < ((trackProgress + slowCarDistance)-math.floor((trackProgress + slowCarDistance))))) then
        lastSlowCarRecieve = totalElapsedTime
    end 
end,ac.SharedNamespace.ServerScript)


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

    flagsWindow = ui.ExtraCanvas(vec2(windowWidth,windowHeight))
    flagsWindow:setName("FlagWindow")

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

    totalElapsedTime = SIM.currentSessionTime
    trackProgress = CAR.splinePosition




        ac.debug('Elapsed totalElapsedTime', totalElapsedTime)
        --ac.debug('asconfig', parsedConfig)
--        ac.debug('Progress', ac.flagType.Ambulance)
        --ac.debug('speed', CAR.wheels[1].suspensionDamage)
        --ac.debug('whatever', configChecks)
        --ac.debug('uiScale', uiScale)
        --ac.debug('mirrorscale', mirrorScale)    
        --ac.debug('windowHeight', image1posy) 
        ac.debug("batt", currentFlags)
        ac.debug("dm", SIM.directMessagingAvailable)
        ac.debug("udp", SIM.directUDPMessagingAvailable)

    flagHandler()
end

--Logic Functins
function flagHandler()

    if ((trackProgress > noOvertake1_S) and (trackProgress < noOvertake1_E)) or ((trackProgress > noOvertake2_S) and (trackProgress < noOvertake2_E) or ((trackProgress > noOvertake3_S) and (trackProgress < noOvertake3_E))) or settingsOverride then
        currentFlags[1][1] = true
    else
        currentFlags[1][1] = false
    end

    if shouldSlowCar() or settingsOverride then

    currentFlags[2][1] = true

    else
        currentFlags[2][1] =  false
    end

    if shouldMeatball() or settingsOverride then
        currentFlags[3][1] = true
    else
        currentFlags[3][1] = false
    end


end

function shouldSlowCar()
    if (CAR.speedKmh < 30) and not(CAR.isInPitlane) and (CAR.wheelsOutside < 3) and (SIM.timeToSessionStart < -10000) then
        if lastSlowCarBroadcastAttempt + slowCarCooldown < totalElapsedTime then
            lastSlowCarBroadcastAttempt = totalElapsedTime
            --ac.broadcastSharedEvent("broadcastSlowCar", trackProgress)
            slowCarEvent({slowCarProgress=trackProgress})
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
    CAR.wheels[0].isBlown or
    CAR.wheels[1].isBlown or
    CAR.wheels[2].isBlown or
    CAR.wheels[3].isBlown
    --CAR.wheels[4].isBlown

    then
        return true
    else
        return false
    end
end


--Communication Between Scripts



--Recieving

--0.9 0.1 



--[[ac.onSharedEvent("broadcastSlowCar", function(slowCarProgress)
    if ((slowCarProgress+0.01) > trackProgress-math.floor((trackProgress + slowCarDistance)) and (slowCarProgress < ((trackProgress + slowCarDistance)-math.floor((trackProgress + slowCarDistance))))) then
        lastSlowCarRecieve = totalElapsedTime
    end 
end)]]

--sending
ac.onChatMessage(function()
    --ac.broadcastSharedEvent("broadcastSlowCar", 0.3)
    ac.store("testGameState", false)
end)

--UI FUNCTIONSSS
ac.onResolutionChange(function()
    windowWidth, windowHeight = ac.getSim().windowWidth,ac.getSim().windowHeight

        mirrorScale = windowHeight/1800
        

        vmirrorTop = (85/uiScale)
        vmirrorLeft = ((windowWidth/2)-(425.45525*mirrorScale)-2)/uiScale
        vmirrorBottom = ((213.78521*mirrorScale+83.3)/uiScale)
        vmirrorRight = ((windowWidth/2)+(425.45525*mirrorScale)+2)/uiScale
    flagsWindow = ui.ExtraCanvas(vec2(windowWidth,windowHeight))
        
end)

ui.registerOnlineExtra(ui.Icons.Flag, "BetterFlags Settings", function() return true end,

    function() --UiCallback
        settingsOverride = true

        tempSettings.flagWindowX = ui.slider("Flag Left/Right",tempSettings.flagWindowX, 0,1)
        tempSettings.flagWindowY = ui.slider("Flag Up/Down",tempSettings.flagWindowY, 0,1)



        if ui.modernButton("Apply Settings",vec2(200,50), ui.ButtonFlags.None, ui.Icons.Save) then
            betterFlagSettings = tempSettings
            return true
        end
        
    end,
    function(cancel) --CloseCallback
        settingsOverride = false
end, ui.OnlineExtraFlags.Tool)



function script.drawUI() --Draws a shitty UI for it.

if settingsOverride then
    ui.setCursor(vec2(tempSettings.flagWindowX*windowWidth, tempSettings.flagWindowY*windowHeight))
else
    ui.setCursor(vec2(betterFlagSettings.flagWindowX*windowWidth, betterFlagSettings.flagWindowY*windowHeight))
end

flagsWindow:clear()
flagsWindow:update(function(dt)
        local blanks = 0
    for i = 1, #currentFlags do

        if currentFlags[i][1] then
            ui.drawImage(currentFlags[i][2],vec2((120*(i-blanks)),0),vec2(256+(120*(i-blanks)),256))
        else
            blanks = blanks + 1
        end
    end
end)
ui.image(flagsWindow, vec2(windowWidth,windowHeight))

ui.setCursor(vec2(0,0))




end



