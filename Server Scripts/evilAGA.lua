ac.debug("!version", "evilAGA v0.6")
if ac.getSim().inputMode ~= ac.UserInputMode.Wheel then

physics.startPhysicsWorker([[

function script.update(dt)
    physics.overrideSteering(0, ac.getControllerSteerValue())
end

]], function(err)
    ac.log(err)
    end)
end
