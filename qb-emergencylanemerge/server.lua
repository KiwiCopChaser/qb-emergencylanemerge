local QBCore = exports['qb-core']:GetCoreObject()

-- Server-side events (for future expansion)
RegisterNetEvent('emergency-merge:server:syncEmergencyStatus', function(vehicleNetId, hasEmergency)
    -- Sync emergency status across clients if needed
    TriggerClientEvent('emergency-merge:client:updateEmergencyStatus', -1, vehicleNetId, hasEmergency, source)
end)

-- Command to toggle debug mode (admin only)
QBCore.Commands.Add('mergedebug', 'Toggle emergency merge debug mode', {}, false, function(source, args)
    local Player = QBCore.Functions.GetPlayer(source)
    if Player.PlayerData.group == 'admin' then
        TriggerClientEvent('emergency-merge:client:toggleDebug', source)
    else
        TriggerClientEvent('QBCore:Notify', source, 'You do not have permission to use this command', 'error')
    end
end, 'admin')

-- Get player count for performance monitoring
RegisterNetEvent('emergency-merge:server:getPlayerCount', function()
    local playerCount = GetNumPlayerIndices()
    TriggerClientEvent('emergency-merge:client:receivePlayerCount', source, playerCount)
end)

print('^2[Emergency Merge] ^7Server script loaded successfully')

-- ==========================================
RegisterNetEvent('emergency-merge:client:toggleDebug', function()
    Config.EnableDebug = not Config.EnableDebug
    QBCore.Functions.Notify(('Debug mode %s'):format(Config.EnableDebug and 'enabled' or 'disabled'), 'info')
end)

RegisterNetEvent('emergency-merge:client:updateEmergencyStatus', function(vehicleNetId, hasEmergency, playerId)
    -- Handle emergency status updates from other players
    local vehicle = NetworkGetEntityFromNetworkId(vehicleNetId)
    if DoesEntityExist(vehicle) then
        emergencyVehicles[vehicle] = hasEmergency and GetGameTimer() + 5000 or nil
    end
end)

RegisterNetEvent('emergency-merge:client:receivePlayerCount', function(playerCount)
    if Config.EnableDebug then
        print(('Emergency Merge: %d players online'):format(playerCount))
    end
end)