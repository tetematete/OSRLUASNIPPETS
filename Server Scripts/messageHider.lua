ac.onChatMessage(function (message, senderCarIndex, senderSessionID)
  if string.find(message, '^RP>') ~= nil then
    ac.log(message)
    return true
  end
end)