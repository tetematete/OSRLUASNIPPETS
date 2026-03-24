local timeTable
local liveTimingsTimer = 2
local timetableURL = "http://".. ac.getServerIP() .. ":" ..ac.getServerPortHTTP() .. "/timetable.json"
local enabled = true
local serverNumber
ac.debug("!version", "ACSMINFO v0.9")

ac.onOnlineWelcome(function(message, config) --Reads the script config from the extra options config
  serverURL = config:get("ACSMINFO", "SERVER_URL", "")
  serverNumber = config:get("ACSMINFO", "SERVER_NUMBER", 0)
  timeTableModeEnabled =  config:get("ACSMINFO", "TIMETABLE_MODE", 0)
end)

function getLiveTimings()
  if timeTableModeEnabled == 0 then
    web.get(serverURL .. "/api/live-timings/basic.json?server=" .. serverNumber, function(err, response)
      if JSON.parse(response.body) ~= nil then
        timeTable = JSON.parse(response.body)
      end
      liveTimingsTimer = 1
    end)
  else
    web.get(timetableURL, function(err, response)
      if JSON.parse(response.body) ~= nil then
        timeTable = JSON.parse(response.body)
      end
      liveTimingsTimer = 1
    end)
  end


end

function script.update(dt)
  ac.debug("server", timeTable)
  for index, value in ac.iterateCars.serverSlots() do
      ac.debug(value:driverName(), value.racePosition)
  end

  if liveTimingsTimer < 0 then
    getLiveTimings()
    liveTimingsTimer = 1
  end
  liveTimingsTimer = liveTimingsTimer - dt

  if enabled then
    if timeTable ~= nil then
      if timeTableModeEnabled == 0 then
        for i, value in ipairs(timeTable["ConnectedDrivers"]) do
          ac.log(value["DriverName"] .. " ".. ac.getCarByDriverName(value["DriverName"]):driverName(), value["Position"])
          ac.setRaceScore(ac.getCarByDriverName(value["DriverName"]), value["Position"])
        end
      else
        for index, value in ac.iterateCars.serverSlots() do

        end
      end
    end
  else
    for index, value in ac.iterateCars() do
      ac.setRaceScore(value.index, math.nan)
    end
  end
end

ui.registerOnlineExtra(ui.Icons.Shield, "ACSM Info", function ()return true end, function ()
  if ui.checkbox("Enable ASCMINFO", enabled) then
    enabled = not enabled
  end
end, function ()
  
end, ui.OnlineExtraFlags.None )
