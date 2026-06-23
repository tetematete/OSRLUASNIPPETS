ac.debug("!version", "thing v0.2")
local finalPlate = ui.ExtraCanvas(1000, 1, render.AntialiasingMode.None)
local num = "000"
local filepath = ac.getFolder(ac.FolderID.ExtTextures)
local clicked = false
local class = {"GT4","LMP3"}
local classPlates = 
{GT4={canvas=ui.ExtraCanvas(1000, 1, render.AntialiasingMode.None),src="https://raw.githubusercontent.com/tetematete/OSRLUASNIPPETS/refs/heads/main/img/numplate/GT4.jpg"}, 
LMP3={canvas=ui.ExtraCanvas(1000, 1, render.AntialiasingMode.None),src="https://raw.githubusercontent.com/tetematete/OSRLUASNIPPETS/refs/heads/main/img/numplate/LMP3.jpg"}}
local selClass = 1


for key, plate in pairs(classPlates) do
   ui.onImageReady(plate.src, function ()
plate.canvas:update(function (dt)
    ui.drawImage(plate.src, vec2(0,0), vec2(1000,1000))
end):setName(key)    
ac.log(key .. " ready!")
end) 
end




ui.registerOnlineExtra(ui.Icons.LoadingSpinner, "Numberplate", function ()
    return true
end, function ()
    local changed = false
    selClass, changed = ui.combo("Class", selClass, ui.ComboFlags.None, class)

    finalPlate:clear()
    finalPlate:update(function (dt)
        ui.pushDWriteFont('Segoe UI;Weight=Black')
        ui.drawImage(classPlates[class[selClass]].canvas, vec2(0,0), vec2(1000,1000))
        ui.beginScale()
        ui.dwriteTextAligned(num, 250, ui.Alignment.Center, ui.Alignment.Center, vec2(1000,975), false, rgbm.colors.black)
        ui.endScale(2.15)
    end)

    ui.image(finalPlate, vec2(250,250))

    num = ui.inputText("Num", num, bit.bor(ui.InputTextFlags.CharsDecimal,ui.InputTextFlags.CharsNoBlank))
    if ui.button("Save and Copy Path") then
        finalPlate:save(filepath .. "\\numplate_"..num..".png", ac.ImageFormat.PNG)
        clicked = true
        ac.setClipboardText(filepath .. "\\numplate_"..num..".png")
    end
    if io.fileExists(filepath .. "\\numplate_"..num..".png") then
        ui.text("File saved to: " .. filepath .. "\\numplate_"..num..".png")
        --[[if ui.itemClicked(ui.MouseButton.Left) then
            ac.setClipboardText(filepath .. "\\numplate_"..tonumber(num)..".png")
            clicked = true
        end
        if ui.itemHovered() then
            if clicked then 
                ui.tooltip(function ()
                    ui.text("Path Copied!")
                end)
            else
                ui.tooltip(function ()
                    ui.text("Click to copy path")

                end)
            end
        end]]
        if clicked then
            
        ui.text("Path Copied To Clipboard")
        end
    end

end, function (okClicked)

end, ui.OnlineExtraFlags.Tool)
