local timeTable
local liveTimingsTimer = 2
local enabled = true
local serverNumber
ac.debug("!version", "ACSMINFO v0.5")

ac.onOnlineWelcome(function(message, config) --Reads the script config from the extra options config
  serverURL = config:get("ACSMINFO", "SERVER_URL", "")
  serverNumber = config:get("ACSMINFO", "SERVER_NUMBER", 0)
end)

function getLiveTimings()
  web.get(serverURL .. "/api/live-timings/basic.json?server=" .. serverNumber, function(err, response)
    if JSON.parse(response.body) ~= nil then
      timeTable = JSON.parse(response.body)
    end
    liveTimingsTimer = 1
  end)
end

function script.update(dt)
  ac.debug("server", timeTable)
  if liveTimingsTimer < 0 then
    getLiveTimings()
    liveTimingsTimer = 1
  end
  liveTimingsTimer = liveTimingsTimer - dt

  if timeTable ~= nil then
    for i, value in ipairs(timeTable["ConnectedDrivers"]) do
      ac.setRaceScore(ac.getCarByDriverName(value["DriverName"]), value["Position"])
    end
  end
end
