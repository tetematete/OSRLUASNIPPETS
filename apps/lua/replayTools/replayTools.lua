local sim = ac.getSim()
local app_folder = ac.getFolder(ac.FolderID.ACApps) .. '/lua/replayTools/'
local resultsPage = nil
local penaltyTable = {}
local resultsFile = JSON.parse(ac.load("resultsFile"))
local sortedResultsFile = JSON.parse(ac.load("sortedResultsFile"))
local page = 0
local selectedDriver = ""
local resultsFilepath = ""
local replaySyncTime = 0
local settings = ac.storage{
  URL = "",
  serverNumber = "0"
}
local URL = settings.URL
local serverNumber = settings.serverNumber
local collisionTable = {{car1 = 0, car2 = 0, speed = 0, timestamp = sim.currentSessionTime}}
local penaltyLinkEnabled = false
local penaltyLinkTimeout = 0
local reversePenaltyTable
local openInReplay = false
local softTime = 0
  

local replaystream = ac.ReplayStream({
  ac.StructItem.key("replayLinkSync"),
  time = ac.StructItem.int32()
}, function() end)

function script.windowMain(dt)

  ui.tabBar("Replay Tools", function()
   ui.tabItem("ACSM Link", function()
      if ui.button("Autofill") then
        searchQuery = "+" .. ac.getTrackID()
      end
      URL, URLChanged, URLConfirm = ui.inputText("ACSM URL (no ?server=)", URL, bit.bor(ui.InputTextFlags.RetainSelection, ui.InputTextFlags.Placeholder)) 
      if URLConfirm then
        settings.URL = URL
      end

      ui.indent() serverNumber, serverNumberChanged, serverNumberConfirm = ui.inputText("multiserver Number", serverNumber, bit.bor(ui.InputTextFlags.RetainSelection, ui.InputTextFlags.CharsDecimal)) 
      if serverNumberConfirm then
        settings.serverNumber = serverNumber
      end
      ui.unindent()
      ui.newLine()

      local searchQuery, searchChanged, searchConfirm = ui.inputText("Search for results", searchQuery,
        ui.InputTextFlags.RetainSelection)
      local searchConfirmButton = ui.button("Search Results")
      ui.sameLine()
      if ui.checkbox("Connect To Penalties Log", penaltyLinkEnabled) then
        penaltyLinkEnabled = not penaltyLinkEnabled
        
      end

      --ac.debug("c", ui.combo("Session Type", "Session Type", ui.ComboFlags.None, function() ui.menuItem()end))


      if resultsPage ~= nil then
        ui.childWindow("Results List", vec2(400, ui.windowHeight()-300), function()
          if resultsPage["results"] ~= nil then
            for index, v in ipairs(resultsPage["results"]) do
              if ui.menuItem(isoTimetoReadable(v["date"]) .. " | " .. (v["session_type"]) .. " at " .. v["track"], selectedResults == index) then
                selectedResults = index
                resultsFilepath = v["results_json_url"]
              end
            end
          else
            ui.text("No Results Found or Too Many Requests!")
          end
        end) --end Results List Window

        ui.combo("page", page, ui.ComboFlags.None, function()
          for index = 0, resultsPage["num_pages"], 1 do
            if ui.selectable(index) then
              page = index
            end
          end
        end)
        if ui.button("Load Results File") then
          loadResults(resultsFilepath)
        end
      end --Results Availiable end



      if searchConfirm or searchConfirmButton then
        loadResultsList(searchQuery, page, serverNumber)
        ac.log(searchQuery)
      end
    end) --End results File Tab

    ui.tabItem("Replay Data", function()
      ui.tabBar("ReplayControls", function()
        ui.tabItem("Events", function()
          --ac.debug("frame", sim.replayCurrentFrame)
          --ac.debug("total", sim.replayFrames)
          --ui.columns(2, true, "columnlayout")
          ui.combo("Driver", selectedDriver, function()
            if ui.selectable("None") then
              selectedDriver = ""
              reSortEventTable()
            end
            for index, value in ipairs(sortedResultsFile["Cars"]) do
              if ui.selectable(value["Driver"]["Name"]) then
                selectedDriver = value["Driver"]["Name"]
                reSortEventTable()
              end
            end
          end)

          if sortedResultsFile ~= nil then
            if ui.checkbox("exclude env collisions", excludeEnvCollisions) then
              excludeEnvCollisions = not excludeEnvCollisions
              reSortEventTable()
            end
            ui.sameLine()
            if ui.checkbox("remove Obvious Dupes", removeObviousDupes) then
              removeObviousDupes = not removeObviousDupes
              reSortEventTable()
            end

            ui.childWindow("Event Table", vec2(ui.windowWidth()-50, ui.windowHeight()-150), function()
              local replayStartTime = (sortedResultsFile["Laps"][1]["Timestamp"] - (sortedResultsFile["Laps"][1]["LapTime"] / 1000)) -
                  sortedResultsFile["SessionConfig"]["wait_time"]
              --ac.log(replayStartTime)
              --ac.debug("Events", resultsFile["Laps"])
              for index, value in ipairs(sortedResultsFile["Events"]) do
                if value ~= "" then
                 -- if
                  --(value["Type"] ~= eventsortCheck) and

                  --(value["Driver"]["Name"] ~= sortedResultsFile["Events"][math.min(index + 1, #sortedResultsFile["Events"])]["OtherDriver"]["Name"]) and
                      --((selectedDriver == "") or (value["Driver"]["Name"] == selectedDriver or value["OtherDriver"]["Name"] == selectedDriver)) 
                      -- then
                    if ui.button(index .. " | " .. ac.lapTimeToString(((value["Timestamp"] - replayStartTime - 3) - ((value["Timestamp"] - replayStartTime - 3) * 0.0013)) * 1000, true) .. " " .. value["Driver"]["Name"] .. " " .. ((value["Type"] == "COLLISION_WITH_CAR" and "with") or (value["Type"] == "COLLISION_WITH_ENV" and "With Environment. lmao.")) .. " " .. value["OtherDriver"]["Name"] .. " at " .. math.round(value["ImpactSpeed"], 2) .. " km/h") then
                      ac.setReplayPosition(
                        (((value["Timestamp"] - replayStartTime - 5) - ((value["Timestamp"] - replayStartTime - 5) * 0.0013)) * 1000) /
                        sim.replayFrameMs, 1)

                      if ac.getCarByDriverName(value["Driver"]["Name"]) ~= -1 then 
                        ac.focusCar(ac.getCarByDriverName(value["Driver"]["Name"]))
                      elseif  ac.getCarByDriverName(value["OtherDriver"]["Name"]) ~= -1 then
                        ac.focusCar(ac.getCarByDriverName(value["OtherDriver"]["Name"]))
                      end
                     -- ac.focusCar(math.max(ac.getCarByDriverName(value["Driver"]["Name"]), (ac.getCarByDriverName(value["OtherDriver"]["Name"]))))

                    end
                  --end
                end
              end
            end)
          end
          --ui.nextColumn()

          ui.columns(1, true, "columnlayout")
        end) --events tab

        ui.tabItem("Info", function ()

        end)

        ui.tabItem("Save/Load", function ()
          
        end)

        ui.tabItem("Edit",function ()
          
        end)
      end)   --Replay Controls Tab Bar
    end)     --Replay Data Tab

    ui.tabItem("PenaltyLink", ui.TabItemFlags.None, function()
      --ui.combo("sortPenalties", sortTable, ui.ComboFlags.GoUp, function ()
      penaltySort = ui.inputText("Search", penaltySort, ui.InputTextFlags.ClearButton)
  
      if (not (sim.isReplayOnlyMode)) and sim.isReplayActive then
        if ui.button("Catch Up") then
          ac.setReplayPosition(sim.replayFrames, 1)
        end
        ui.sameLine()
        if ui.button("Exit Live Replay") then
          ac.tryToToggleReplay(false)
        end
      else
        if ui.checkbox("Open in replay", openInReplay) then
          openInReplay = not openInReplay
        end
      end
    ui.sameLine()
    if ui.checkbox("Ascending", sortPenaltiesAscending) then
      sortPenaltiesAscending = not sortPenaltiesAscending
    end

      if penaltySort == nil then
        sortCheck = false
      else
        sortCheck = true
      end

      --if ui.checkbox("reverse", reversePenaltyTable ) then
      --  reversePenaltyTable = not reversePenaltyTable
      --end
      if sortedPenaltyTable ~= nil then
      ui.childWindow("PenaltyWindow", vec2(500,500), function()
      
      if sortPenaltiesAscending then
      for index, value in ipairs(penaltyTable) do
        makePenaltyTable(index,value)
      end
    else
      for index, value in reverseIterator(penaltyTable) do
        makePenaltyTable(index,value)
      end   
    end
      


    end)
    end
    end)

    ui.tabItem("About and Tutorial", ui.TabItemFlags.None, function ()
        ui.text("Just dm me lmao i no wanna write one rn")      
    end)
  end)
--ac.debug("time", replaystream.time)
--ac.debug("sestime", sim.currentSessionTime)

end

function makePenaltyTable(index, value)
        if (sortCheck and (string.match(JSON.stringify(value), penaltySort))) or (not sortCheck)then
          if ui.button((os.parseDate(value["time"], '%Y-%m-%dT%H:%M:%S') - softTime) .. " | " .. value["driver_name"] .. " " .. value["name"] .. " " .. value["context"] .. " | " .. value["type"]) then
            if openInReplay then
            ac.tryToToggleReplay(true)
            end
            ac.focusCar(ac.getCarByDriverName(value["driver_name"]))
            ac.setReplayPosition(
            sim.replayCurrentFrame +
            ((((os.parseDate(value["time"], '%Y-%m-%dT%H:%M:%S') - softTime) - 10) * 1000)) / sim.replayFrameMs, 1)
          end
        end
end


function reSortEventTable()
  sortedResultsFile = JSON.parse(ac.load("resultsFile")) --For some reason resultsFile is also getting changed here, so load from storage. sure ig.
  for index, value in ipairs(sortedResultsFile["Events"]) do
    if ((value["Type"] == "COLLISION_WITH_ENV") and excludeEnvCollisions)
        or
        ((value["Driver"]["Name"] == sortedResultsFile["Events"][math.min(index + 1, #sortedResultsFile["Events"])]["OtherDriver"]["Name"]) and removeObviousDupes)
        or
        not (((selectedDriver == "") or (value["Driver"]["Name"] == selectedDriver or value["OtherDriver"]["Name"] == selectedDriver)))
    then
      sortedResultsFile["Events"][index] = ""
    end
  end

  --ac.debug("file2", sortedResultsFile["Events"])
  --ac.debug("file", resultsFile["Events"])
end

function reSortPenaltiesTable()
  sortedPenaltyTable = penaltyTable

end


function script.update(dt)
  --  ac.debug("a", replaystream.time)
  
  softTime = replaystream.time

  if not sim.isReplayOnlyMode then
    
    replaystream.time = sim.systemTime
    --ac.debug(" ", replaystream.time)
  end

  
      if penaltyLinkEnabled and penaltyLinkTimeout < 0 then
        linkToPenaltiesLog(serverNumber)
        ac.log("request")
        penaltyLinkTimeout = 5
        
      end
      penaltyLinkTimeout = penaltyLinkTimeout - dt
end
--[[ac.onCarCollision(-1, function (carIndex)
  local car = ac.getCar(carIndex)
  --if not(collisionTable[#collisionTable]["car1"] == carIndex and sim.currentSessionTime-collisionTable[#collisionTable]["timestamp"]<1000) then
  table.insert(collisionTable, {car1 = carIndex, car2 = car.collidedWith, speed = car.collisionDepth, timestamp = sim.currentSessionTime}) 
  ac.log(collisionTable[#collisionTable])
  ac.focusCar(carIndex)
  --end
  ac.writeReplayBlob("replayLink", JSON.stringify(collisionTable))
end)]]


ac.onReplay(function(event)
  if event == "start" then
    --[[if replaystream.time ~= 0 then
    replaySyncTime = replaystream.time      
    else
    ac.setReplayPosition(5000/sim.replayFrameMs,1)
    replaySyncTime = replaystream.time 
    end]]
    replaySyncFrame = sim.replayCurrentFrame
    ac.log("replay start time init to " .. ac.lapTimeToString(replaySyncTime,true ) .. replaySyncFrame)
  end
  if event == "jump" then
    ac.log("jumped to:" .. os.dateGlobal("%H:%M:%S", replaystream.time) .. " sync: " .. ac.lapTimeToString(replaySyncTime,true))
  end

  ac.log(event)
end)

function loadResultsList(input, pageNumber, server)

  local query = string.urlEncode(tostring(input), true)
if input == nil then
  query = "" 
end
  local sort = "date"

  web.get(settings.URL .. "/api/results/list.json?q=" .. query .. "&sort=" .. sort .. "&page=" .. pageNumber .. "&server=" .. server, function(err, response)
    --ac.debug("error", error)
    resultsPage = JSON.parse(response.body)
  end)
  ac.log(settings.URL .. "/api/results/list.json?q=" .. query .. "&sort=" .. sort .. "&page=" .. pageNumber .. "&server=" .. server)
end

function linkToPenaltiesLog(server)
  web.get(settings.URL .. "/race-control/penalties-log.json?server=" .. server, function (err, response)
    --ac.debug("error", error)
    penaltyTable = JSON.parse(response.body)
    if reversePenaltyTable then
      penaltyTable = ReverseTable(penaltyTable)
    end
    reSortPenaltiesTable()
  end)

end

function loadResults(file)
  --file = io.load(app_folder .. "/2026_1_3_13_15_RACE.json", "error")
  web.get(settings.URL .. file, function (err, response)
    resultsFile = JSON.parse(response.body)
    ac.store("resultsFile", response.body)

    sortedResultsFile = resultsFile
    ac.store("sortedResultsFile", response.body)

    ac.log(settings.URL .. file)

  end)

  
end

function script.windowSettings()
  ui.button("true")
end

function isoTimetoReadable(time)
return os.date('%Y-%m-%d %H:%M:%S',(os.parseDate(time,'%Y-%m-%dT%H:%M:%S')))
--return year .. "-" .. month .. "-" .. day .. " " .. hour .. ":" .. minute
end

function ReverseTable(t) --not mine, you can tell bc it's elegant
    local reversedTable = {}
    local itemCount = #t
    for k, v in ipairs(t) do
        reversedTable[itemCount + 1 - k] = v
    end
    return reversedTable
end

function reverseIterator(array)
   -- create a closure
   local function reverse(array,i)
      -- decrement the index
      i = i - 1
      -- if i is not 0
      if i ~= 0 then
         return i, array[i]
      end
   end
   -- call the closure
   return reverse, array, #array+1
end
