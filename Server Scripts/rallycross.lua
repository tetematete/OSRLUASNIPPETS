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

local cubic = require('shared/math/cubic')
ac.debug("!version", "jokerlap v0.1")

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
local spl = {}
local noVisuals = false
local arrowColor = rgbm(0.4, 0.8, 1, 0)
local active = false
local rotation = 90


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

local testa = ac.INIConfig.parse([[
[ATTACKMODE]
POINT_0=112.65518188477,0.78796672821045,-842.85900878906
OFFSET=0
POINT_3=170.95404052734,1.1461935043335,-854.06195068359
POINT_2=160.42752075195,1.0953969955444,-850.65606689453
POINT_1=139.10534667969,0.95912742614746,-846.13781738281
HITBOX=1.3159999847412
SIZE = 1
DIST = 1
]], ac.INIFormat.Extended)


--==============================================================================
--      Load server spline settings
--==============================================================================
ac.onOnlineWelcome(function(message, config)
    --config = testa
     local sec = "RALLYCROSS"
    for index, key in config:iterateValues(sec, "POINT", true) do
        local pos = config:get(sec, key, vec3())
        table.insert(spl, { pos = pos, helper = render.PositioningHelper({ skipAxis = { 'y' } }), collected=false })
    end
    hitbox = config:get(sec, "HITBOX", 2)
    offset = config:get(sec, "OFFSET", 0)
    size = config:get(sec, "SIZE", 1)
    dist = config:get(sec, "DIST", 1)
    age = config:get(sec, "AGE", 0.5)
    rotation = config:get(sec, "ROTATION", 90)
    arrowColor = config:get(sec, "COLOR", rgbm(0.4, 0.8, 1, 1))
    --noVisuals = config:get("ATTACKMODE", "NO_VISUALS", 0) == 1
    --ac.log(config:serialize())
    if #spl > 3 then
        makePaint()
    end


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
    hitbox, hittrue = ui.slider("hitbox", hitbox, 0.5, 3)
    size, sizetrue = ui.slider("size", size, 0.5, 3)
    dist, disttrue = ui.slider("dist", dist, 0.01, 3)
    age, agetrue = ui.slider("age", age, 0, 1)
    rotation, rotationtrue = ui.slider("rotation", rotation, 0, 360)
    if sizetrue or disttrue or agetrue or rotationtrue then
        makePaint()
    end
    if ui.hotkeyShift() and ui.mouseClicked(ui.MouseButton.Left) then
        local ray = render.createMouseRay()
        local pos = vec3()
        if physics.raycastTrack(ray.pos, ray.dir, math.huge, pos) ~= -1 then
            ac.log(pos)
            table.insert(spl, { pos = pos, helper = render.PositioningHelper({ skipAxis = {'y'} }), collected=false })
            if #spl > 3 then
                makePaint()
            end
        end
    end
    
    if ui.button("Export Current") then
        local sec = "RALLYCROSS"
        local config = ac.INIConfig(ac.INIFormat.Extended, {[sec]={}})
        for index, value in ipairs(spl) do
            config:set(sec, "POINT_" .. index-1, value.pos)
        end
        config:set(sec, "HITBOX", hitbox)
        --config:set("ATTACKMODE", "NO_VISUALS", noVisuals)
        --config:set("ATTACKMODE", "OFFSET", offset)
        config:set(sec,"COLOR", arrowColor)
        config:set(sec, "SIZE", size)
        config:set(sec, "DIST", dist)
        config:set(sec, "AGE", age)
        config:set(sec, "ROTATION", rotation)
        ac.log(config:serialize())
        ac.setClipboardText(config:serialize())
        tempConfig = config:serialize()
    end

    for index, value in ipairs(spl) do
        ui.text(index .. ": " .. tostring(value.pos))
        if ui.itemHovered(ui.HoveredFlags.None) then
            ui.itemUnderline()
        end

        if ui.itemClicked(ui.MouseButton.Left) then
            table.remove(spl, index)
            makePaint()
        end
    end
    

    if #spl > 3 then
    else
        ui.text("4 Points Required, shift + click to add a point")
    end
ui.nextColumn()
if ui.colorPicker("Arrow Color", arrowColor, ui.ColorPickerFlags.AlphaBar) then makePaint() end

    ui.nextColumn()
    ui.columns(1)
    ui.separator()

    if tempConfig ~= nil then 
        ui.inputText("##CONFIG", tempConfig, ui.InputTextFlags.None, ui.availableSpace())
    end

end, function (okClicked)
    showDebug = false
    
end, ui.OnlineExtraFlags.Tool)
--==============================================================================
-- 3D Update function, for showing hitbox and positioning helpers
--==============================================================================
local helperGrabbed = false
function script.draw3D()
    if showDebug then
        for index, val in ipairs(spl) do
            local track = ac.worldCoordinateToTrack(val.pos)
            track.x = track.x + offset
            render.debugSphere(ac.trackCoordinateToWorld(track), hitbox, val.collected and rgbm.colors.green or nil)
            
        end
        for index, val in ipairs(spl) do
            val.helper:render(val.pos)
            render.debugText(val.pos, index)
        end
        
        render.debugText(car.position, "Car Hitbox")
        if not render.isPositioningHelperBusy() and helperGrabbed and #spl > 3 then
            makePaint()
        end

        helperGrabbed = render.isPositioningHelperBusy()
    end
