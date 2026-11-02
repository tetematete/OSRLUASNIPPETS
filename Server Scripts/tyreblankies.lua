local car = ac.getCar(0)
local sim = ac.getSim()
local blankiesOn = false
local temps = {0}
local carData = {}
ac.debug("!version", "tyreblankies v1.1")

for i, c in ac.iterateCars() do
    ac.log(c:id())
end
local debugMode = true

--c.onOnlineWelcome(function(message, config) --Reads the script config from the extra options config--
    --temps = {config:get("BLANKIES", "TEMP_DEGC", 70, 1), config:get("BLANKIES", "TEMP_DEGC", ac.INIConfig.OptionalNumber(), 2)}
--end)

ac.onOnlineWelcome(function(message, config)
    local sec = "BLANKIES"
    if debugMode then
        config = ac.INIConfig.parse([[
        [BLANKIES_...]
        CAR_FOLDER=ks_mazda_mx5_cup
        TEMP_DEGC=70,70

        [BLANKIES_...]
        CAR_FOLDER=BEBEBE
        TEMP_DEGC=40
        ]], ac.INIFormat.Extended)
    end


    temps = config:get(sec, "TEMP_DEGC", {nil,nil,nil,nil})
    if #temps > 0 then
        
    else
        for i, s in config:iterate("BLANKIES") do
            if config:get(s, "CAR_FOLDER", car:id()) == car:id() then
                temps = config:get(s, "TEMP_DEGC", {nil,nil,nil,nil})
                break
            end
        end
    end
    ac.log(temps)

end)

ac.onCarJumped(0, function(carIndex)
    blankiesOn = true
end)
local wasMenu = false
function script.update(dt)
    if car.isChangingTyres then
        blankiesOn = true
    end
    if blankiesOn then
        if car.speedKmh > 10 then
            blankiesOn = false
        end
        if #temps == 1 then
            physics.setTyresTemperature(car.index, ac.Wheel.All, temps[1])
        elseif #temps == 2 then
            physics.setTyresTemperature(car.index, ac.Wheel.Front, temps[1])
            physics.setTyresTemperature(car.index, ac.Wheel.Rear, temps[2])
        elseif #temps == 4 then
            physics.setTyresTemperature(car.index, ac.Wheel.FrontLeft, temps[1])
            physics.setTyresTemperature(car.index, ac.Wheel.FrontRight, temps[2])
            physics.setTyresTemperature(car.index, ac.Wheel.RearLeft, temps[3])
            physics.setTyresTemperature(car.index, ac.Wheel.RearRight, temps[4])
        end
        
    end
    if not sim.isInMainMenu and wasMenu then
        blankiesOn = true
    end
    wasMenu = sim.isInMainMenu
end
