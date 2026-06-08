ac.debug("!version", "assistPenalties v1.1")

--If you intend to modify this script, leave these in. 
ac.debug("URL", "https://github.com/tetematete/OSRLUASNIPPETS/tree/main")
ac.debug("Credit", "original script by tetematete, co-owner of OSR. \nTo race with us, support us, or find more scripts like this one,\n follow the link below.")
--I mean it :)

local sim = ac.getSim()
local car = ac.getCar(0)
local scriptReady = false
local penaltiesTable = {}

local initialBallast = car.ballast
local initialRestrictor = car.restrictor
ac.log("Initial Ballast, Restrictor: " .. initialBallast .. "   " .. initialRestrictor)
local absUp = ac.ControlButton("ABSUP")
local absDn = ac.ControlButton("ABSDN")
local tcUp = ac.ControlButton("TCUP")
local tcDn = ac.ControlButton("TCDN")

local lockABS = false
local lockTC = false
local chosenABS = 0
local chosenTC = 0
local carPenalties

ac.onOnlineWelcome(function(message, config)
  for index, value in config:iterate("ASSISTPEN") do
    local parsedSection = JSON.stringify(config:mapSection(value, {ABS_RES_BAL = { 0, 0, -1 }, TC_RES_BAL = { 0, 0, -1 } })) --parse each section. json.stringify to fix a circular reference error that i am too stupid to understand
    local parsedCars = config:mapSection(value, {CAR_FOLDER={"other"}})

    for index2, value2 in pairs(parsedCars["CAR_FOLDER"]) do --add the car folder as keys to the penalty data to make some stuff later simpler
      penaltiesTable[value2] = JSON.parse(parsedSection)
    end
  end

  local carID = ac.getCarID(0)
  if penaltiesTable[carID] == nil then carID = "other" end 

  carPenalties = penaltiesTable[carID]

  if tonumber(carPenalties["ABS_RES_BAL"][1]) == 0 and tonumber(carPenalties["ABS_RES_BAL"][2]) == 0 then
    ac.log("No abs penalty set")
  else
    lockABS = true
    if carPenalties["ABS_RES_BAL"][3] ~= nil then
    if carPenalties["ABS_RES_BAL"][3] ~= -1 then
      ac.setABS(carPenalties["ABS_RES_BAL"][3])
    end
    end
  end

  if tonumber(carPenalties["TC_RES_BAL"][1]) == 0 and tonumber(carPenalties["TC_RES_BAL"][2]) == 0 then
    ac.log("No TC penalty set")
  else
    lockTC = true
    if carPenalties["TC_RES_BAL"][3] ~= nil then
    if carPenalties["TC_RES_BAL"][3] ~= -1 then
      ac.setTC(carPenalties["TC_RES_BAL"][3])
    end
    end
  end

  --ac.log(penaltiesTable)
  scriptReady = true
end)

function refreshPenalties()
  chosenTC, chosenABS = car.tractionControlMode, car.absMode

    physics.setCarRestrictor(0, initialRestrictor + ((chosenTC ~= 0 and lockTC) and tonumber(carPenalties["TC_RES_BAL"][1]) or 0) + ((chosenABS ~= 0 and lockABS) and tonumber(carPenalties["ABS_RES_BAL"][1]) or 0))
    physics.setCarBallast(0, initialBallast + ((chosenTC ~= 0 and lockTC) and tonumber(carPenalties["TC_RES_BAL"][2]) or 0) + ((chosenABS ~= 0 and lockABS) and tonumber(carPenalties["ABS_RES_BAL"][2]) or 0)) 
  ac.log("Penalties Refreshed. TC: " .. (lockTC and "true" or "false") .. " ".. chosenTC )
  ac.log("Penalties Refreshed. ABS: " .. (lockABS and "true" or "false") .. " ".. chosenABS )
end

local wasMenu = true

function script.frameBegin(dt)
  --ac.debug("a", car.restrictor .. " " .. car.ballast)
  --ac.debug("tc", car.tractionControlMode)
  --ac.debug("abs", car.absMode)

  if scriptReady then
    if not sim.isInMainMenu and wasMenu  then
      refreshPenalties()
    end
    if sim.isInMainMenu and not wasMenu then
      physics.setCarRestrictor(0, initialRestrictor)
      physics.setCarBallast(0, initialBallast)
    end
    if not sim.isInMainMenu then
      if lockTC then
        ac.setTC((chosenTC>=1) and math.max(car.tractionControlMode, 1) or 0)
      end
      if lockABS then
      ac.setABS((chosenABS>=1) and math.max(car.absMode, 1) or 0)
      end
    end
  end
  wasMenu = sim.isInMainMenu
end

--[[function absLockMessage()
    if lockABS then
        --ac.setMessage(nil, nil, nil, 1)
        --ac.setMessage("ABS", "ABS LOCKED TO " .. chosenABS, nil, 5)
    end
end

function tcLockMessage()
    if lockTC then
        --ac.setMessage(nil, nil, nil, 1)
        --ac.setMessage("TC", "TC LOCKED TO " .. chosenTC, nil, 5)
    end
end

absUp:onPressed(function () absLockMessage()  end)
absDn:onPressed(function () absLockMessage() end)
tcUp:onPressed(function () tcLockMessage() end)
tcDn:onPressed(function () tcLockMessage() end)]]
