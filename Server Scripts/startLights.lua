sim = ac.getSim()
car = ac.getCar(0)
texFilePath = (ac.getFolder(ac.FolderID.Root) .. "\\content\\texture\\")

lastReadPoints = 0
pointsRateOfChange = 0

isWarning = false
warningTimer = 0 --Warning Variables
lastcombo = 0


lightCount = 6
started = false
startTime = 17000
delayTime = 3000
lightsOutMax = 5000
lightsOutMin = 3000
seqStartTime = 12000
seqDuration = 17000

light = ui.ExtraCanvas(vec2(64,64))
light.setName(light, "light")
--ac.debug("a", ui.imageSize(light))
if ui.imageSize(texFilePath .. "off.png") < vec2(32,32) then
    
    
    light:update(function ()
        ui.drawCircleFilled(vec2(32,32),30,rgbm.colors.white,24)
    end)
else
    light:update(function ()
        ui.drawImage(texFilePath .. "off.png", vec2(0,0), vec2(64,64))
    end)
end


windowWidth, windowHeight = ac.getSim().windowWidth, ac.getSim().windowHeight
lightWidth, lightHeight = ui.imageSize(light):unpack()
lightCenter = vec2((lightWidth / 2), (lightHeight / 2))
lightArrayStart = (windowWidth / 2) - (lightWidth * 2) - lightWidth / 2
lightState = {}
for i=1,lightCount,1 do
    lightState[i] = rgbm.colors.gray
end


ac.onOnlineWelcome(function(message, config) --Reads the script config from the extra options config
    parsedConfig = tostring(config)
    configCheck = config:mapSection("HOLDBRAKES", { TARGET_RATE_OF_CHANGE = 0, SAMPLE_TIME = 0, DISPLAY_WARNING_FOR = 0 })

    targetRateOfChange = config:get("HOLDBRAKES", "TARGET_RATE_OF_CHANGE", 100)
    sampleTime = config:get("HOLDBRAKES", "SAMPLE_TIME", 0.5)
    displayWarningFor = config:get("HOLDBRAKES", "DISPLAY_WARNING_FOR", 5)
    forceBrakes = config:get("HOLDBRAKES", "FORCE_VICTIM_BRAKES", 0)

    if forceBrakes == 0 then
        forceBrakes = false
    elseif forceBrakes == 1 then
        forceBrakes = true
    end
end)

ac.debug("!version", "startLights v0.1")

function script.update(dt)
    --ac.debug("c",car.speedKmh)
    
    if startTime+delayTime - sim.currentSessionTime > -5000 and not started then
        if car.speedKmh > 0.5 then
            started = true
            if startTime+delayTime - sim.currentSessionTime > 0 then
                ac.sendChatMessage(car:driverName() .. " Jumped the start by:" .. math.round(startTime+delayTime - sim.currentSessionTime,0) .. "ms.")
            else
                ac.sendChatMessage(car:driverName() .. " Reacted in: " .. math.abs(math.round(startTime+delayTime - sim.currentSessionTime,0)) .. "ms.")
            end
        end
    end
end

ui.registerOnlineExtra(ui.Icons.ArrowRight, "Start Lights", function() return true end, function()

end, function(okClicked)
    ac.log("Start Lights Triggered")
    triggerStart({ startTime = sim.currentSessionTime + seqDuration, delayTime = math.random(lightsOutMin,lightsOutMax) })
end, ui.OnlineExtraFlags.None)

triggerStart = ac.OnlineEvent({
    key = ac.StructItem.key("Start Lights"),
    startTime = ac.StructItem.float(),
    delayTime = ac.StructItem.float()
}, function(sender, message)
    startTime = message.startTime
    delayTime = message.delayTime
    started = false
    ac.log("Start Light Trigger Received at " .. ac.lapTimeToString(sim.currentSessionTime, true))
end)

ac.onResolutionChange(function()
    windowWidth, windowHeight = ac.getSim().windowWidth, ac.getSim().windowHeight
    lightWidth, lightHeight = ui.imageSize(light):unpack()
    lightCenter = vec2((lightWidth / 2), (lightHeight / 2))
    lightArrayStart = (windowWidth / 2) - (lightWidth * 2) - lightWidth / 2
end)

function script.drawUI() --Draws a shitty UI for it.

    --ac.debug("path", texFilePath .. "texture_trafficlight_off.png")
    --ac.debug("size", "x:" .. windowWidth .. " y:" .. windowHeight)
    --ac.debug("a", sim.currentSessionTime)
    --ac.debug("b", startTime-delayTime-seqStartTime)
    --ac.debug("d", delayTime)
    
    if sim.currentSessionTime < startTime + delayTime then
        for i = 1, lightCount, 1 do
            if sim.currentSessionTime > startTime-seqDuration+seqStartTime+((seqDuration-seqStartTime)/6)*i then
                lightState[i] = rgbm.colors.red
            else
                lightState[i] = rgbm.colors.gray
            end
        end

        
        for i = 1, lightCount, 1 do
            ui.drawImage(light, vec2(lightArrayStart + lightWidth * (i-1), 256) - lightCenter,
                vec2(lightArrayStart + lightWidth * (i-1), 256) + lightCenter, lightState[i], ui.ImageFit.Stretch)
        end
    end

end
