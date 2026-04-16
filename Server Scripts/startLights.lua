sim = ac.getSim()
car = ac.getCar(0)
texFilePath = (ac.getFolder(ac.FolderID.Root) .. "\\content\\texture\\")

penaltyType = 0 -- -2 for gearbox locked until start, -1 for no Penalty, 0 for teleport to pits, above 0 will be laps to serve drive through.

lightCount = 6
adminFlag = ui.OnlineExtraFlags.None
started = true
startTime = 17000
delayTime = 3000
lightsOutMax = 5000
lightsOutMin = 3000
seqStartTime = 12000
seqDuration = 17000

light = ui.ExtraCanvas(vec2(64,64))
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
    --ac.debug("config", parsedConfig)
    configCheck = config:mapSection("STARTLIGHTS", { TARGET_RATE_OF_CHANGE = 0, SAMPLE_TIME = 0, DISPLAY_WARNING_FOR = 0 })
    lightsOutMin, lightsOutMax = config:get("STARTLIGHTS", "RANDOM_DELAY_RANGE", 3,1)*1000,config:get("STARTLIGHTS", "RANDOM_DELAY_RANGE", 5,2)*1000
    penaltyType = config:get("STARTLIGHTS", "PENALTY_TYPE", -1)
    seqDuration,seqStartTime = config:get("STARTLIGHTS", "SEQUENCE_LENGTH", 17)*1000,config:get("STARTLIGHTS", "SEQUENCE_START", 12)*1000

        if config:get("STARTLIGHTS", "ADMIN_ONLY", 1) == 1 then
            adminFlag = ui.OnlineExtraFlags.Admin
        else
            adminFlag = ui.OnlineExtraFlags.None
        end
    

    ui.registerOnlineExtra(ui.Icons.TrafficLight, "Start Lights", function() return true end, function()

end, function(okClicked)
    ac.log("Start Lights Triggered")
    math.randomseed(sim.systemTime)
    triggerStart({ startTime = sim.currentSessionTime + seqDuration, delayTime = math.random(lightsOutMin,lightsOutMax) })
end, adminFlag)
end)

ac.debug("!version", "startLights v0.5")

function script.update(dt)
    --ac.debug("c",car.speedKmh)
    
    if startTime+delayTime - sim.currentSessionTime > -5000 and not started then
        if car.speedKmh > 0.5 then
            started = true
            if startTime+delayTime - sim.currentSessionTime > 0 then
                ac.sendChatMessage(car:driverName() .. " Jumped the start by:" .. math.round(startTime+delayTime - sim.currentSessionTime,0) .. "ms.")
                if penaltyType == 0 then
                    physics.setCarPenalty(ac.PenaltyType.TeleportToPits, math.round((startTime+delayTime - sim.currentSessionTime)/1000,0)+5)
                elseif penaltyType > 0 then
                    physics.setCarPenalty(ac.PenaltyType.MandatoryPits, penaltyType)
                end
            else
                ac.sendChatMessage(car:driverName() .. " Reacted in: " .. math.abs(math.round(startTime+delayTime - sim.currentSessionTime,0)) .. "ms.")
            end
        end
    end
end



triggerStart = ac.OnlineEvent({
    key = ac.StructItem.key("Start Lights"),
    startTime = ac.StructItem.float(),
    delayTime = ac.StructItem.float()
}, function(sender, message)
    startTime = message.startTime
    delayTime = message.delayTime
    started = false
    ac.log("Start Light Trigger Received at " .. ac.lapTimeToString(sim.currentSessionTime, true))
    --ac.log(delayTime)

                if penaltyType == -2 then
                    physics.lockUserGearboxFor((startTime+delayTime - sim.currentSessionTime)/1000, true )
                end
end, ac.SharedNamespace.ServerScript)

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
