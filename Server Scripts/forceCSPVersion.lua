ac.debug("!version", "forceCSPVersion v1.2")

--If you intend to modify this script, leave these in. 
ac.debug("URL", "https://github.com/tetematete/OSRLUASNIPPETS/tree/main")
ac.debug("Credit", "original script by tetematete, co-owner of OSR. \nTo race with us, support us, or find more scripts like this one,\n follow the link below.")
local sim = ac.getSim()
local ver = {}
local explodePlayer = false
local versionCorrect = false
local newMenu = 0
local GUIConfig = ac.INIConfig.cspModule(ac.CSPModuleID.GUI)

ac.onOnlineWelcome(function (message, config)
    local sec = "CSPVERSION"
    for i = 1, 99, 1 do
        ver[i] = config:get(sec, "VERSION", ac.INIConfig.OptionalNumber, i)
    end

    for index, version in ipairs(ver) do
        if version == ac.getPatchVersionCode() then
            versionCorrect = true
        end
    end
    newMenu = config:get(sec, 'NEW_MENU_OFF', 0, 1)
        checkNewMainMenu()
    if versionCorrect then
        ac.log("Version Correct")
    else
        killPlayer()
    end
end)
ac.onCSPConfigChanged(ac.CSPModuleID.GUI, function()
        checkNewMainMenu()
end)

function checkNewMainMenu()
    GUIConfig = ac.INIConfig.cspModule(ac.CSPModuleID.GUI)
    if GUIConfig:get('NEW_UI', 'REPLACE_MAIN_MENU', 0, 1) == 1 and newMenu then
       killPlayer() 
    end
end

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

function script.drawUI(dt)
    if explodePlayer then
        ui.drawRectFilled(0, ui.windowSize(), rgbm(1, 0, 0, 0.3))
        local text = ''
        if versionCorrect == false then
            text = "Incorrect CSP Version.\nExpected: " ..
            table.concat(ver, ', ') .. "\nActual: " .. ac.getPatchVersionCode()
        end
        if newMenu and GUIConfig:get('NEW_UI', 'REPLACE_MAIN_MENU', 0, 1) == 1 then
            text = text .. '\nNew Menu Detected, Please Disable to race.'
        end

        ui.dwriteTextAligned(
            text, 50,
            ui.Alignment.Center, ui.Alignment.Center, ui.windowSize(), false, rgbm.colors.yellow)
    end
end