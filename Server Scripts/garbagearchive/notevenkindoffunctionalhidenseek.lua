local sim = ac.getSim()

gameStarted = true
players = {}
Seeker = nil
timeofStart = 0
initialized = false
_ac_SceneReference = nil
gamephase = 0
seekchoosetime = 200
hidetime = 200


local jumpEvent = ac.OnlineEvent({
  key = ac.StructItem.key('itshammertime'),  -- to make sure there would be no collisions with other events, it’s a good idea to use a unique key
  gameStartedm = ac.StructItem.boolean(),  -- check if hide and seek game in progress.
  timeofStartm = ac.StructItem.int32()
}, function (sender, message)
gameStarted = message.gameStartedm
timeofStart = message.timeofStartm
initialized = false
end)



function script.update(dt)



render.debugCross(seekpos, 20, rgbm(1,1,1,100))
time = sim.currentServerTime
seekpos = ac.getCar(Seeker).position
ac.debug('seekerpos', seekpos)
  if gameStarted then
    ac.debug('time',time)
    ac.debug('seeker', ac.getDriverName(Seeker))
    ac.debug('players', players)
    ac.debug('gamephase', gamephase)
    ac.debug('gamephase2', Seeker)
    gameInit()
  end

  if Seeker == 0 then
    ac.setAppsHidden(true)
  end
  if time - timeofStart > seekchoosetime and gamephase == 0 and gameStarted then
    catches = 0


    --seeker chosen! hide phase start
    gamephase = 1
    if Seeker == 0 then
    physics.lockUserControlsFor(seekchoosetime/1000)
    ac.
    end
    
  end

  if time - timeofStart > hidetime + seekchoosetime and gamephase == 1 then
    --seek phase
    gamephase = 2
    ac.onCarCollision(0, function()
      ac.debug('bnk', 1)
  if Seeker == 0 then
    for i, c in ac.iterateCars() do
      if ac.areCarsColliding(0, i) then
        ac.broadcastSharedEvent('catch', ac.getCar(i).sessionID)
      end
    end
  end

    end)
    ac.onSharedEvent('catch', function(catch) 
      ac.debug('catch', catch)
    for i = 0, sim.carsCount do
      local car = ac.getCar(i)
        if car ~= nil then
          ac.debug('please', i)
          if (players[i] ~= nil and players[i][0] == catch) and (players[i][1] == false)  then
            players[i][1] = true
            if players[i][2] == 0 then
              ac.tryToTeleportToPits()
            end
          catches = catches + 1
          timeend = time
          break
          end
        end
      end
    end,
    true)
    
  end
  
  if catches == #players-1 then
      gamephase = 3

      if time - timeend > 10000 then
        gameStarted = 0
      end 
    end
  


end



function gameInit()
  if initialized == false then
    for i = 1, sim.carsCount do
      local car = ac.getCar(i - 1)
        if car.isConnected then
          players[i-1] = {}
          players[i - 1][0] = car.sessionID
          players[i-1][1] = false
          players[i-1][2] = i-1
        end
    end
    Seeker = players[math.round((math.seededRandom(timeofStart)*(#players)), 0)][2]
    physics.lockUserControlsFor(10)
    ac.tryToTeleportToPits()
    gamephase = 0
    initialized = true
    timeend = 0
end
end




function script.drawUI()

if gamephase == 0 then
ui.dwriteDrawText('Picking Seeker...', 20, vec2(100,200))
end

if gamephase == 1 then
  if Seeker == 0 then
    ui.dwriteDrawText('You are the seeker!', 20, vec2(100,200))
  end
  ui.dwriteDrawText('Remaining Time to Hide: ' .. tostring(math.round(((hidetime) - (time - timeofStart - seekchoosetime))/1000),0), 20, vec2(100,300))
end
if gamephase == 3 then
ui.dwriteDrawText('SEEKER WINS! ' .. tostring(math.round(((hidetime) - (time - timeofStart - seekchoosetime))/1000),0), 20, vec2(100,300))
end
end

function hammertimeUI()
  ui.text('balls')
end

function script.draw3D()
ac.debug('render', seekpos)

--render.debugText( ac.getCameraPosition() + ac.getCameraForward() * 0.5, "OlA", rgbm.colors.lime, 3, render.FontAlign.Center)
render.debugCross(seekpos, 1, rgbm(1,1,1,100))
end

local function hammertimeHUD()
    if ui.button('START') then
         jumpEvent({
         gameStartedm = true,
         timeofStartm = time})
    end
    if ui.button('CatchCheck') then
         ac.broadcastSharedEvent('catch', 9)
    end
    if ui.button('STOP') then
         jumpEvent({
         gameStartedm = false,
         timeofStartm = time})
    end    
end

local function hammertimeHUDclosed()

end


ui.registerOnlineExtra(ui.Icons.Crosshair, 'Controls', nil, hammertimeHUD, hammertimeHUDclosed, ui.OnlineExtraFlags.Admin)