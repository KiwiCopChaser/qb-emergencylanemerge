local QBCore = exports['qb-core']:GetCoreObject()
local PlayerData = {}
local emergencyVehicles = {}
local processedVehicles = {}

-- Initialize
CreateThread(function()
    while QBCore == nil do
        Wait(10)
    end
    
    PlayerData = QBCore.Functions.GetPlayerData()
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    PlayerData = QBCore.Functions.GetPlayerData()
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(JobInfo)
    PlayerData.job = JobInfo
end)

-- Function to check if vehicle is emergency vehicle
local function IsEmergencyVehicle(vehicle)
    if not DoesEntityExist(vehicle) then return false end
    
    local model = GetEntityModel(vehicle)
    local class = GetVehicleClass(vehicle)
    
    -- Check by vehicle class and model
    local isEmergencyClass = Config.EmergencyClasses[class] or false
    local isEmergencyModel = Config.EmergencyVehicles[model] or false
    
    return isEmergencyClass or isEmergencyModel
end

-- Function to check if vehicle is civilian AI vehicle
local function IsCivilianAIVehicle(vehicle)
    if not DoesEntityExist(vehicle) then return false end
    
    -- Don't merge emergency vehicles
    if IsEmergencyVehicle(vehicle) then return false end
    
    local driver = GetPedInVehicleSeat(vehicle, -1)
    if not DoesEntityExist(driver) then return false end
    
    -- CRITICAL: Don't merge any player vehicles
    if IsPedAPlayer(driver) then return false end
    
    -- Check if any player is in the vehicle
    for i = -1, GetVehicleMaxNumberOfPassengers(vehicle) - 1 do
        local passenger = GetPedInVehicleSeat(vehicle, i)
        if DoesEntityExist(passenger) and IsPedAPlayer(passenger) then
            return false -- Player is in vehicle, don't merge
        end
    end
    
    -- Only merge civilian AI peds (type 4 = civilian)
    if GetPedType(driver) ~= 4 then return false end
    
    -- Additional check: Make sure it's actually an AI ped
    if NetworkGetEntityOwner(vehicle) ~= -1 and NetworkGetEntityOwner(driver) ~= -1 then
        -- This might be a player-controlled entity
        return false
    end
    
    return true
end

-- Function to check if emergency vehicle has lights/sirens active
local function HasEmergencyActive(vehicle)
    if not DoesEntityExist(vehicle) then return false end
    
    -- Check if it's a player vehicle first
    local driver = GetPedInVehicleSeat(vehicle, -1)
    if DoesEntityExist(driver) and IsPedAPlayer(driver) then
        -- For player emergency vehicles, check lights and sirens
        return IsVehicleSirenOn(vehicle) or GetVehicleHornActive(vehicle)
    end
    
    -- For AI emergency vehicles, also check lights and sirens
    return IsVehicleSirenOn(vehicle) or GetVehicleHornActive(vehicle)
end

-- Function to get lane direction relative to emergency vehicle
local function GetLaneDirection(emergencyVeh, targetVeh)
    local emergencyPos = GetEntityCoords(emergencyVeh)
    local targetPos = GetEntityCoords(targetVeh)
    local emergencyHeading = GetEntityHeading(emergencyVeh)
    
    -- Calculate relative position
    local dx = targetPos.x - emergencyPos.x
    local dy = targetPos.y - emergencyPos.y
    
    -- Convert to local coordinates relative to emergency vehicle heading
    local cos_h = math.cos(math.rad(emergencyHeading))
    local sin_h = math.sin(math.rad(emergencyHeading))
    
    local localX = dx * cos_h + dy * sin_h
    local localY = -dx * sin_h + dy * cos_h
    
    -- Determine which side the target is on
    if localY > 0 then
        return "right"
    else
        return "left"
    end
end

