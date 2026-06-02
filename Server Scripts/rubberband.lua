ac.debug("!version", "rubberband v0.5")
local ballastlut    --= ac.DataLUT11.parse("|0=500|3=100|10=-200|")
local restrictorlut --= ac.DataLUT11.parse("|0=50|10=0")
local lcar = 0
local selfCar = ac.getCar(0)
local updDelay = 0
local updTimer = 0
local lapToActivate = 0
local active = false
local practice, quali, race

function setActive()
local session = ac.getSession(ac.getSim().currentSessionIndex).type

if session == ac.SessionType.Practice and practice == 1 or 
    session == ac.SessionType.Qualify and quali == 1 or 
    session == ac.SessionType.Race and race == 1 then 
        active = true 
    else
        active = false
    end
end

ac.onOnlineWelcome(function(message, config)
  ballastlut = config:tryGetLut("RUBBERBAND", "BALLAST")
  restrictorlut = config:tryGetLut("RUBBERBAND", "RESTRICTOR")
  lapToActivate = config:get("RUBBERBAND", "ACTIVE_ON_LAP", 0)
  updDelay = config:get("RUBBERBAND", "SEC_PER_UPDATE", 0 )
  practice, quali, race = config:get("RUBBERBAND", "ACTIVE_PQR", 0, 1), config:get("RUBBERBAND", "ACTIVE_PQR", 0, 2), config:get("RUBBERBAND", "ACTIVE_PQR", 1, 3)

  setActive()
end)

ac.onSessionStart(function (sessionIndex, restarted)
    setActive()
end)

function script.update(dt)
    if active then

        if updTimer > 0 then
            updTimer = updTimer - dt
        else
            lcar = ac.getCar.leaderboard(0)
            local gap = ac.getGapBetweenCars(0, lcar.index)
            if selfCar.speedKmh > 50 and lcar.lapCount >= lapToActivate then
                physics.setCarRestrictor(0, restrictorlut:get(gap))
                physics.setCarBallast(0, ballastlut:get(gap))
            end
            updTimer = updDelay
        end
    end
end
