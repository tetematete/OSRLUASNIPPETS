ac.storageSetPath("drsSettings", "OSR")
--=================================================================================================================
--                                  Online Window Maker Class
--=================================================================================================================
--#region
local onlineWindow = class('onlineWindow')

---Makes an interactable window for online scripts.
---@param id string @Window ID, has to be unique within your script.
---@param pos vec2 @Window Initial Position
---@param wsize vec2 @Window size.
---@param noPadding boolean @Disables window padding. Default value: `false`.
---@param transparent boolean @Whether window should be transparent
---@overload fun(id: string, pos: vec2, wsize: vec2, noPadding: boolean, transparent: boolean)
function onlineWindow.initialize(self, id, pos, wsize, noPadding, transparent)
  self.id = const(id)
  self.winSettings = ac.storage({
    windowPos = pos,
    windowSize = wsize
  }, self.id)
  self.transparent = const(transparent)
  self.noPadding = const(noPadding)

  self.size = const(wsize)
  self.dragging = false
  self.startPos = vec2()
  self.move = function()
    if ui.windowHovered() then
      if ui.isMouseDragging(ui.MouseButton.Left) and not self.dragging --[[and not betterFlagSettings.flagWindowPinned ]] then
        self.startPos = ui.windowPos()
        self.dragging = true
      end
    end
    if self.dragging and ui.mouseDragDelta(ui.MouseButton.Left) ~= vec2(0, 0) then
      self.winSettings.windowPos = self.startPos + ui.mouseDragDelta()
    else
      self.dragging = false
    end
  end
  self.window = function(s, content)
    if s.transparent then
      ui.transparentWindow(s.id, s.winSettings.windowPos, self.size, self.noPadding, true, function()
        self.move()
        content()
      end)
    else
      ui.toolWindow(s.id, s.winSettings.windowPos, self.size, self.noPadding, true, function()
        self.move()
        content()
      end)
    end
  end
end

onlineWindow.make    = class.emmy(onlineWindow, onlineWindow.initialize)
--#endRegion

local car = ac.getCar(0)
local sim = ac.getSim()
local drsZones = ac.INIConfig.trackData('drs_zones.ini')
local crossingTimes = {}

local activateOnLap = 1
local gapAhead = 1
local maxActivations = 1
local usages = 0
local usagesPerLap = 0
local DRSEnabled = false
local drsData = {}

local debugMode = false

local usedThisLap = false
ac.debug("!version", "realDRS v0.7")
for index, section in drsZones:iterate("ZONE") do
    drsData[index] = drsZones:mapSection(section, { DETECTION = 0, START = 0, END = 0, TIMEOUT = -1, ALLOWED = false })
    ac.log(drsData[index])
    ac.log("DRS: " .. section)
    ac.onTrackPointCrossed(-1, drsData[index].DETECTION, function(carIndex, timeMs)
      --ac.log(carIndex, index)
        if carIndex ~= 0  then
            drsData[index].ALLOWED = true
            clearTimeout(drsData[index].TIMEOUT)
            drsData[index].TIMEOUT = setTimeout(function()
                drsData[index].ALLOWED = false
            end, gapAhead)
        else
            if sim.raceSessionType == ac.SessionType.Race then
                if drsData[index].ALLOWED and sim.leaderLapCount >= activateOnLap and (maxActivations-usages>=0) then
                    physics.allowCarDRS(0, false)

                    ac.log("DRS: Gap ahead under threshold, enabling DRS.")
                else
                    physics.allowCarDRS(0, true)

                    ac.log("DRS: Gap ahead above threshold or not yet enabled, disabling DRS.")
                end
            end
        end

    if not DRSEnabled then

        if sim.leaderLapCount >= activateOnLap and sim.raceSessionType == ac.SessionType.Race and car.lapCount >= 1 then
          ac.log("DRS: NOW ENABLED")
          DRSEnabled = true
        end

    end
    end)

end
--physics.setCarAutopilot(true)

if drsData == {} then
    ac.log("No or Malformed drs_zones.ini detected!")
end

ac.onOnlineWelcome(function(message, config)
  if debugMode then
    config = ac.INIConfig.parse([[
  [REALDRS]
  ACTIVE_ON_LAP=1
  GAP_AHEAD= 5
  USAGES = 2, 2
  ]], ac.INIFormat.Extended)
  ac.debug("config:", config:serialize())
  end


    local sec = "REALDRS"
    activateOnLap = config:get(sec, "ACTIVE_ON_LAP", 1)
    gapAhead = config:get(sec, "GAP_AHEAD", 1)
    maxActivations, usagesPerLap = config:get(sec, "USAGES", 1, 1),config:get(sec, "USAGES", 0, 2)

    
end)


ac.onTrackPointCrossed(-1, drsData[1].START, function(carIndex, timeMs)
  if carIndex == 0 then
    usedThisLap = false
  end
end)

local started = false
ac.onSessionStart(function(sessionIndex, restarted)
  checkStart()
end)

function checkStart()
    setTimeout(function()
        ac.log("DRS: SESSION RESTARTED")
        usages = 0
        usedThisLap = false
        if sim.raceSessionType == ac.SessionType.Race then
            ac.log("DRS: SESSION START | DRS DISABLED")
            DRSEnabled = false
            physics.allowCarDRS(0, true)
        else
            ac.log("DRS: SESSION START | DRS ENABLED")
            DRSEnabled = true
            physics.allowCarDRS(0, false)

        end
    end, 1)
    started = false
    DRSEnabled = false

end


local wasDRS = false
function script.update(dt)
  if debugMode then
    ac.debug("drsData", drsData)
    ac.debug("d", usedThisLap)
    ac.debug("usages", usages)
    ac.debug("max", maxActivations)
    for index, value in ipairs(drsData) do
      ac.debug("zone_%d" % index, value.ALLOWED)
    end
  end

  if (car.drsActive and not wasDRS) and sim.isSessionStarted then
    if not usedThisLap then
      usedThisLap = true
      usages = usages + usagesPerLap
    end
  end
  wasDRS = car.drsActive
end

checkStart()




local usagesWindow = onlineWindow.make("DRSWindow", vec2(100,50), vec2(100,50), true, true) 
function script.drawUI(dt)
  if usagesPerLap > 0 then
    usagesWindow:window(function()
      ui.drawRectFilled(0, 100, rgbm.colors.gray)
      ui.setNextTextBold()
      ui.pushFont(ui.Font.Title)
      ui.beginScale()
      ui.textAligned(math.max(maxActivations-usages,0), 0.5, usagesWindow.winSettings.windowSize)
      ui.endScale(2)
      ui.popFont()
    end)
  end
end


if debugMode then
ac.onChatMessage(function (message, senderCarIndex, senderSessionID)
  if senderCarIndex == 0 then
  physics.setCarAutopilot(not car.isAIControlled)
  end
end)

physics.setAIAggression(0, 0.5)
physics.setAILevel(0, 0.5)
end
