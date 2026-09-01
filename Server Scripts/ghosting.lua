ac.debug('!version', 'Ghosting v0.5')
local function log(s)
  ac.log('GHOSTING:' .. s)
end

local amIGhosted = false
local car = ac.getCar(0)

for index, c in ac.iterateCars() do
  physics.disableCarCollisions(index, false, true)
  physics.disableCarCollisions(index, false, false)
end
ac.onOnlineWelcome(function (message, config)
    for index, key in config:iterateValues('GHOSTING', 'GUID') do
      log('Ghosted GUID: '..config:get('GHOSTING', key, ac.INIConfig.OptionalString, 1))
      if ac.getUserSteamID() == config:get('GHOSTING', key, ac.INIConfig.OptionalString, 1) then
        amIGhosted = true
        log('Match! Putting Self on ghost list')
        
      end
      
    end
    cast(evil, {car=car.sessionID, ghost=amIGhosted, admin=false, req = false})
end)

ui.registerOnlineExtra(ui.Icons.Crosshair, 'Ghosting Panel', nil, function ()
  for i, c in ac.iterateCars.serverSlots() do
    ui.pushID(i)
    if c.index == 0 then
      ui.setNextTextBold()
    end
    ui.text(c:driverName() .. ' ID: '.. c.sessionID) ui.sameLine()
    if ui.button('Collisions Off') then
      cast(evil, {car=c.sessionID, ghost=true, admin=true, req = false})
    end ui.sameLine()
    if ui.button('Collisions On') then
      cast(evil, {car=c.sessionID, ghost=false, admin=true, req = false})
    end
    ui.popID()
  end
end, nil, bit.bor(ui.OnlineExtraFlags.Admin, ui.OnlineExtraFlags.Tool), ui.WindowFlags.None)

---@param t table @The table that you would normally pass to the function returned by ac.onlineEvent
function cast(f, t)
    math.randomseed(sim.currentSessionTime)
    if not f(t) then
        setInterval(function ()
            if f(t) then
                return clearInterval
            end
        end, math.random())
    end
end

evil = ac.OnlineEvent({
    ac.StructItem.key('Ghosting'),
    req = ac.StructItem.boolean(),
    car = ac.StructItem.int16(),
    ghost = ac.StructItem.boolean(),
    admin = ac.StructItem.boolean()
}, function (sender, message)
    if message.req then
      log('Update Requested By ' .. sender:driverName())
        cast(evil, {car=car.sessionID, ghost=amIGhosted, admin=false, req = false})
    else
      if sender ~= 0 or message.admin then
        log('Collisions: ' .. (message.ghost and 'false' or 'true') .. ' ID: ' .. message.car )
        physics.disableCarCollisions(ac.getCar.serverSlot(message.car).index, message.ghost, true)
        
      end
      if ac.getCar.serverSlot(message.car).index == 0 then
        amIGhosted = message.ghost
      else
        ac.highlightCar(ac.getCar.serverSlot(message.car).index, message.ghost and rgb(1,0,0) or nil )
      end
    end
end, ac.SharedNamespace.ServerScript)

setTimeout(function ()
  cast(evil, {req=true})
end, 3)
