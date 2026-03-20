local serverURL
local parsedConfig
local ratingsTable
local timetableURL = "http://".. ac.getServerIP() .. ":" ..ac.getServerPortHTTP() .. "/timetable.json"
local timeTable
local displayTable= {}
local enabled = false
local colorOfTag = rgbm.colors.light
ac.debug("!version", "acsrtags v0.8")

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
    --local displayTable = ratingsTable["DriverACSRRatings"][timeTable["EntryList"][(ac.getCar(index).sessionID)+1]["GUID"]]
    local displayTable = ratingsTable["DriverACSRRatings"][timeTable["EntryList"][index.sessionID + 1]["GUID"]]

    if displayTable ~= nil then
      ui.drawRectFilled(vec2(420, 0), vec2(512, 64), rgbm.colors.gray, ui.CornerFlags.All)
      if displayTable["is_provisional"] then
        ui.drawRectFilled(vec2(424, 6), vec2(508, 58), rgbm.colors.orange, ui.CornerFlags.All)
        ui.setNextTextBold()
        ui.pushFont(ui.Font.Tiny)
        ui.drawTextClipped("Provisional", vec2(424, 6), vec2(508, 58), rgbm.colors.black, vec2(0.5, 0.1))
        ui.pushFont(ui.Font.Main)
        ui.setNextTextBold()
        ui.drawTextClipped(displayTable["num_events"] .. "/8", vec2(424, 6), vec2(508, 58), rgbm.colors.black,
          vec2(0.5, 0.8))
      else
        ui.drawRectFilled(vec2(424, 6), vec2(508, 30), rgbm.colors.blue, ui.CornerFlags.All)
        ui.drawRectFilled(vec2(424, 35), vec2(508, 58), rgbm(0, 0.5, 0.1, 1), ui.CornerFlags.All)
        ui.setNextTextBold()
        ui.drawTextClipped(displayTable["safety_rating"], vec2(424, 31), vec2(508, 58), rgbm.colors.white, vec2(0.5, 0))
        ui.setNextTextBold()
        ui.drawTextClipped(displayTable["skill_rating_grade"], vec2(424, 3), vec2(508, 58), rgbm.colors.white,
          vec2(0.5, 0))
      end
    end
  end
end, { tagSize = vec2(512, 64) })

ui.registerOnlineExtra(ui.Icons.Shield, "ACSR Tags", function ()return true end, function ()
  if ui.checkbox("Enable ACSR Tags", enabled) then
    enabled = not enabled
  end
end, function ()
  
end, ui.OnlineExtraFlags.None )

