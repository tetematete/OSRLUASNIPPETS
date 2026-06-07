ac.debug("!version", "reporting v0.5")
local sim = ac.getSim()
local timestamp = 0
local sessionStartTime = 0
local session = ac.getSession(sim.currentSessionIndex)
local fadeTimer = 0
local timeout = 0
local reportStore = ac.storage {
  pos = vec2(300, 300),
}
local flagDragging = false
local flagStartPos = vec2(0, 0)
local reportBind = ac.ControlButton("reportBinding")
local reportLimit = 2

if not sim.isReplayActive then
  ac.writeReplayBlob("TimestampSessionStart", os.time() - sim.currentSessionTime / 1000)
else
  sessionStartTime = ac.readReplayBlob("TimestampSessionStart")
end

function script.drawUI()
  local dt = ac.getDeltaT()

  ui.transparentWindow("ReportWindow", reportStore.pos, vec2(200, 100), false, true, function()
    if reportBind:control(vec2(150, 50), ui.ControlButtonControlFlags.SingleEntry, "Click to bind \nreport button") then
      reportBind:boundTo()
    end
    ui.pushFont(ui.Font.Title)

    if fadeTimer > 0 then
      fadeTimer = fadeTimer - dt
    end

    ui.pushStyleColor(ui.StyleColor.Text, rgbm(255, 165, 0, math.clamp(fadeTimer / 2, 0, 1)))

    if reportLimit >= 0 then
      ui.text("Report Sent!")
    else
      ui.text("No Reports Remaining For This Lap")
    end

    if ui.windowHovered(ui.HoveredFlags.RectOnly) then
      ui.drawRectFilled(vec2(0, 0), ui.windowSize(), rgbm(0, 0, 0, 0.1))

      if ui.isMouseDragging(ui.MouseButton.Left) and not flagDragging then
        flagStartPos = ui.windowPos()
        flagDragging = true
      end
    end
    if flagDragging and ui.mouseDragDelta(ui.MouseButton.Left) ~= vec2(0, 0) then
      reportStore.pos = flagStartPos + ui.mouseDragDelta()
    else
      flagDragging = false
    end
  end)
  ac.debug("as", reportLimit)
end
--mmmmm callbacks
reportBind:onPressed(function() 
  if reportLimit > 0 and fadeTimer <= 0 then
    report({balls=true})
  end
  if fadeTimer <= 0 then
  reportLimit = reportLimit - 1
  fadeTimer = 5
  end
end)

ac.onLapCompleted(0, function(carIndex, lapTime, valid, cuts, lapCount)
  reportLimit = 2
end)
ac.onSessionStart(function(sessionIndex, restarted)
  reportLimit = 2
end)

report = ac.OnlineEvent({ ac.StructItem.key("AwesomeReportKey"), balls=ac.StructItem.boolean()}, function(sender, message) end)
