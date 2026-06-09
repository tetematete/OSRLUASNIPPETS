ac.debug("!version", "reporting v0.7")
local sim = ac.getSim()
local timestamp = 0
local sessionStartTime = 0
local session = ac.getSession(sim.currentSessionIndex)
local fadeTimer = 0
local cooldown = 5
local timeout = 0
local reportStore = ac.storage {
  pos = vec2(300, 300),
  hidden = false
}
local flagDragging = false
local flagStartPos = vec2(0, 0)
local reportBind = ac.ControlButton("reportBinding")
local reportLimit = 2
local reports

if not sim.isReplayActive then
  ac.writeReplayBlob("TimestampSessionStart", os.time() - sim.currentSessionTime / 1000)
else
  sessionStartTime = ac.readReplayBlob("TimestampSessionStart")
end

ac.onOnlineWelcome(function (message, config)
  local SECTION = "REPORTING"
  reportLimit = config:get(SECTION, "LIMIT_PER_LAP", 2, 1)
  cooldown = config:get(SECTION, "COOLDOWN", 5, 1)

  reports = reportLimit
end)


function script.drawUI()
  local dt = ac.getDeltaT()

  ui.transparentWindow("ReportWindow", reportStore.pos, vec2(200, 125), true, true, function()
    if not reportStore.hidden then
    if reportBind:control(vec2(150, 50), ui.ControlButtonControlFlags.SingleEntry, "Click to bind \nreport button") then
      reportBind:boundTo()
    end
  end
    ui.sameLine(175)
    if ui.iconButton(reportStore.hidden and ui.Icons.UpAlt or ui.Icons.DownAlt, vec2(25,25)) then
      reportStore.hidden = not reportStore.hidden
    end
    ui.pushFont(ui.Font.Title)

    if fadeTimer > 0 then
      fadeTimer = fadeTimer - dt
    end

    ui.pushStyleColor(ui.StyleColor.Text, rgbm(255, 165, 0, math.clamp(fadeTimer / 2, 0, 1)))

    if reports >= 0 then
      ui.text("Report Sent!")
    else
      ui.text("No Reports Remaining\nFor This Lap")
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
  ac.debug("as", reports)
end
--mmmmm callbacks
reportBind:onPressed(function() 
  if reports > 0 and fadeTimer <= 0 then
    report({balls=true})
  end
  if fadeTimer <= 0 then
  reports = reports - 1
  fadeTimer = cooldown
  end
end)

ac.onLapCompleted(0, function(carIndex, lapTime, valid, cuts, lapCount)
  reports = reportLimit
  fadeTimer = 0
end)

ac.onSessionStart(function(sessionIndex, restarted)
  reports = reportLimit
end)

report = ac.OnlineEvent({ ac.StructItem.key("AwesomeReportKey"), balls=ac.StructItem.boolean()}, function(sender, message) end)
