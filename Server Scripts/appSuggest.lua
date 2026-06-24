ac.debug("!version", "shelf v0.1")
local appShelf = require('shared/utils/appshelf')
local done = false
local sim = ac.getSim()
local wasMenu = true
local check

setTimeout(function() --Wait 5 Seconds to ensure all available apps are loaded.
    local apps = ac.getAppWindows()
    local hasRadar = false
    local hasSetupExchange = false
    ac.debug("apps", apps)

    for index, value in ipairs(apps) do --Iterate installed apps in search of Radar app
        if value.name == "IMGUI_LUA_Radar_main" then
            hasRadar = true
        end
    end

    ac.log(hasRadar, hasSetupExchange)

    if not hasRadar then
        check = setInterval(function() --If radar is not detected, wait until player leaves the main menu.
            if not done then
                if (not sim.isInMainMenu and wasMenu) then --Once main menu left, offer to install radar and clear interval, ending script.
                    appShelf.offer({ id = 'Radar', reason =
                    'Please install the reccomended Radar app. you can resize, recolour, and tweak the app from the settings icon in the app window. \nMore performant and better visibility than CMRT, Helicorsa, etc.' })
                    clearInterval(check)
                end

                wasMenu = sim.isInMainMenu
            end
        end, 1, "radarCheckInterval")
    end
end, 5, 'appLoadDelay')
