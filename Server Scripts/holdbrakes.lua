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
-- TARGET_RATE_OF_CHANGE=50 ;Sensitivity of the script, lower numbers display warning earlier. rate of change graph avaliable in lua debug app to help with picking the right value
-- DISPLAY_WARNING_FOR=5 ;Time in seconds to display warning for
-- 
-- if you're still stuck check here: https://github.com/ac-custom-shaders-patch/acc-extension-config/wiki/Misc-%E2%80%93-Server-extra-options#online-scripts

SIM = ac.getSim()
CAR = ac.getCar(SIM.focusedCar)

lastReadPoints = 0
pointsRateOfChange = 0

isWarning = false
warningTimer = 0 --Warning Variables

targetRateOfChange = 50
sampleTime = 0.5
displayWarningFor = 5 --Config Defaults. 

xPos, yPos = ac.getSim().windowWidth,ac.getSim().windowHeight

ac.onOnlineWelcome(function(message, config)     --Reads the script config from the extra options config
    parsedConfig = tostring(config)
    configCheck = config:mapSection("HOLDBRAKES", { TARGET_RATE_OF_CHANGE = 0, SAMPLE_TIME = 0, DISPLAY_WARNING_FOR = 0 })

    if configCheck["TARGET_RATE_OF_CHANGE"] == 0 then
        ac.sendChatMessage("Target ROC Config Missing Or Misconfigured. Falling Back to Defaults")
    end
    --if configCheck["SAMPLE_TIME"] == 0 then
    --    ac.sendChatMessage("Sample Time Config Missing Or Misconfigured. Falling Back to Defaults")
    --end
    if configCheck["DISPLAY_WARNING_FOR"] == 0 then
        ac.sendChatMessage("Warning Time Config Missing Or Misconfigured. Falling Back to Defaults")
    end

    targetRateOfChange = config:get("HOLDBRAKES", "TARGET_RATE_OF_CHANGE", 50)
    sampleTime = config:get("HOLDBRAKES", "SAMPLE_TIME", 0.5)
    displayWarningFor = config:get("HOLDBRAKES", "DISPLAY_WARNING_FOR", 5)
end)

function script.update(dt)
    instantPoints = CAR.driftInstantPoints

    ac.debug("!version", "0.8")

    --ac.debug('Instantaneous Points', instantPoints)
    ac.debug('Points Rate Of Change', pointsRateOfChange, 0,200,3)

    if pointsRateOfChange > tonumber(targetRateOfChange) then
        warningTimer = displayWarningFor
    end

    if warningTimer > 0 then --Checks the time the warning started at against how long to display it for.
        warningTimer = warningTimer - dt
        isWarning = true 
    else
        isWarning = false
    end

        pointsRateOfChange = (instantPoints - lastReadPoints)/dt
        lastReadPoints = instantPoints

    --ac.debug('asconfig', parsedConfig)
    --ac.debug('BrakeGain', targetRateOfChange)
    --ac.debug('sampleTime', sampleTime)
    --ac.debug('whatever', configChecks)
end

ac.onResolutionChange(function()
    xPos, yPos = ac.getSim().windowWidth, ac.getSim().windowHeight
end)

function script.drawUI() --Draws a shitty UI for it.
    if isWarning then
        ui.dwriteTextAligned("⚠️HOLD YOUR BRAKES⚠️", 0.05 * yPos, ui.Alignment.Center, ui.Alignment.Center,
            vec2(1 * xPos, 0.4 * yPos), false, rgbm.colors.red)
    end
end