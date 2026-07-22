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
        self.move = function ()
            if ui.windowHovered() then
                if ui.isMouseDragging(ui.MouseButton.Left) and not self.dragging --[[and not betterFlagSettings.flagWindowPinned ]]then
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
                ui.transparentWindow(s.id, s.winSettings.windowPos, self.size, self.noPadding, true, function ()
                    self.move()
                    content()
                end)
            else
                ui.toolWindow(s.id, s.winSettings.windowPos, self.size,self.noPadding, true, function ()
                    self.move()
                    content() 
                end)
            end
        end
        
    end
    onlineWindow.make = class.emmy(onlineWindow, onlineWindow.initialize)
    --#endRegion

    --=================================================================================================================
    --                                  Spline Maker Class
    --=================================================================================================================
    --#reigon
local cubic = require('shared/math/cubic')
local splineContainer = class('splineContainer')
local splinePoint = class('splinePoint')
function splineContainer:initialize(size,dist,age,rotation,color)
    self.size = size or 1
    self.dist = dist or 1
    self.age = age or 0.5
    self.rotation = rotation or 90
    self.color = color or rgbm.colors.white
    self.pts = {}
    self.paint = ac.TrackPaint()
    self.collectedPoints = 0

    self.createPoint = function(pos,size)
        self.pts[#self.pts+1] = splinePoint(pos,size)
    end
    self.deletePoint = function (index)
        table.remove(self.pts, index)
    end
    self.reset = function ()
        self.collectedPoints = 0
        for index, pt in ipairs(self.pts) do
            pt.collected = false
        end
    end
end

function splinePoint:initialize(pos, size)
    self.pos = pos
    self.size = size or 5
    self.helper = render.PositioningHelper({ skipAxis = {'y'} })
    self.collected=false
end


    --#endRegion

ac.debug("!version", "jokerlap v0.3")

--If you intend to modify this script, leave these in. 
ac.debug("URL", "https://github.com/tetematete/OSRLUASNIPPETS/tree/main")
ac.debug("Credit", "original script by tetematete, co-owner of OSR. \nTo race with us, support us, or find more scripts like this one,\n follow the link below.")
--I mean it :)

local car = ac.getCar(0)
local sim = ac.getSim()

local paint = ac.TrackPaint()
local showDebug  
local chevron = ui.ExtraCanvas(500, 1):setName("chev"):update(function(dt)

    ui.pathLineTo(vec2(250, 250))
    ui.pathLineTo(vec2(500, 400))
    ui.pathLineTo(vec2(500, 250))
    ui.pathLineTo(vec2(250, 100))
    ui.pathLineTo(vec2(0, 250))
    ui.pathLineTo(vec2(0, 400))
    ui.pathFillConvex(rgbm.colors.white)
    --ui.pathStroke(rgbm.colors.red,false, 5)
end)
local encoded = chevron:encode()
local hitbox = 2
local offset = 0
local size = 1
local dist = 1
local age = 0.5
--local spl = {}
local noVisuals = false
local arrowColor = rgbm(0.4, 0.8, 1, 0)
local active = false
local rotation = 90  -ac.getRealTrackHeadingAngle()
local readyUp = false
local ready = false
local statusList = {}
local doneCount = 0
local function makePaint()
    
        paint:reset()
    if not noVisuals then
        paint:age(age)
        local tab = {}
        for index, value in ipairs(spl) do
            table.insert(tab, spl[index].pos)
        end
        --ac.debug("points", tab)
        local pts = cubic.vec(tab)

        for i = 0, 1, (3 * dist) / pts.length() do
            local degree = ac.getCompassAngle(pts.get(i) - pts.get(i + 0.001))
            --ac.log(degree)

            --paint:arrow(pts.get(i), vec2(1,1), degree+90)
            paint:image(ui.decodeImage(encoded), pts.get(i), 5 * size, degree + rotation, arrowColor)
        end
    end
