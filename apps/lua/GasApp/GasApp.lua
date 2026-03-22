local sim = ac.getSim()
local car = ac.getCar(0)

function script.windowMain()
    ui.pushFont(ui.Font.Title)
    ui.text("Fuel Remaining:")
    ui.text(math.round(car.fuel,1) .. "L/" .. car.maxFuel .. "L")
    --ui.progressBar((car.fuel/car.maxFuel),vec2(ui.windowWidth(), 20), nil)
end

