local sim = ac.getSim()
local fcyToggle = ac.ControlButton("FCYTOGGLE")
local FCY = false
local force = false
ac.storageSetPath('woeFCYuponye')
local stor = ac.storage{
    t = 5
}
local autoslow = false
local dtLaps = 3
local adminOnly = true
local altLimiter = true
ac.debug("!version", "woeFCYuponye v1.5")

ac.onSessionStart(function (sessionIndex, restarted)
    FCY = false
    force = false
end)

ac.onOnlineWelcome(function (message, config)
    local sec = "FCY"
    autoslow = const(config:get(sec, "AUTO_SLOW", true))
    adminOnly = const(config:get(sec, "ADMIN_ONLY", true))
    dtLaps = const(config:get(sec, "LAPS_TO_SERVE_DT", 3))
    altLimiter = const(config:get(sec, "ALT_LIMITER", false))
    local adminFlags
    if adminOnly then 
        adminFlags = bit.bor(ui.OnlineExtraFlags.Tool, ui.OnlineExtraFlags.Admin)
    else
        adminFlags = ui.OnlineExtraFlags.Tool
    end
ui.registerOnlineExtra(ui.Icons.AppWindow, "FCY", nil, function ()
    stor.t = ui.slider("Deploy/Lift Time", stor.t, 0, 20, '%.0f sec')
    if ui.button("TOGGLE FCY") then
        
        castStatus({fcy=(not FCY), time=stor.t, req=false})
    end
    fcyToggle:control(vec2(100,100))
end, function (okClicked)
    
end, adminFlags)

end)


function castStatus(t)
    math.randomseed(sim.currentSessionTime)
    if not comms(t) then
        setInterval(function ()
            if comms(t) then
                return clearInterval
            end
        end, math.random())
    end
end

fcyToggle:onPressed(function ()
    if (adminOnly and sim.isAdmin) or not adminOnly then
    castStatus({fcy=(not FCY), time=stor.t, req=false})
    end
end)

comms = ac.OnlineEvent({
ac.StructItem.key("FCY"),
fcy=ac.StructItem.boolean(),
time=ac.StructItem.uint8(),
req=ac.StructItem.boolean()
}, function(sender, message)
    local timer = message.time

    ac.log(tostring(message.fcy) .. " " .. message.time .. " " .. tostring(message.req))
    if message.req then
        comms({ fcy=FCY, time=0, req=false })
    else
        if FCY ~= message.fcy then
            FCY = message.fcy

            setInterval(function()
                ac.log(timer)
                if timer > 0 then
                    if FCY then
                        ac.setMessage("FCY", "FCY DEPLOYED IN " .. timer, nil, 5)
                    else
                        ac.setMessage("FCY", "FCY LIFTED IN " .. timer, nil, 5)
                    end
                    timer = timer - 1
                else
                    if FCY then
                        ac.setMessage("FCY", "FCY DEPLOYED", nil, 5)
                    else
                        ac.setMessage("FCY", "FCY LIFTED", nil, 5)
                    end

                    force = FCY
                    return clearInterval
                end
            end, 1, "FCY")
        end
    end

end, ac.SharedNamespace.ServerScript)


local wasstop = false
local wasforce = false
local wasFCY = false
function script.update(dt)
    local stop = false

    if autoslow then       

        if (car.speedKmh > 85) and force then
        if physics.getCarInputControls().brake < 0.1 then
                if true then --ac.getCarOptimalBrakingAmount(0) == -1 then
                    stop = true
                else
                    physics.forceUserBrakesFor(0.1, math.max(ac.getCarOptimalBrakingAmount(0), 0.1))
                    physics.forceUserThrottleFor(0.1, 0)
                end
            end

        elseif car.speedKmh > 79 and force then
            if altLimiter then
                physics.setEngineRPM(0, car.rpm-(100 * (math.max(car.speedKmh-79, 0) )))
            else
                if not car.manualPitsSpeedLimiterEnabled then
                    physics.forceUserThrottleFor(dt, 0)
                end
            end
        end


    end

    if dtLaps > 0 then
        if car.speedKmh > 80.5 and force then
            physics.setCarPenalty(ac.PenaltyType.MandatoryPits, dtLaps)
        end
    end

    if FCY then
        if not wasFCY then
        physics.overrideRacingFlag(ac.FlagType.Caution)  
        end
        ac.setTurningLights(ac.TurningLights.Hazards)
    end

    if not force and wasforce then
        ac.setTurningLights(ac.TurningLights.None)
        physics.overrideRacingFlag(ac.FlagType.None)  
    end

    if stop and not wasstop then
        physics.setGentleStop(0, true)
    end
    if not stop and wasstop then
        physics.setGentleStop(0, false)
    end
    wasstop = stop
    wasforce = force
    wasFCY = FCY
end

castStatus({req=true})
