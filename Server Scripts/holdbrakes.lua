SIM                        = ac.getSim()
CAR                        = ac.getCar(SIM.focusedCar)
Spend = 0
Boost = 0
MAX = 1000
Gain = 0.001
LastTime = 0
lastRead = 0
Read = 0
diff =0
counter = 0
warn = false
warningTime = 0
isWarning = 0
function script.update(dt)
    
    Points = CAR.driftPoints
    valid = CAR.isDriftValid
    instantPoints = CAR.driftInstantPoints
    bonus = CAR.isDriftBonusOn
    time = os.preciseClock()

    ac.debug('points', Points)

    ac.debug('inst points', instantPoints)

    ac.debug('time', time)

    ac.debug('ROC', diff)
    ac.debug('warn', warn)
    ac.debug('warn', warn)
    ac.debug('a', xPos)
    ac.debug('b', yPos)

    if diff > 50 then
        warningTime = time       
    end
    
    if (warningTime + 5) > time then
        warn = true 
        ui.drawIcon('ui.Icons.Gamepad', vec2(0,0), vec2(500,500))

    else 
        warn = false
    end

    if (time - LastTime) > 0.5 then
        counter = counter + 1
        LastTime = time
        lastRead = Read
        read = instantPoints

        diff = instantPoints - lastRead
    end
end 

function script.drawUI()
    if warn then
    xPos, yPos = (ui.windowSize()):unpack()
    ui.setCursor()
    --ui.drawText("text", vec2(0.4*xPos,0.4*yPos), rgbm.colors.red)
    --ui.dwriteDrawTextClipped("HOLD YOUR BRAKES", 0.05*yPos, vec2(0.345*xPos,0.03*yPos+50), vec2(0.65*xPos,0.5*yPos), ui.Alignment.Start, ui.Alignment.Start, false, rgbm.colors.red)
    ui.dwriteTextAligned("⚠️HOLD YOUR BRAKES⚠️", 0.05*yPos, ui.Alignment.Center, ui.Alignment.Center, vec2(1*xPos,0.4*yPos), false, rgbm.colors.red)

    --ui.drawIcon(ui.Icons.Gamepad, vec2(0.4*xPos,0.4*yPos), vec2(0.6*xPos,0.6*yPos))
    end
end