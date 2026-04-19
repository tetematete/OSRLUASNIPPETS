local car = ac.getCar(0)
local sim = ac.getSim()
local blankiesOn = false
local temp
ac.debug("!version", "tyreblankies v1.0")

ac.onOnlineWelcome(function(message, config) --Reads the script config from the extra options config
    temp = config:get("BLANKIES", "TEMP_DEGC", 70)
end)

ac.onCarJumped(0, function(carIndex)
    blankiesOn = true
end)

function script.update(dt)
    if car.isChangingTyres then
        blankiesOn = true
    end
    if blankiesOn then
        if car.speedKmh > 10 then
            blankiesOn = false
        end
        physics.setTyresTemperature(car.index, ac.Wheel.All, temp)
    end
end