end



--==============================================================================
--      Load server spline settings
--==============================================================================
local jSpl = splineContainer()
ac.onOnlineWelcome(function(message, config)
    --config = testa
    local sec = "RX_CONFIG"
    readyUp = config:get(sec, "READY_UP", false)


     local sec = "RALLYCROSS"
    for index, key in config:iterateValues(sec, "POINT", true) do
        local pos = config:get(sec, key, vec4())
        jSpl.createPoint(vec3(pos.x, pos.y, pos.z), pos.w)
    end
    hitbox = config:get(sec, "HITBOX", 2)
    offset = config:get(sec, "OFFSET", 0)
    size = config:get(sec, "SIZE", 1)
    dist = config:get(sec, "DIST", 1)
    age = config:get(sec, "AGE", 0.5)
    rotation = config:get(sec, "ROTATION", 90 - ac.getRealTrackHeadingAngle())
    arrowColor = config:get(sec, "COLOR", rgbm(0.4, 0.8, 1, 0))

    active = true
end)


--==============================================================================
--          Spline Creation and Export Tool
--==============================================================================


ui.registerOnlineExtra(ui.Icons.Pitlane, "RALLYCROSS", nil, function()
    local offtrue, hittrue, sizetrue, disttrue, agetrue,rotationtrue = false, false, false, false, false, false
    showDebug = true
    active = true
    --offset, offtrue = ui.slider("offset", offset, -1, 1)
    ui.columns(2, true, "Columntest")
    
  --if ui.checkbox("No Visuals", noVisuals) then noVisuals = not noVisuals makePaint() end
    --hitbox, hittrue = ui.slider("hitbox", hitbox, 1, 20, '%.1f')
    --size, sizetrue = ui.slider("size", size, 0.5, 3, '%.1f')
    --dist, disttrue = ui.slider("dist", dist, 0.01, 3, '%.1f')
    --age, agetrue = ui.slider("age", age, 0, 1, '%.1f')
    --rotation, rotationtrue = ui.slider("rotation", rotation, 0, 360, '%.1f')


    if ui.hotkeyShift() and ui.mouseClicked(ui.MouseButton.Left) then
        local ray = render.createMouseRay()
        local pos = vec3()
        if physics.raycastTrack(ray.pos, ray.dir, math.huge, pos) ~= -1 then
            jSpl.createPoint(pos, 5)
            ui.storeNumber(0, #jSpl.pts)
        end
    end
    


    for index, value in ipairs(jSpl.pts) do
        if ui.menuItem(index, ui.loadStoredNumber(0,1)==index) then
            ui.storeNumber(0, index)
        end
    end
    
    if ui.button("Export Current") then
        local sec = "RALLYCROSS"
        local config = ac.INIConfig(ac.INIFormat.Extended, {[sec]={}})
        for index, value in ipairs(jSpl.pts) do
            config:set(sec, "POINT_" .. index-1, vec4(value.pos.x,value.pos.y,value.pos.z,value.size))
        end

        ac.log(config:serialize())
        ac.setClipboardText(config:serialize())
        tempConfig = config:serialize()
    end

        ui.text("shift + click \nto add point")

ui.nextColumn()
--if ui.colorPicker("Arrow Color", arrowColor, ui.ColorPickerFlags.AlphaBar) then makePaint() end
if #jSpl.pts > 0 then 
    jSpl.pts[ui.loadStoredNumber(0, 1)].size = ui.slider("hitbox", jSpl.pts[ui.loadStoredNumber(0, 1)].size, 1, 30, '%.1f')
end

if ui.button("Delete Point") then
    jSpl.deletePoint(ui.loadStoredNumber(0, 0))
    ui.storeNumber(0, #jSpl.pts)
end
    ui.nextColumn()
    ui.columns(1)
    ui.separator()

    if tempConfig ~= nil then 
        ui.inputText("##CONFIG", tempConfig, ui.InputTextFlags.None, ui.availableSpace())
    end
end, function (okClicked)
    showDebug = false
    
end, bit.bor(ui.OnlineExtraFlags.Admin, ui.OnlineExtraFlags.Tool))
--==============================================================================
-- 3D Update function, for showing hitbox and positioning helpers
--==============================================================================
local helperGrabbed = false
function script.draw3D()
    if showDebug then
        for index, val in ipairs(jSpl.pts) do
            local track = ac.worldCoordinateToTrack(val.pos)
            track.x = track.x + offset
            render.debugSphere(ac.trackCoordinateToWorld(track), val.size, val.collected and rgbm.colors.green or nil)
            
        end
        for index, val in ipairs(jSpl.pts) do
            val.helper:render(val.pos)
            render.debugText(val.pos, index)
        end
        
        render.debugText(car.position, "Car Hitbox")
        --[[if not render.isPositioningHelperBusy() and helperGrabbed and #jSpl.pts > 3 then
            makePaint()
        end]]

        helperGrabbed = render.isPositioningHelperBusy()
    end
end

--==============================================================================
-- Script Constant update Logic
--==============================================================================
--local collectedPoints = 0
local jokerStatus = 0
function script.update(dt)
   --ac.debug("A", jSpl.pts)
--ac.debug("a", car.p2pStatus)
    if active and not (#jSpl.pts == 0) then
        if jSpl.collectedPoints == #jSpl.pts then
            allCollected()
        else
            if jSpl.collectedPoints < #jSpl.pts and jSpl.pts[jSpl.collectedPoints + 1].pos:distance(car.position) < jSpl.pts[jSpl.collectedPoints + 1].size then
                if jSpl.collectedPoints == 0 and jokerStatus ~= 2 then
                    bcast({status=1})
                end
                jSpl.pts[jSpl.collectedPoints + 1].collected = true
                jSpl.collectedPoints = jSpl.collectedPoints + 1
            end
        end

    end


end
--==============================================================================
-- Script UI Drawing functions
--==============================================================================

local jsmooth = ui.SmoothInterpolation(0, 2)
local col1, col2 = rgbm(0.05, 0.05, 0.05, 1), rgbm(0.9, 0.9, 0.9, 1)


local progress = 0
local progress2 = 0
local drawJokerInd = function(dt)
    ui.beginGradientShade()
    ui.drawQuadFilled(vec2(10, 0) * 2, vec2(125 + 10, 0) * 2, vec2(125, 50) * 2, vec2(0, 50) * 2, col1)

    ui.endGradientShade(vec2(-100 + progress, 50), vec2(0 + progress, 50), col2, col1)
    ui.beginGradientShade()
    ui.pushDWriteFont('Segoe UI;Weight=Semibold')

    local txt = "JOKER"
    local size = 60
    if readyUp then
        if sim.raceSessionType == ac.SessionType.Race then
                txt = "JOKER"
                size = 60
        else
            if jokerStatus == 0 then
                txt = "RIGHT CLICK\nTO READY"
                size = 30
            elseif jokerStatus == 2 then
                if sim.isAdmin then
                txt = "READY\nSTATUS:\n" .. doneCount .."/".. sim.connectedCars .. "                              ‎"
                size = 20
                else
                txt = "READY"
                size = 60
                end
            end
        end
    end

    ui.dwriteTextAligned(txt, size, ui.Alignment.Center, ui.Alignment.Center, vec2(260, 100))
    ui.endGradientShade(vec2(-100 + progress, 50), vec2(0 + progress, 50), col1, col2)
end
local jokerInd = ui.ExtraCanvas(vec2(400, 100)):setName("a"):update(drawJokerInd)

ac.onTrackPointCrossed(0, 0.995, function (carIndex, timeMs)
        if car.lapCount+1 == ac.getSession(sim.currentSessionIndex).laps  and jokerStatus ~= 2 and sim.raceSessionType == ac.SessionType.Race then
        physics.setCarPenalty(ac.PenaltyType.BlackFlag)
        ac.setMessage("JOKER LAP", "YOU HAVE BEEN DISQUALIFIED FOR NOT TAKING THE JOKER LAP", 'illegal', 10)
    end
end)

local jokerWindow = onlineWindow.make("a", vec2(500,500), vec2(270, 100), true, true)


function script.drawUI()
    --ac.log(jokerStatus)
    if jokerStatus == 0 then
        progress = jsmooth(0)
        progress2 = 0
    elseif jokerStatus == 1 then
        progress = jsmooth(400 * (jSpl.collectedPoints / #jSpl.pts))
        progress2 = 400 * (jSpl.collectedPoints / #jSpl.pts)
    else
        progress = jsmooth(400)
        progress2 = 400
    end

    if progress ~= progress2 or sim.isAdmin then
        jokerInd:clear():update(drawJokerInd)
    end

    jokerWindow:window(function ()
        ui.image(jokerInd, vec2(400, 100))
        if readyUp then
            if ui.itemClicked(ui.MouseButton.Right) and sim.raceSessionType == ac.SessionType.Practice then
                if jokerStatus == 2 then
                        bcast({status=0})
                else
                    bcast({status=2})
                end
            end

            if sim.isAdmin then
                if ui.rectHovered(vec2(75, 0), vec2(175, 60)) then
                    ui.tooltip(function()
                        for index, c in ac.iterateCars.serverSlots() do
                            if c.isConnected then
                                ui.text(c:driverName() .. ": " .. ((statusList[index] == 2) and "Ready" or "Not Ready"))
                            end
                        end
                    end)
                end
                if jokerStatus == 2 then
                                    ui.setCursor(vec2(75,65))
                if ui.modernButton("Next Session", vec2(150,25),ui.ButtonFlags.None, ui.Icons.Skip) then
                    ac.sendChatMessage("/ksns")
                end
                end
            end
        end
    end)


end

--==============================================================================
-- Comms
--==============================================================================
for index, value in ac.iterateCars.serverSlots() do
    statusList[index] = 0
end

bcast = ac.OnlineEvent({
    ac.StructItem.key("BroadcastCarStatus"),
    req = ac.StructItem.boolean(),
    status = ac.StructItem.int8()
}, function (sender, message)
    if message.req then
        bcast({status=jokerStatus})
    else
        if sender.index == 0 then
            jokerStatus = message.status
        end
        statusList[sender.sessionID + 1] = message.status
        doneCount = 0
        for index, value in ipairs(statusList) do
            if value == 2 and ac.getCar.serverSlot(index - 1).isConnected then
                doneCount = doneCount + 1
            end
        end
    end
end)

---@param t table @The table that you would normally pass to the function returned by ac.onlineEvent
function castStatus(t)
    math.randomseed(sim.currentSessionTime)
    if not bcast(t) then
        setInterval(function ()
            if bcast(t) then
                return clearInterval
            end
        end, math.random())
    end
end

ac.onClientDisconnected(function (connectedCarIndex, connectedSessionID)
    if statusList[connectedSessionID+1] == 2 then
        doneCount = doneCount - 1
    end
    statusList[connectedSessionID+1] = 0

end)

castStatus({req=true})
--==============================================================================
-- Reset, Complete Lap callbacks
--==============================================================================



function reset() --reset function, 
    setTimeout(function ()
    resetCollected()
    end, 1, "reset")

    bcast({status=0})
end


ac.onSessionStart(function (sessionIndex, restarted)
reset()
end)
reset()


ac.onLapCompleted(0, function (carIndex, lapTime, valid, cuts, lapCount)
    resetCollected()
end)

function resetCollected()
    jSpl.reset()
    if jokerStatus ~= 2 then
            bcast({status=0})
    end
end

function allCollected()   
    bcast({status=2})
    resetCollected()
end




