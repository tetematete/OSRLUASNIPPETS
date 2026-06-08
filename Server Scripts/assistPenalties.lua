ac.debug("!version", "assistPenalties v0.5")
local sim = ac.getSim()
local car = ac.getCar(0)
local scriptReady = false
local penaltiesTable = {}

local initialBallast = car.ballast
local initialRestrictor = car.restrictor

local lockABS = false
local lockTC = false
local chosenABS = 0
local chosenTC = 0

ac.onOnlineWelcome(function(message, config)
  for index, value in config:iterate("ASSISTPEN") do
    local parsedSection = JSON.stringify(config:mapSection(value, {ABS_RES_BAL = { 0, 0 }, TC_RES_BAL = { 0, 0 } }))
    local parsedCars = config:mapSection(value, {CAR_FOLDER={"other"}})

    for index2, value2 in pairs(parsedCars["CAR_FOLDER"]) do
      penaltiesTable[value2] = JSON.parse(parsedSection)
    end
  end

  --ac.log(penaltiesTable)
  refreshPenalties()
  scriptReady = true
end)

function refreshPenalties()
  local carID = ac.getCarID(0)
  if penaltiesTable[carID] == nil then carID = "other" end
  local carPenalties = penaltiesTable[carID]
  chosenTC, chosenABS = car.tractionControlMode, car.absMode
  if tonumber(carPenalties["ABS_RES_BAL"][1]) == 0 and tonumber(carPenalties["ABS_RES_BAL"][2]) == 0 then
    ac.log("No abs penalty set")
  else
    lockABS = true
  end
  if tonumber(carPenalties["TC_RES_BAL"][1]) == 0 and tonumber(carPenalties["TC_RES_BAL"][2]) == 0 then
    ac.log("No TC penalty set")
  else
    lockTC = true
  end

    physics.setCarRestrictor(0, initialRestrictor + tonumber(carPenalties["TC_RES_BAL"][1]) + tonumber(carPenalties["ABS_RES_BAL"][1]))
    physics.setCarBallast(0, initialBallast + tonumber(carPenalties["TC_RES_BAL"][2]) + tonumber(carPenalties["ABS_RES_BAL"][2]))
  ac.log("Penalties Refreshed. TC: " .. (lockTC and "true" or "false") .. " ".. chosenTC )
  ac.log("Penalties Refreshed. ABS: " .. (lockABS and "true" or "false") .. " ".. chosenABS )
end


local wasMenu = false
function script.update(dt)
  --ac.debug("a", car.restrictor .. " " .. car.ballast)
  --ac.debug("tc", car.tractionControlMode)
  --ac.debug("abs", car.absMode)

  if scriptReady then
    if sim.isInMainMenu ~= wasMenu then
      refreshPenalties()
    end
    if not sim.isInMainMenu then
      if lockTC and car.tractionControlMode ~= chosenTC then
        ac.setTC(chosenTC)
        ac.setMessage(nil, nil, nil, 1)
        ac.setMessage("TC", "TC LOCKED", nil, 5)
      end

      if lockABS and car.absMode ~= chosenABS then
        ac.setABS(chosenABS)
        ac.setMessage(nil, nil, nil, 1)
        ac.setMessage("TC", "ABS LOCKED", nil, 5)
      end
    end
  else

  end
  wasMenu = sim.isInMainMenu
end
