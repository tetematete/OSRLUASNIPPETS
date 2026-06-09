ac.debug("!version", "evilAGA v0.7")
ac.debug("csp:", ac.getPatchVersionCode())

if ac.getSim().inputMode ~= ac.UserInputMode.Wheel then
    if ac.getPatchVersionCode() >= 3978 then
        physics.startPhysicsWorker([[
            function script.update(dt)
                physics.overrideSteering(0, ac.getControllerSteerValue())
            end
]], function(err)
            ac.log(err)
        end)
    else
        function script.update(dt)
            physics.overrideSteering(0, ac.getControllerSteerValue())
        end
    end
end


