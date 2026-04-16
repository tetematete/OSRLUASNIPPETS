function script.update(dt)
    --ac.debug("input", ac.getControllerSteerValue(),-1,1)
    --ac.debug("compare", ac.getCar(0).steer/486,-1,1)
    --ac.debug("table", ac.getGamepadAxisValue(1, ac.GamepadAxis.LeftThumbX))
    --physics.overrideSteering(0, math.nan)
    physics.overrideSteering(0, ac.getControllerSteerValue())
end
