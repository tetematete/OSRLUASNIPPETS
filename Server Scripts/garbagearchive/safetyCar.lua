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

scStart = 0


--ui init
settingsOverride = false
windowWidth, windowHeight = ac.getSim().windowWidth,ac.getSim().windowHeight
uiScale = ac.getUI().uiScale


tempSettings = betterFlagSettings

--safetyCar
local carsDIR = ac.getFolder(ac.FolderID.ContentCars)
safetyCar = ac.emptySceneReference()
safetyCar:loadKN5("content/cars/ks_lotus_3_eleven/lotus_3_eleven.kn5")
safetyCar:setOutline(rgbm.colors.lime)

--web.loadRemoteAssets("content/cars/ks_lotus_3_eleven/lotus_3_eleven.kn5", function(err, folder) ac.debug("err",err) ac.debug("folder", folder)end)

trackRootReference = ac.findNodes('carsRoot:yes')
insertedCarSceneReference = trackRootReference:loadKN5("content/cars/ks_mazda_mx5_cup/mazda_mx5_lod_a.kn5")
insertedCarSceneReference:setVirtualCarFlag(true)

secondcar = trackRootReference:loadKN5("content/cars/ks_mazda_mx5_cup/mazda_mx5_lod_a.kn5")
thirdcar = trackRootReference:loadKN5("content/cars/ks_mazda_mx5_cup/mazda_mx5_lod_a.kn5")

--insertedCarSceneReference = trackRootReference:loadKN5("content/cars/ks_lotus_3_eleven/lotus_3_eleven.kn5")

end
--[[ac.onOnlineWelcome(function(message, config) --Reads the script config from the extra options
    parsedConfig = tostring(config)
    configCheck = config:mapSection("BETTERFLAGS", { NO_OVERTAKE_ZONE_1 = {0,0}, NO_OVERTAKE_ZONE_2 = {0,0}, NO_OVERTAKE_ZONE_3 = {0,0}})

    ac.debug("config", configCheck)

    noOvertake1_S,noOvertake1_E = config:get("BETTERFLAGS", "NO_OVERTAKE_ZONE_1", 0), config:get("BETTERFLAGS", "NO_OVERTAKE_ZONE_1", 0,2)
    noOvertake2_S,noOvertake2_E = config:get("BETTERFLAGS", "NO_OVERTAKE_ZONE_2", 0), config:get("BETTERFLAGS", "NO_OVERTAKE_ZONE_2", 0,2)
    noOvertake3_S,noOvertake3_E = config:get("BETTERFLAGS", "NO_OVERTAKE_ZONE_3", 0), config:get("BETTERFLAGS", "NO_OVERTAKE_ZONE_3", 0,2)
    meatballThreshold = config:get("BETTERFLAGS", "MEATBALL_THRESHOLD", 0.10)
    slowCarFlagPersist = (config:get("BETTERFLAGS", "SLOW_CAR_FLAG_PERSIST", 3))*1000
end)]]--



initialization()

trackLength = SIM.trackLengthM
scGridOffset = 20/trackLength
scGridWindow = 10/trackLength
scTrackPoint = 0.1
scSpeed = 80/3.6

tooFarAhead = false
tooFarBehind = false




ac.onSessionStart(function() initialization() end)

--Update Every Frame
function script.update(dt)
    totalElapsedTime = SIM.currentSessionTime
    trackProgress = CAR.splinePosition



    distanceTraveled = scSpeed*((totalElapsedTime - scStart)/1000)
    scTrackPoint = (splineFix(distanceTraveled/trackLength))
    

    if not (trackProgress < (scTrackPoint-((--[[CAR.racePosition()]]1*scGridOffset)))) then
        tooFarAhead = true
    elseif not (trackProgress > (scTrackPoint-(((--[[CAR.racePosition()]]1)*scGridOffset)-scGridWindow))) then
        tooFarBehind = true
    else
        tooFarAhead = false
        tooFarBehind = false
    end

    ac.debug("startTime", distanceTraveled)
    point = vec3()
    point2 = vec3()
    normal = vec3()



    physics.raycastTrack(ac.trackCoordinateToWorld(vec3(0,-0.43,scTrackPoint)), vec3(0,-0.5,0), 10, point)
    physics.raycastTrack(ac.trackCoordinateToWorld(vec3(0,-0.43,scTrackPoint-0.00001)), vec3(0,-0.5,0), 10, point2)

    insertedCarSceneReference:setPosition(point)

    insertedCarSceneReference:setOrientation(point-point2)
    

    secondcar:setPosition(ac.trackCoordinateToWorld(vec3(0,-0.43,(scTrackPoint-((--[[CAR.racePosition()]]1*scGridOffset))))))
    thirdcar:setPosition(ac.trackCoordinateToWorld(vec3(0,-0.43,(scTrackPoint-((--[[CAR.racePosition()]]1*scGridOffset)-scGridWindow)))))
    --insertedCarSceneReference:setPosition(CAR.position)





        ac.debug('Elapsed totalElapsedTime', totalElapsedTime)
        --ac.debug('asconfig', parsedConfig)
--        ac.debug('Progress', ac.flagType.Ambulance)
        --ac.debug('speed', CAR.wheels[1].suspensionDamage)
        --ac.debug('whatever', configChecks)
        --ac.debug('uiScale', uiScale)
        --ac.debug('mirrorscale', mirrorScale)    
        --ac.debug('windowHeight', image1posy) 
        ac.debug("batt", trackProgress)
        ac.debug("scPos", scTrackPoint)
        ac.debug("windowStart", (scTrackPoint-((--[[CAR.racePosition()]]1*scGridOffset))) )
        ac.debug("windowEnd", (scTrackPoint-((--[[CAR.racePosition()]]1*scGridOffset)-scGridWindow)))
        ac.debug("a", ac.trackCoordinateToWorld(vec3(0,-0.43,0.1)))
        ac.debug("b", a)


        ac.debug("plus", tooFarAhead)
        ac.debug("minus", tooFarBehind)


end

--Logic Functins
function splineFix(splinePos) 
    splinePos = splinePos-math.floor(splinePos)
    return splinePos
end


--Communication Between Scripts



--Recieving

--sending
ac.onChatMessage(function()
    --ac.broadcastSharedEvent("broadcastSlowCar", 0.3)
    scStart = totalElapsedTime
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

--[[ui.registerOnlineExtra(ui.Icons.Flag, "BetterFlags Settings", function() return true end,

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
end, ui.OnlineExtraFlags.Tool)]]--



function script.drawUI() --Draws a shitty UI for it.





end



