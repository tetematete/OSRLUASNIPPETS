local sim = ac.getSim()
local fcyToggle = ac.ControlButton("FCYTOGGLE")
local FCY = false

local force = false
local stor = ac.storage{
    t = 5
}

ui.registerOnlineExtra(ui.Icons.AppWindow, "FCY", nil, function ()
    stor.t = ui.slider("Deploy/Lift Time", stor.t, 0, 20, '%.0f sec')
    if ui.button("TOGGLE FCY") then
        FCY = not FCY
        castStatus(FCY, stor.t)
    end
    fcyToggle:control(vec2(100,100))
end, function (okClicked)
    
end, ui.OnlineExtraFlags.Tool)

ac.onClientConnected(function (connectedCarIndex, connectedSessionID)
    setTimeout(function ()
        castStatus(FCY, stor.t)
    end, 5)
end)

function castStatus(f,d)
    math.randomseed(sim.currentSessionTime)
    if not comms({fcy=f,time=d}) then
        setInterval(function ()
            if comms({fcy=f,time=d}) then
                return clearInterval
            end
        end, math.random())
    end
end

fcyToggle:onPressed(function ()
    FCY = not FCY
    castStatus(FCY, stor.t)
end)

comms = ac.OnlineEvent({
ac.StructItem.key("FCY"),
fcy=ac.StructItem.boolean(),
time=ac.StructItem.uint8()
}, function(sender, message)
    local timer = message.time
    FCY = message.fcy

    setInterval(function()
        if timer > 0 then
        if FCY then
            ac.setMessage("FCY", "FCY DEPOYED IN " .. timer, nil, 5)
        else
            ac.setMessage("FCY", "FCY LIFTED IN " .. timer, nil, 5)
        end
        timer = timer - 1
    else
            if FCY then
                ac.setMessage("FCY", "FCY DEPOYED", nil, 5)
            else
                ac.setMessage("FCY", "FCY LIFTED", nil, 5)
            end

            force = FCY
            return clearInterval
        end
    end, 1, "FCY")

end, ac.SharedNamespace.ServerScript)


local wasstop = false

function script.update(dt)
    local stop = false
    if (car.speedKmh > 85) and force then  
        if physics.getCarInputControls().brake < 0.1 then
        stop = true
        end
    elseif car.speedKmh > 80 and force then
        if not car.manualPitsSpeedLimiterEnabled then
        physics.forceUserThrottleFor(0.01, 0)    
        end
    end

    if stop and not wasstop then
        physics.setGentleStop(0, true)
    end
    if not stop and wasstop then
        physics.setGentleStop(0, false)
    end
    wasstop = stop
end
