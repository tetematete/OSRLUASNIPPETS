local serverURL
local parsedConfig
local ratingsTable
local timetableURL = "http://".. ac.getServerIP() .. ":" ..ac.getServerPortHTTP() .. "/ENTRY"
local timeTable
local displayTable
local enabled = false
local classColours = {Intermediate=rgbm.colors.green, ["Noob Class"] = rgbm.colors.yellow}
ac.debug("!version", "acsrtags v0.9")

ac.onOnlineWelcome(function(message, config) --Reads the script config from the extra options config
    parsedConfig = tostring(config)

    serverURL = config:get("ACSRTAGS", "CHAMPIONSHIP_URL", "")

    
    web.get(serverURL .. "/standings.json", function(err, response)
        ratingsTable = JSON.parse(response.body)

        for class, cars in pairs(ratingsTable["DriverStandings"]) do
          for index, value in ipairs(cars) do
            ratingsTable["DriverACSRRatings"][value["Car"]["Driver"]["Guid"]]["Class"] = class
          end
          
        end
        --ac.debug("ratings", ratingsTable)
        --web.get(timetableURL, function(err, response)
            --timeTable = JSON.parse(response.body)
            web.get(timetableURL, function(err, response) 
              timeTable = entryEndpointParse(response.body)
          if timeTable ~= nil and ratingsTable ~= nil then
            enabled = true
          end
        end)
    end)
end)

ac.onClientConnected(function (connectedCarIndex, connectedSessionID)
    web.get(timetableURL, function(err, response) 
      local trytimeTable = entryEndpointParse(response.body)
      if not err and response.body ~= nil then
        timeTable = trytimeTable
      end
    end)
end)


ui.onDriverNameTag(false, nil, function(index)

  if enabled then
    --local displayTable = ratingsTable["DriverACSRRatings"][timeTable["EntryList"][(ac.getCar(index).sessionID)+1]["GUID"]]
    local displayTable = ratingsTable["DriverACSRRatings"][timeTable[index.sessionID + 1]["Guid"]]

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
      ui.drawQuadFilled(vec2(50,0), vec2(65,0),vec2(45,64),vec2(30,64), classColours[displayTable["Class"]])
    else 
        ui.drawRectFilled(vec2(420, 0), vec2(512, 64), rgbm.colors.gray, ui.CornerFlags.All)
        ui.drawRectFilled(vec2(424, 6), vec2(508, 58), rgbm.colors.orange, ui.CornerFlags.All)
        ui.setNextTextBold()
        ui.pushFont(ui.Font.Tiny)
        ui.drawTextClipped("Provisional", vec2(424, 6), vec2(508, 58), rgbm.colors.black, vec2(0.5, 0.1))
        ui.pushFont(ui.Font.Main)
        ui.setNextTextBold()
        ui.drawTextClipped("0/8", vec2(424, 6), vec2(508, 58), rgbm.colors.black,
          vec2(0.5, 0.8))
      
    end

  end
end, { tagSize = vec2(512, 64) })

ui.registerOnlineExtra(ui.Icons.Shield, "ACSR Tags", function ()return true end, function ()
  if ui.checkbox("Enable ACSR Tags", enabled) then
    enabled = not enabled
  end
end, function ()
  
end, ui.OnlineExtraFlags.None )

function entryEndpointParse(data)
  local parsedTable = {}
  local keys = {}
  local entryTable = string.match(data, "<table>(.-)</table>")
  --ac.debug("entry", entryTable)

  local rowMatches = 0
  for tr in string.gmatch(entryTable, "<tr>(.-)</tr>") do
    rowMatches = rowMatches + 1
    local rowData = {}
    local divMatches = 0

    
    for td in string.gmatch(tr, "<td>(.-)</td>") do
      
      divMatches = divMatches + 1
      if rowMatches == 1 then keys[divMatches] = td else
        rowData[keys[divMatches]] = td
      end
      
    end
    if rowMatches == 1 then
      
    else
      parsedTable[rowMatches-1] = rowData
    end
  end

  return parsedTable
end

--[[web.get("http://70.51.165.122:8082/ENTRY", function (err, response)
  ac.debug("body", response.body)
  ac.debug("Parsed", entryEndpointParse(response.body))
end)]]

