ac.debug("!version", "assistPenalties v0.8")

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
local absOffset = 0
local tcOffset = 0
if car.absModes == 0 then
  ac.setABS(0)
end
if car.tractionControlModes == 0 then
  ac.setTC(0)
end

ac.onOnlineWelcome(function(message, config)
  for index, value in config:iterate("ASSISTPEN") do
    local parsedSection = JSON.stringify(config:mapSection(value, {ABS_RES_BAL = { 0, 0 }, TC_RES_BAL = { 0, 0 } }))
    local parsedCars = config:mapSection(value, {CAR_FOLDER={"other"}})

    for index2, value2 in pairs(parsedCars["CAR_FOLDER"]) do
      penaltiesTable[value2] = JSON.parse(parsedSection)
    end
  end

  --ac.log(penaltiesTable)
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
  absOffset = 0
  tcOffset = 0
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
