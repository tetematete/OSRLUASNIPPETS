ac.debug("!version", "forceCSPVersion v1.1")

--If you intend to modify this script, leave these in. 
ac.debug("URL", "https://github.com/tetematete/OSRLUASNIPPETS/tree/main")
ac.debug("Credit", "original script by tetematete, co-owner of OSR. \nTo race with us, support us, or find more scripts like this one,\n follow the link below.")
local sim = ac.getSim()
local ver = {}
local explodePlayer = false
local versionCorrect = false

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
    

    if versionCorrect then
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
    "Incorrect CSP Version.\nExpected: " .. table.concat(ver, ', ') .. "\nActual: " .. ac.getPatchVersionCode(), 50,
        ui.Alignment.Center, ui.Alignment.Center, ui.windowSize(), false, rgbm.colors.yellow)
    end
end