end

--==============================================================================
-- Script Constant update Logic
--==============================================================================
local collectedPoints = 0
local jokerStatus = 0
function script.update(dt)
--ac.debug("a", car.p2pStatus)
    if active and not (#spl == 0) then
        if collectedPoints == #spl then
            allCollected()
        else
            if collectedPoints < #spl and spl[collectedPoints + 1].pos:distance(car.position) < hitbox then
                if collectedPoints == 0 and jokerStatus ~= 2 then
                    bcast({status=1})
                    jokerStatus = 1
                end
                spl[collectedPoints + 1].collected = true
                collectedPoints = collectedPoints + 1
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
    ui.dwriteTextAligned("JOKER", 60, ui.Alignment.Center, ui.Alignment.Center, vec2(260, 100))
    ui.endGradientShade(vec2(-100 + progress, 50), vec2(0 + progress, 50), col1, col2)
end
local jokerInd = ui.ExtraCanvas(vec2(400, 100)):setName("a"):update(drawJokerInd)



ac.onTrackPointCrossed(0, 0.995, function (carIndex, timeMs)
        if car.lapCount+1 == ac.getSession(sim.currentSessionIndex).laps  and jokerStatus ~= 3 and sim.raceSessionType == ac.SessionType.Race then
        physics.setCarPenalty(ac.PenaltyType.BlackFlag)
        ac.setMessage("JOKER LAP", "YOU HAVE BEEN DISQUALIFIED FOR NOT TAKING THE JOKER LAP", 'illegal', 10)
    end
end)

local jokerWindow = onlineWindow.make("a", vec2(500,500), vec2(270, 100), true, true)


function script.drawUI()
    --ac.log(jokerStatus)
    if jokerStatus == 0 then
        progress = 0
        progress2 = 0
    elseif jokerStatus == 1 then
        progress = jsmooth(400 * (collectedPoints / #spl))
        progress2 = 400 * (collectedPoints / #spl)
    else
        progress = jsmooth(400)
        progress2 = 400
    end

    if progress ~= progress2 then
        jokerInd:clear():update(drawJokerInd)
    end

    jokerWindow:window(function ()
        ui.image(jokerInd, vec2(400, 100))
    end)


end

--==============================================================================
-- Reset, Complete Lap callbacks
--==============================================================================

function reset() --reset function, 

    setTimeout(function ()
    resetCollected()
    end, 1, "reset")

end


ac.onSessionStart(function (sessionIndex, restarted)
reset()
end)
reset()


ac.onLapCompleted(0, function (carIndex, lapTime, valid, cuts, lapCount)
    resetCollected()
end)

function resetCollected()
    collectedPoints = 0
    if jokerStatus ~= 2 then
        jokerStatus = 0
    end
    for index, point in ipairs(spl) do
        point.collected = false
    end
end

function allCollected()   
    bcast({status=2})
    jokerStatus = 2
    resetCollected()

end

bcast = ac.OnlineEvent({
    ac.StructItem.key("BroadcastCarStatus"),
    status = ac.StructItem.int8()
}, function (sender, message)

end)


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