-- Function to make vehicle merge to opposite lane
local function MergeVehicle(vehicle, direction, emergencyVeh)
    if not DoesEntityExist(vehicle) or not DoesEntityExist(emergencyVeh) then return end
    
    -- Triple check: Only merge civilian AI vehicles
    if not IsCivilianAIVehicle(vehicle) then return end
    
    local driver = GetPedInVehicleSeat(vehicle, -1)
    if not DoesEntityExist(driver) then return end
    
    -- Clear existing tasks
    ClearPedTasks(driver)
    
    -- Get positions and headings
    local vehPos = GetEntityCoords(vehicle)
    local vehHeading = GetEntityHeading(vehicle)
    local emergencyPos = GetEntityCoords(emergencyVeh)
    
    -- Calculate merge direction (opposite of current lane)
    local mergeOffset = 4.0 -- Distance to merge
    if direction == "right" then
        mergeOffset = -mergeOffset -- Merge left if on right side
    end
    
    -- Calculate merge target position
    local cos_h = math.cos(math.rad(vehHeading))
    local sin_h = math.sin(math.rad(vehHeading))
    
    local mergeX = vehPos.x + (mergeOffset * -sin_h)
    local mergeY = vehPos.y + (mergeOffset * cos_h)
    local mergeZ = vehPos.z
    
    -- Set vehicle to merge
    TaskVehicleDriveToCoord(
        driver,
        vehicle,
        mergeX,
        mergeY,
        mergeZ,
        GetVehicleModelMaxSpeed(GetEntityModel(vehicle)) * Config.MergeSpeed,
        0,
        GetEntityModel(vehicle),
        786603, -- Driving style: careful + avoid traffic
        2.0,
        true
    )
    
    -- Mark as processed to avoid repeated commands
    processedVehicles[vehicle] = GetGameTimer() + 10000 -- Process for 10 seconds
    
    if Config.EnableDebug then
        print(("AI vehicle %d (driver type: %d) merging %s away from emergency vehicle %d"):format(
            vehicle, 
            GetPedType(GetPedInVehicleSeat(vehicle, -1)),
            direction == "right" and "left" or "right",
            emergencyVeh
        ))
    end
end

-- Main processing thread
CreateThread(function()
    while true do
        Wait(Config.UpdateInterval)
        
        local playerPed = PlayerPedId()
        local playerPos = GetEntityCoords(playerPed)
        
        -- Get all vehicles in range
        local vehicles = GetGamePool('CVehicle')
        local emergencyFound = false
        
        -- Find emergency vehicles with active lights/sirens
        local activeEmergencyVehicles = {}
        
        for _, vehicle in pairs(vehicles) do
            if DoesEntityExist(vehicle) then
                local vehPos = GetEntityCoords(vehicle)
                local distance = #(playerPos - vehPos)
                
                if distance <= Config.DetectionRange then
                    if IsEmergencyVehicle(vehicle) and HasEmergencyActive(vehicle) then
                        table.insert(activeEmergencyVehicles, vehicle)
                        emergencyFound = true
                    end
                end
            end
        end
        
        -- If emergency vehicles found, process civilian vehicles
        if emergencyFound then
            local processedCount = 0
            
            for _, emergencyVeh in pairs(activeEmergencyVehicles) do
                local emergencyPos = GetEntityCoords(emergencyVeh)
                
                for _, vehicle in pairs(vehicles) do
                    if processedCount >= Config.MaxMergeVehicles then break end
                    
                    if DoesEntityExist(vehicle) and vehicle ~= emergencyVeh then
                        local vehPos = GetEntityCoords(vehicle)
                        local distance = #(emergencyPos - vehPos)
                        
                        -- Check if vehicle should merge (ONLY civilian AI vehicles)
                        if distance <= Config.MergeDistance and 
                           IsCivilianAIVehicle(vehicle) and
                           GetEntitySpeed(vehicle) > Config.MinMergeSpeed and -- Only merge moving vehicles
                           (not processedVehicles[vehicle] or GetGameTimer() > processedVehicles[vehicle]) then
                            
                            local direction = GetLaneDirection(emergencyVeh, vehicle)
                            MergeVehicle(vehicle, direction, emergencyVeh)
                            processedCount = processedCount + 1
                        end
                    end
                end
            end
        end
        
        -- Clean up old processed vehicles
        for vehicle, expireTime in pairs(processedVehicles) do
            if GetGameTimer() > expireTime or not DoesEntityExist(vehicle) then
                processedVehicles[vehicle] = nil
            end
        end
    end
end)

-- Cleanup on resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        -- Clear all processed vehicles
        for vehicle, _ in pairs(processedVehicles) do
            if DoesEntityExist(vehicle) then
                local driver = GetPedInVehicleSeat(vehicle, -1)
                if DoesEntityExist(driver) then
                    ClearPedTasks(driver)
                end
            end
        end
        processedVehicles = {}
    end
end)
