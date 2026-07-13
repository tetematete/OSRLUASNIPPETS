local car = ac.getCar(0)
local initB = car.ballast
local initR = car.restrictor
local ballast = 0
local restrictor = 0
local enabled = false

local topSpeed = 0
local data = {}

for i = 1, 50, 1 do
    --data[i] = "DFSKJDSKL:FAJKL:DSAJKLFDSJFKDSLJFKL"
end



ui.registerOnlineExtra(ui.Icons.CarFront, "QUICKBOPTEST", nil, function()
    local b, r,b2,r2 = false, false,false, false
    if ui.checkbox("Enable BOP Override", enabled) then

            b2 ,r2 = true,true
        enabled = not enabled
        if not enabled then
            physics.setCarBallast(0, initB)
            physics.setCarRestrictor(0, initR)

        end
    end

    ballast, b = ui.slider("###Ballast", ballast, -200, 400, 'Ballast: %.0fkg') ui.sameLine() ui.text(car.ballast)
    restrictor, r = ui.slider("###restrictor", restrictor, -100, 400, 'Restrictor: %.0f%%') ui.sameLine() ui.text(car.restrictor)

    if enabled then
        if b or b2 then
            physics.setCarBallast(0, ballast)
        end
        if r or r2 then
            physics.setCarRestrictor(0, restrictor)
        end
    end
    if ui.button("toggle Autopilot") then
        physics.setCarAutopilot(not car.isAIControlled)
    end
    ui.childWindow("Data", vec2(ui.availableSpaceX(), 500), function()
        for index, e in ipairs(data) do
            local txt = "Lap Time: " .. ac.lapTimeToString(e.t) .. " R/B: " .. e.res .. "%/"..e.bal .."kg Top Speed: " ..e.ts
            if ui.menuItem(txt) then
                ac.setClipboardText(txt)
            end
        end
    end)
end, nil, ui.OnlineExtraFlags.Tool)

function script.update(dt)
    if enabled then
        if car.speedKmh > topSpeed then
            topSpeed = car.speedKmh
        end

        ac.markLapAsSpoiled(false)
        physics.markLapAsSpoiled(0)
    end
end

function reset()
    topSpeed = 0
end

ac.onLapCompleted(0, function(carIndex, lapTime, valid, cuts, lapCount)
   
    table.insert(data, {t=lapTime, c=cuts, res=car.restrictor, bal=car.ballast, ts=topSpeed})
    reset()
end)
