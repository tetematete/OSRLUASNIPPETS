sim = ac.getSim()
car = ac.getCar(0)
local texFilePath = (ac.getFolder(ac.FolderID.Root) .. "\\content\\texture\\")

local penaltyType = 0 -- -2 for gearbox locked until start, -1 for no Penalty, 0 for teleport to pits, above 0 will be laps to serve drive through.

local URL = ""
local lightCount = 6
local adminFlag = ui.OnlineExtraFlags.None
local overrideTimer = 0
local started = true
local startTime = 0
local delayTime = 0
local lightsOutMax = 5000
local lightsOutMin = 3000
local seqStartTime = 12000
local seqDuration = 17000
local replaceACStart = 0
math.randomseed(sim.randomSeed)
local gracePeriod = 1000 * math.random(1, 2)
local debugMode = 0


local light = ui.ExtraCanvas(vec2(64, 64))
--ac.debug("a", ui.imageSize(light))
light:setName("light")
if ui.imageSize(texFilePath .. "off.png") < vec2(32, 32) then
    light:update(function()
        ui.drawCircleFilled(vec2(32, 32), 30, rgbm.colors.white, 24)
    end)
else
    light:update(function()
        ui.drawImage(texFilePath .. "off.png", vec2(0, 0), vec2(64, 64))
    end)
end


local windowWidth, windowHeight = ac.getSim().windowWidth, ac.getSim().windowHeight
local lightWidth, lightHeight = ui.imageSize(light):unpack()
local lightCenter = vec2((lightWidth / 2), (lightHeight / 2))
local lightArrayStart = (windowWidth / 2) - (lightWidth * 2) - lightWidth / 2
local lightState = {}
for i = 1, lightCount, 1 do
    lightState[i] = rgbm.colors.gray
end


local function overrideStart()
    if replaceACStart == 1 and sim.raceSessionType == ac.SessionType.Race then
        started = false
        startTime = sim.currentSessionTime + sim.timeToSessionStart
        math.randomseed(sim.randomSeed + sim.currentSessionIndex * 100)
        delayTime = math.random(lightsOutMin, lightsOutMax)
        ac.disableExtraHUDElements('startingLights', true)
        --ac.debug("d", startTime)
        --ac.log(sim.currentSessionTime,sim.timeToSessionStart)
        --ac.debug("a", sim.currentSessionTime+sim.timeToSessionStart)
    else
        started = true
        startTime = 0
        delayTime = 0
    end
end

ac.onOnlineWelcome(function(message, config) --Reads the script config from the extra options config
    local parsedConfig = tostring(config)
    --ac.debug("config", parsedConfig)
    local configCheck = config:mapSection("STARTLIGHTS",
        { TARGET_RATE_OF_CHANGE = 0, SAMPLE_TIME = 0, DISPLAY_WARNING_FOR = 0 })
    lightsOutMin, lightsOutMax = config:get("STARTLIGHTS", "RANDOM_DELAY_RANGE", 3, 1) * 1000,
        config:get("STARTLIGHTS", "RANDOM_DELAY_RANGE", 5, 2) * 1000
    penaltyType = config:get("STARTLIGHTS", "PENALTY_TYPE", -1)
    seqDuration, seqStartTime = config:get("STARTLIGHTS", "SEQUENCE_LENGTH", 17) * 1000,
        config:get("STARTLIGHTS", "SEQUENCE_START", 12) * 1000

    if config:get("STARTLIGHTS", "ADMIN_ONLY", 1) == 1 then
        adminFlag = ui.OnlineExtraFlags.Admin
    else
        adminFlag = ui.OnlineExtraFlags.None
    end
    replaceACStart = config:get("STARTLIGHTS", "REPLACE_AC_START", 0)
    URL = config:get("STARTLIGHTS", "ICON_URL", "")
    debugMode = config:get("STARTLIGHTS", "DEBUG_MODE", 0)

    overrideTimer = 1

   ui.registerOnlineExtra(ui.Icons.TrafficLight, "Start Lights", function() return true end, function()

    end, function(okClicked)
        math.randomseed(sim.systemTime)
        ac.log("Start Lights Message Sent")
        ac.setMessage("Start Lights Command Sent","")
        if debugMode == 1 then
            ac.debug("Settings Dump", tostring(config))
        end
        
        triggerStart({ startTime = sim.currentSessionTime + seqDuration, delayTime = math.random(lightsOutMin,
            lightsOutMax) })
    end, adminFlag)
end)



