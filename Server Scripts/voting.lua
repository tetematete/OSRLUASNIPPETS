ac.debug("!version", "voting v0.1")

local car = ac.getCar(0)
local sim = ac.getSim()


local qr = require('shared/utils/qr')
local URL = ''
local autofill = {name=0, guid=0}
local steamID = ac.getUserSteamID()
local driverName = ac.getDriverName(0)
local requiredLaps = 2
local ready =false
local qrCode 
local link = ''

local carIDs = {}
for i, c in ac.iterateCars.serverSlots() do
    carIDs[i] = c:id()
end
carIDs = table.distinct(carIDs)
for index, value in ipairs(carIDs) do
    ac.log(value)
end

ac.onOnlineWelcome(function (message, config)
  local sec = 'VOTING'
  --[=[config = ac.INIConfig.parse([[
  [VOTING]
  AUTOFILL_NAME=1536678926
  AUTOFILL_GUID=1892313525
  REQUIRED_LAPS=2
  PREFIX=S36
  GROUP_0 = Nascar, pg_euronascarford, pg_euronascarfj, pg_euronascarshadow
    ]], ac.INIFormat.Extended)]=]

  URL = ac.configValues({URL=''}).URL
  autofill.name, autofill.guid = config:get(sec, 'AUTOFILL_NAME', 0, 1), config:get(sec, 'AUTOFILL_GUID', 0, 1)
  link = string.format('%s/viewform?usp=pp_url&entry.%d=%s&entry.%d=%d', URL, autofill.name, string.urlEncode(driverName), autofill.guid, steamID)
  qrCode = qr.encode(link)

 requiredLaps = config:get(sec, 'REQUIRED_LAPS', 3, 1)

  ac.storageSetPath('VotingStorage-'..config:get(sec, 'PREFIX', '', 1))
  makeGroups(config)
  ready = true
end)

local groups = {}
---comment
---@param config ac.INIConfig
function makeGroups(config)
    groups = {}
    local availableCars = table.clone(carIDs)
    local sec = 'VOTING'
    for i, key in config:iterateValues(sec, 'GROUP') do
        local name = config:get(sec, key, 'GroupName', 1)
        groups[name] = {}
        local g = groups[name]
        g.cars = {}
        g.laps = ac.storage(name, 0)

        for i = 1, 10, 1 do
            ac.log(config:get(sec, key, ac.INIConfig.OptionalString, i + 1))

            if config:get(sec, key, ac.INIConfig.OptionalString, i + 1) ~= nil then
                table.removeItem(availableCars, config:get(sec, key, 'CarID', i + 1))

                    table.insert(g.cars, config:get(sec, key, 'CarID', i + 1))

            else
                break
            end
        end


    end

    for index, name in ipairs(availableCars) do
        groups[name] = {cars={name}, laps=ac.storage(name, 0)}
    end
    groups.ignore = nil
    --ac.log(availableCars)
    --ac.log(groups)
end

ac.onLapCompleted(0, function (carIndex, lapTime, valid, cuts, lapCount)
    local id = car:id()
    updateLapValue(id)
end)

function updateLapValue(id, down)
    local allComplete = true
    for k, g in pairs(groups) do
        for i, c in ipairs(g.cars) do
            if id == c then
                g.laps:set(g.laps:get() + 1)
            end
            if not checkCompleted(g) then
                allComplete = false
            end
        end
    end
    return allComplete
end

ui.registerOnlineExtra(ui.Icons.HammerAlt, "Voting!", function ()
    return true
end, function ()

    for k, g in pairs(groups) do
        ui.text(k)
        ui.separator()
        for i, c in ipairs(g.cars) do

        if ui.modernMenuItem(string.format('%s %d/%d',c, g.laps:get(), requiredLaps), ui.Icons.CarFront, checkCompleted(g))
        then
            ac.reconnectTo({serverIP = ac.getServerIP(), serverPort = ac.getServerPortUDP(), serverHttpPort = ac.getServerPortHTTP(), carID = c})
        end
        if sim.isAdmin then
            ui.sameLine() g.laps:set(ui.slider('###'..c, g.laps:get(), 0, 10, '%.0f'))
        end
    end


    end
    if updateLapValue('') then
        ui.separator()
        ui.setNextTextBold()
        ui.pushFont(ui.Font.Title)
        ui.text('Cast Vote')
        --ui.image(qrCode,200)
        if ui.button('Open Link In Browser') then
            os.openURL(link)
        end ui.sameLine()
        if ui.button('Copy Link') then
            ac.setClipboardText(link)
        end         

end
    ui.separator()
    if ui.iconButton(ui.Icons.Exit) then
        return true
    end
end, nil, ui.OnlineExtraFlags.None)

function checkCompleted(g)
    if g.laps:get() >= requiredLaps then
        return true
    else
        return false
    end
end
