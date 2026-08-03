ac.debug("!version", "forceCSPVersion v1.0")

--If you intend to modify this script, leave these in. 
ac.debug("URL", "https://github.com/tetematete/OSRLUASNIPPETS/tree/main")
ac.debug("Credit", "original script by tetematete, co-owner of OSR. \nTo race with us, support us, or find more scripts like this one,\n follow the link below.")
local sim = ac.getSim()
local ver = 0
local explodePlayer = false

ac.onOnlineWelcome(function (message, config)
    local sec = "CSPVERSION"
    ver = config:get("CSPVERSION", "VERSION", ac.INIConfig.OptionalNumber)
    if ac.getPatchVersionCode() == ver then
        ac.log("Version Correct")
        function script.drawUI(dt)
        end
    else
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
end)

function script.drawUI(dt)
    if explodePlayer then
    ui.drawRectFilled(0, ui.windowSize(), rgbm(1, 0, 0, 0.3))
    ui.dwriteTextAligned(
    "Incorrect CSP Version.\nExpected: " .. ver .. "\nActual: " .. ac.getPatchVersionCode(), 50,
        ui.Alignment.Center, ui.Alignment.Center, ui.windowSize(), false, rgbm.colors.yellow)
    end
end




