local timer = 5
local screensize = vec2(ac.getSim().windowWidth, ac.getSim().windowHeight)

local cspChatWindow = ac.accessAppWindow('CHAT')

ac.onResolutionChange(function(newSize, makingScreenshot)
    screensize = vec2(ac.getSim().windowWidth, ac.getSim().windowHeight)
end)
function script.update(dt)
    if not cspChatWindow:visible() then cspChatWindow:setVisible(true) end
    --ac.debug("t", timer)
    if not ac.getSim().isInMainMenu then
        if timer >= 0 then
            timer = timer - dt
        end
    else
        timer = 5
    end
end

function script.drawUI(dt)
    if timer > 0 then
        ui.pushFont(ui.Font.Title)
        ui.setCursor(screensize / 2 - screensize/10)
        ui.text("use the lightbulb")
        ui.sameLine()
        ui.icon(ui.Icons.Bulb, vec2(32, 32))
        ui.sameLine()
        ui.text("to change color\nor practice a race start!")
        ui.drawLine(screensize / 2 - screensize/14, cspChatWindow:position() + 100, rgbm.colors.red, 5)
    end
end