ac.onSessionStart(function()
    overrideTimer = 1
end)

ac.debug("!version", "startLights v0.7")

function script.update(dt)
    if overrideTimer > 0 then
        overrideTimer = overrideTimer - dt
    elseif overrideTimer < 0 and overrideTimer > -1 then
        overrideStart()
        overrideTimer = -2
    end

    if URL ~= "" and ui.isImageReady(URL) then
        light:clear()
        light:update(function()
            ui.drawImage(URL, vec2(0, 0), vec2(64, 64))
        end)
        URL = ""
    end
    --ac.debug("t", overrideTimer )
    --ac.debug("c",car.speedKmh)
    --ac.debug("d", startTime+delayTime - gracePeriod)
    --ac.debug("b", (sim.currentSessionTime) )

    if startTime + delayTime - sim.currentSessionTime < startTime + delayTime - gracePeriod and startTime + delayTime - sim.currentSessionTime > -5000 and not started then
        if car.speedKmh > 0.5 then
            started = true
            if startTime + delayTime - sim.currentSessionTime > 0 then
                ac.sendChatMessage(car:driverName() ..
                " Jumped the start by:" .. math.round(startTime + delayTime - sim.currentSessionTime, 0) .. "ms.")
                if penaltyType == 0 then
                    physics.setCarPenalty(ac.PenaltyType.TeleportToPits,
                        math.round((startTime + delayTime - sim.currentSessionTime) / 1000, 0) + 5)
                elseif penaltyType > 0 then
                    physics.setCarPenalty(ac.PenaltyType.MandatoryPits, penaltyType)
                end
            else
                ac.sendChatMessage(car:driverName() ..
                " Reacted in: " .. math.abs(math.round(startTime + delayTime - sim.currentSessionTime, 0)) .. "ms.")
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
    ac.log("TIME: Start Light Trigger Received at " .. ac.lapTimeToString(sim.currentSessionTime, true) .. " | " .. ac.lapTimeToString(sim.sessionTimeLeft, true) .. " Remaining." .. 
    "\n COMMS: Sent By: " .. sender:driverName() .. " Penalty Type:" .. penaltyType ..
    "\n SYNC: Lights will all be lit in:" .. ac.lapTimeToString(startTime - sim.currentSessionTime) .. " Expected roughly: " .. ac.lapTimeToString(seqDuration).. " Delay between: " .. lightsOutMin/1000 .. "s and " .. lightsOutMax/1000 .. "s" )

    if debugMode == 1 then
        
        ac.sendChatMessage("Start Light Command Successfully Recieved. Lights Out in: " .. ac.lapTimeToString(startTime+delayTime - sim.currentSessionTime,true))
    end
    if penaltyType == -2 then
        physics.lockUserGearboxFor((startTime + delayTime - sim.currentSessionTime) / 1000, true)
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


    if sim.currentSessionTime < startTime + delayTime then
        for i = 1, lightCount, 1 do
            if sim.currentSessionTime > startTime - seqDuration + seqStartTime + ((seqDuration - seqStartTime) / 6) * i then
                lightState[i] = rgbm.colors.red
            else
                lightState[i] = rgbm.colors.gray
            end
        end


        for i = 1, lightCount, 1 do
            ui.drawImage(light, vec2(lightArrayStart + lightWidth * (i - 1), 256) - lightCenter,
                vec2(lightArrayStart + lightWidth * (i - 1), 256) + lightCenter, lightState[i], ui.ImageFit.Stretch)
        end
    end
end
