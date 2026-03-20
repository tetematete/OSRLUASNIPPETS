local serverURL
local parsedConfig
local ratingsTable
local timetableURL = ac.getServerIP() .. ":" ..ac.getServerPortHTTP() .. "/timetable.json"
local timeTable
local displayTable= {}
local enabled = false
local colorOfTag = rgbm.colors.light
ac.debug("!version", "acsrtags v0.6")

ac.onOnlineWelcome(function(message, config) --Reads the script config from the extra options config
    parsedConfig = tostring(config)

    serverURL = config:get("ACSRTAGS", "CHAMPIONSHIP_URL", "")


    web.get(serverURL .. "/standings.json", function(err, response)
        ratingsTable = JSON.parse(response.body)
        web.get(timetableURL, function(err, response)
            timeTable = JSON.parse(response.body)

          if timeTable ~= nil and ratingsTable ~= nil then
            enabled = true
          end
        end)
    end)

end)

ui.onDriverNameTag(false, nil, function(index)

  
  if enabled then
    local displayTable = ratingsTable["DriverACSRRatings"][timeTable["EntryList"][(ac.getCar(0).sessionID)+1]["GUID"]]
    ui.drawRectFilled(vec2(420,0),vec2(512,64), rgbm.colors.gray, ui.CornerFlags.All)
    ui.drawRectFilled(vec2(424,6),vec2(508,30), rgbm.colors.blue, ui.CornerFlags.All)
    ui.drawRectFilled(vec2(424,35),vec2(508,58), rgbm(0,0.5,0.1,1), ui.CornerFlags.All)

    ui.drawTextClipped(displayTable["safety_rating"], vec2(424,31), vec2(508,58), rgbm.colors.white, vec2(0.5,0))
    ui.drawTextClipped(displayTable["skill_rating_grade"], vec2(424,3), vec2(508,58), rgbm.colors.white, vec2(0.5,0))

  end

end, {tagSize=vec2(512,64)})

ui.registerOnlineExtra(ui.Icons.Shield, "ACSR Tags", function ()return true end, function ()
  if ui.checkbox("Enable ACSR Tags", enabled) then
    enabled = not enabled
  end
end, function ()
  
end, ui.OnlineExtraFlags.None )

