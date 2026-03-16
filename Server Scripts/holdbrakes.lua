-- #### TeTeMaTeTe's awesome hold brakes reminder online script ####
-- Is your server populated by people who don't know how to hold their brakes after a spin?
-- Worry no more! This online script gives them a gentle reminder to hold their brakes shortly after losing control of their 2 ton death machine.
-- 
-- IMPORTANT CONFIG STUFF
-- Put the following into your AC server CSP EXTRA OPTIONS: (without the dashes)
--
-- [SCRIPT_...]
-- SCRIPT = "https://raw.githubusercontent.com/tetematete/OSRLUASNIPPETS/refs/heads/main/Server%20Scripts/holdbrakes.lua"
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
-- if youre still stuck check here: https://github.com/ac-custom-shaders-patch/acc-extension-config/wiki/Misc-%E2%80%93-Server-extra-options#online-scripts

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

DefaultWarning = false

xPos, yPos = ac.getSim().windowWidth,ac.getSim().windowHeight

function script.update(dt)
    
    valid = CAR.isDriftValid
    instantPoints = CAR.driftInstantPoints
    totalElapsedTime = os.preciseClock() 

    ac.debug('Instantaneous Points', instantPoints)
    ac.debug('Elapsed totalElapsedTime', totalElapsedTime)
    ac.debug('Points Rate Of Change', pointsRateOfChange)

    if pointsRateOfChange > tonumber(targetRateOfChange) then
        timeWarningStarted = totalElapsedTime  
    end
    
    if ((timeWarningStarted + tonumber(displayWarningFor)) > totalElapsedTime) and (totalElapsedTime > tonumber(displayWarningFor))  then
        isWarning = true --Checks the time the warning started at against how long to display it for. 
    else 
        isWarning = false
    end

    if (totalElapsedTime - lastReadTime) > tonumber(sampleTime) then --Sampler for the points rate of change
        lastReadTime = totalElapsedTime
        lastReadPoints = currentReadPoints
        currentReadPoints = instantPoints

        pointsRateOfChange = instantPoints - lastReadPoints
    end

    ac.onOnlineWelcome(function(message, config)  --Reads the script config from the extra options config
        parsedConfig = tostring(config)
        configCheck = config:mapSection("HOLDBRAKES", {TARGET_RATE_OF_CHANGE=0,SAMPLE_TIME=0,DISPLAY_WARNING_FOR=0})
        
        if configCheck["TARGET_RATE_OF_CHANGE"] == 0 then
            ac.sendChatMessage("Target ROC Config Missing Or Misconfigured. Falling Back to Defaults")
        end
        if configCheck["SAMPLE_TIME"] == 0 then
            ac.sendChatMessage("Sample Time Config Missing Or Misconfigured. Falling Back to Defaults")            
        end
        if configCheck["DISPLAY_WARNING_FOR"] == 0 then
            ac.sendChatMessage("Warning Time Config Missing Or Misconfigured. Falling Back to Defaults")            
        end       

        targetRateOfChange = config:get("HOLDBRAKES", "TARGET_RATE_OF_CHANGE", 50)
        sampleTime = config:get("HOLDBRAKES", "SAMPLE_TIME", 0.5)
        displayWarningFor = config:get("HOLDBRAKES", "DISPLAY_WARNING_FOR", 5)

        ac.debug('asconfig', parsedConfig)
        ac.debug('BrakeGain', targetRateOfChange)
        ac.debug('sampleTime', sampleTime)
        ac.debug('whatever', configChecks)

    end)
end 

ac.onResolutionChange(function()
    xPos, yPos = ac.getSim().windowWidth,ac.getSim().windowHeight
end)

function script.drawUI() --Draws a shitty UI for it.

    if isWarning then

        ui.setCursor()
        ui.dwriteTextAligned("⚠️HOLD YOUR BRAKES⚠️", 0.05*yPos, ui.Alignment.Center, ui.Alignment.Center, vec2(1*xPos,0.4*yPos), false, rgbm.colors.red)
    end

end

    

