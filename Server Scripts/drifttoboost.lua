SIM                        = ac.getSim()
CAR                        = ac.getCar(SIM.focusedCar)
Spend = 0
Boost = 0
MAX = 1000
Gain = 0.001
function script.update(dt)
    Points = CAR.driftPoints
    Boost = Points - Spend
    if Boost > MAX then
        Spend = Spend + (Boost-MAX)
    end
    --ac.setAppsHidden(true)
    ac.debug('points', Points)
    ac.debug('Boost', Boost)
    ac.debug('Spend', Spend)
    --physics.addWheelTorque(CAR, ac.Wheel.All, 0)
    physics.setCarBallast(CAR, 0)

    if ((CAR.hornActive == true) and (Boost >= 1)) then
    physics.addForce(CAR, vec3(0,0,2), true, vec3(0,-1000,50000), true, -1)
    Spend = Spend + 1
    else
    Spend = Spend + Gain*Boost    
    end

    ac.debug('kers', CAR.hornActive)
end
