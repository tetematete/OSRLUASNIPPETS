local car = ac.getCar(0)
local sim = ac.getSim()
local drsZones = ac.INIConfig.trackData('drs_zones.ini')
local crossingTimes = {}

local activateOnLap = 1
local gapAhead = 1
local flipAllowed = false
local DRSEnabled = activateOnLap == 0 and true or false
local areWeFR = const(true)

for index, section in drsZones:iterate("ZONE") do
    local drsData = drsZones:mapSection(section, { DETECTION = 0, START = 0, END = 0 })
    crossingTimes[index] = {}
    for i, c in ac.iterateCars() do
        crossingTimes[index][i] = 0
    end

    ac.onTrackPointCrossed(-1, drsData.DETECTION, function(carIndex, timeMs)
        if DRSEnabled then
            if carIndex ~= 0 then
                crossingTimes[index][carIndex+1] = timeMs
            else
                for i, v in ipairs(crossingTimes[index]) do
                    if timeMs - v < gapAhead*1000 then
                        physics.allowCarDRS(0, not areWeFR)
                        ac.log("Gap ahead under 1 second. Allowing DRS")
                        break
                    else
                        physics.allowCarDRS(0, areWeFR)
                    end
                end

            end
        end
    end)
end
if crossingTimes == {} then
    ac.log("No or Malformed drs_zones.ini detected!")
end

ac.onOnlineWelcome(function (message, config)
    local sec = "REALDRS"
    activateOnLap = config:get(sec, "ACTIVE_ON_LAP", 1)
    gapAhead = config:get(sec, "GAP_AHEAD", 1)
    flipAllowed = config:get(sec, "FLIP_ALLOWED", false)
    if flipAllowed then
        areWeFR = not areWeFR
    end
end)

ac.onTrackPointCrossed(-1, 1, function (carIndex, timeMs)
    if sim.leaderLapCount >= activateOnLap and sim.raceSessionType == ac.SessionType.Race then
        DRSEnabled = true
    end
end)

local started = false
ac.onSessionStart(function (sessionIndex, restarted)
    started = false
end)

function script.update(dt)
    if not started then
        if sim.isSessionStarted then
            if sim.raceSessionType == ac.SessionType.Race then
                ac.log("Disabling DRS")
                physics.allowCarDRS(0, areWeFR)
            end
            started = true
        end
    end
end
