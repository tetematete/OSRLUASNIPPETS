local car = ac.getCar(0)
local sim = ac.getSim()
local drsZones = ac.INIConfig.trackData('drs_zones.ini')
local crossingTimes = {}

local activateOnLap = 1
local gapAhead = 1
local flipAllowed = false
local DRSEnabled = activateOnLap == 0 and true or false
local areWeFR = const(true)
local drsData = {}
ac.debug("!version", "realDRS v0.2")
for index, section in drsZones:iterate("ZONE") do
    drsData[index] = drsZones:mapSection(section, { DETECTION = 0, START = 0, END = 0, TIMEOUT = -1, ALLOWED = true })
    ac.log(drsData[index])
    ac.log("DRS: " .. section)
    ac.onTrackPointCrossed(-1, drsData[index].DETECTION, function(carIndex, timeMs)
        if carIndex ~= 0 then
            drsData[index].ALLOWED = true
            clearTimeout(drsData[index].TIMEOUT)
            drsData[index].TIMEOUT = setTimeout(function()
                drsData[index].ALLOWED = false
            end, gapAhead)
        else
            if drsData[index].ALLOWED and sim.leaderLapCount >= activateOnLap and sim.raceSessionType == ac.SessionType.Race then
                physics.allowCarDRS(0, areWeFR)
                ac.log("DRS: Gap ahead under threshold, enabling DRS.")
            else
                physics.allowCarDRS(0, not areWeFR)
                ac.log("DRS: Gap ahead above threshold or not yet enabled, disabling DRS.")
            end
        end
    end)
end
--physics.setCarAutopilot(true)

if drsData == {} then
    ac.log("No or Malformed drs_zones.ini detected!")
end

ac.onOnlineWelcome(function(message, config)
    local sec = "REALDRS"
    activateOnLap = config:get(sec, "ACTIVE_ON_LAP", 1)
    gapAhead = config:get(sec, "GAP_AHEAD", 1)
    flipAllowed = config:get(sec, "FLIP_ALLOWED", true)
    if flipAllowed then
        areWeFR = not areWeFR
    end

    ac.debug("Config:",
        "ACTIVE_ON_LAP=" .. activateOnLap .. "\nGAP_AHEAD=" .. gapAhead .. "\nTRUE = " .. (areWeFR and "TRUE" or "FALSE"))
end)


ac.onLapCompleted(-1, function(carIndex, lapTime, valid, cuts, lapCount)
    setTimeout(function()
        if sim.leaderLapCount >= activateOnLap and sim.raceSessionType == ac.SessionType.Race then
            if not DRSEnabled then
                ac.log("DRS: NOW ENABLED")
            end
            DRSEnabled = true
        end
    end, 1)
end)

local started = false
ac.onSessionStart(function(sessionIndex, restarted)
    ac.log("DRS: SESSION RESTARTED\nDRS DISABLED")
    physics.allowCarDRS(0, areWeFR)
    started = false
    DRSEnabled = false
end)



--[=[function script.update(dt)
    ac.debug("drsData", drsData)
    ac.debug("d", car.drsAvailable)
    --[[if not started then
        if sim.isSessionStarted then
            started = true
        end
    end]]
end]=]
