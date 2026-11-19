ac.debug("!version", "noGamepadAssist v0.1")
local sim = ac.getSim()
local explodePlayer = false

function killPlayer()
            setInterval(function ()
            if not sim.isInMainMenu then
                explodePlayer = true
                setTimeout(function ()
                    ac.log("Kicking!")
                    ac.shutdownAssettoCorsa()
                end, 5)
                return clearInterval
            end
        end, 0)
end


ac.onCSPConfigChanged(ac.CSPModuleID.GamepadFX, function()
        checkGamepadScript()
end)

function checkGamepadScript()
    local config = ac.INIConfig.cspModule(ac.CSPModuleID.GamepadFX)
    ac.log(config:get('JOYPAD_ASSIST', 'ENABLED', false, 1))
    if config:get('JOYPAD_ASSIST', 'ENABLED', false, 1) and sim.inputMode ~= ac.UserInputMode.Wheel then
       killPlayer() 
    end
end

checkGamepadScript()


function script.drawUI(dt)
    if explodePlayer then
        ui.drawRectFilled(0, ui.windowSize(), rgbm(1, 0, 0, 0.3))
        local text = ''

            text = text .. 'Please Disable Gamepad Assist Script.'


        ui.dwriteTextAligned(
            text, 50,
            ui.Alignment.Center, ui.Alignment.Center, ui.windowSize(), false, rgbm.colors.yellow)
    end
end