-- #### TeTeMaTeTe's awesome hold brakes reminder online script ####
-- Is your server populated by people who don't know how to hold their brakes after a spin?
-- Worry no more! This online script gives them a gentle reminder to hold their brakes shortly after losing control of their 2 ton death machine.
-- 
-- IMPORTANT CONFIG STUFF
-- Put the following into your AC server welome message:
-- HoldBrakes:[Points Rate of Change]|[Time Between Samples]|[How long to display the warning for]
-- 
-- ## Par Example:
-- HoldBrakes:50|0.500|5
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

SIM = ac.getSim()
CAR = ac.getCar(SIM.focusedCar)

lastReadTime = 0
lastReadPoints = 0
currentReadPoints = 0 --declare rate of change variables for good measure
pointsRateOfChange =0

isWarning = false
timeWarningStarted = 0 --Warning Variables

targetRateOfChange = 50
sampleTime = 0.5
displayWarningFor = 5 --Config Defaults. 

DefaultWarning = false

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

    ac.onOnlineWelcome(function(message, config)  --Reads the script config from the welcome message
        if string.find(message, 'HoldBrakes:[0-9]+|%d.%d+') ~= nil then
            targetRateOfChange, sampleTime, displayWarningFor = string.match(message, "HoldBrakes:([0-9]+)|(%d.%d+)|([0-9]+)")
        else
            if DefaultWarning == false then
                ac.sendChatMessage("HoldBrakes Config Missing Or Misconfigured. Falling Back to Defaults")
                DefaultWarning = true
            end
        end
        ac.debug('message', message)
        ac.debug('BrakeGain', targetRateOfChange)
        ac.debug('sampleTime', sampleTime)

    end)
end 

function script.drawUI() --Draws a shitty UI for it.

    if isWarning then
        xPos, yPos = (ui.windowSize()):unpack()
        ui.setCursor()
        ui.dwriteTextAligned("⚠️HOLD YOUR BRAKES⚠️", 0.05*yPos, ui.Alignment.Center, ui.Alignment.Center, vec2(1*xPos,0.4*yPos), false, rgbm.colors.red)
    end

end