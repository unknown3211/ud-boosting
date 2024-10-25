local QBCore = exports['qb-core']:GetCoreObject()
local selectedContracts = {}
local hackCompleted = false
local currentVehicleModel = nil
local blip = nil
local vehicleSpawned = false

--[[RegisterCommand('boosting', function()
    TriggerEvent('ud-boosting:testBoostingMenu')
end)

RegisterCommand('getlist', function()
    InsertContractList()
end)--]]

RegisterNetEvent('ud-boosting:boostinghack')
AddEventHandler('ud-boosting:boostinghack', function()
    if currentVehicleModel then
        exports['skillchecks']:startAlphabetGame(Config.HackTime, Config.Keys, function(success)
            if success then
                QBCore.Functions.Notify("Hack successful", 1)
                exports['ud-ui']:StatusHud("Boosting", "Drop Off Vehicle At Location")
                hackCompleted = true
            else
                QBCore.Functions.Notify("Hack failed. Try again", 2)
            end
        end)
    else
        QBCore.Functions.Notify("You need to start a boosting contract first", 2)
    end
end)

function SendPoliceDispatch()
    local playerCoords = GetEntityCoords(PlayerPedId())
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    local vehicleName = GetLabelText(GetDisplayNameFromVehicleModel(GetEntityModel(vehicle)))
    
    local primaryColorIndex = GetVehicleColours(vehicle)
    local primaryColorName = Config.Colors[primaryColorIndex] or "Unknown"

    exports["np-dispatch"]:dispatchadd('10-99', "Vehicle Boost In Progress: " .. primaryColorName .. " " .. vehicleName .. " - ", playerCoords)
end

RegisterNetEvent('ud-boosting:InsertContractList')
AddEventHandler('ud-boosting:InsertContractList', function()
    InsertContractList()
end)

function InsertContractList()
    selectedContracts = {}
    local contractsCopy = {}
    for i, contract in ipairs(Config.Contracts) do
        table.insert(contractsCopy, contract)
    end

    for i = 1, math.min(Config.RandomContractAmount, #contractsCopy) do
        local randIndex = math.random(#contractsCopy)
        table.insert(selectedContracts, contractsCopy[randIndex])
        table.remove(contractsCopy, randIndex)
    end
end

RegisterNetEvent('ud-boosting:testBoostingMenu')
AddEventHandler('ud-boosting:testBoostingMenu', function()
    local TestMenu = {
        {
            header = Config.Header,
            icon = Config.HeaderIcon,
            isMenuHeader = true
        }
    }
    for i, contract in ipairs(selectedContracts) do
        local contractInfo = string.format("Class: %s, Type: %s", contract.class, contract.type)
        table.insert(TestMenu, {
            header = contract.vehicle,
            txt = contractInfo,
            icon = Config.MenuIcon,
            params = {
                event = "ud-boosting:spawnVehicle",
                args = {
                    vehicle = contract.vehicle,
                    locations = Config.VehicleSpawnLocations,
                    reward = contract.reward
                }
            }
        })
    end
    exports['qb-menu']:openMenu(TestMenu)
end)

RegisterNetEvent('ud-boosting:spawnVehicle')
AddEventHandler('ud-boosting:spawnVehicle', function(data)
    local spawnLocation = data.locations[math.random(#data.locations)]
    currentVehicleModel = data.vehicle
    QBCore.Functions.SpawnVehicle(currentVehicleModel, function(veh)
        SetEntityCoords(veh, spawnLocation.x, spawnLocation.y, spawnLocation.z, false, false, false, true)
        TriggerEvent('vehiclekeys:client:SetOwner', GetVehicleNumberPlateText(veh))
        blip = AddBlipForCoord(spawnLocation.x, spawnLocation.y, spawnLocation.z)
        SetBlipSprite(blip, 1)
        SetBlipColour(blip, 3)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString("Boosting Vehicle")
        EndTextCommandSetBlipName(blip)
        vehicleSpawned = true
        exports['ud-ui']:StatusHud("Boosting", "Head To Vehicle Location")
    end, spawnLocation, true)

    local dropOffLocation = Config.DropOffLocations[math.random(#Config.DropOffLocations)]

    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(0)
            local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
            if vehicle ~= 0 and vehicleSpawned and GetEntityModel(vehicle) == GetHashKey(currentVehicleModel) then
                RemoveBlip(blip)
                blip = AddBlipForCoord(dropOffLocation.x, dropOffLocation.y, dropOffLocation.z)
                SetBlipRoute(blip, true)
                SetBlipRouteColour(blip, 5)
                exports['ud-ui']:StatusHud("Boosting", "Take Off Vehicle Tracker Before Dropping Off")
                vehicleSpawned = false
                
                Citizen.CreateThread(function()
                    while not hackCompleted do
                        SendPoliceDispatch()
                        Citizen.Wait(7000)
                    end
                end)
            end
            
            local playerCoords = GetEntityCoords(PlayerPedId())
            local distance = #(playerCoords - vector3(dropOffLocation.x, dropOffLocation.y, dropOffLocation.z))
            if distance < Config.ZoneRadius then
                if IsControlJustReleased(0, 38) then
                    if not hackCompleted then
                        QBCore.Functions.Notify("You need to complete the hack first", 2)
                    else
                        QBCore.Functions.DeleteVehicle(vehicle)
                        RemoveBlip(blip)
                        QBCore.Functions.Notify(Config.DropMessage, 1)
                        exports['ud-ui']:StatusHudClose()
                        for i, contract in ipairs(selectedContracts) do
                            if contract.vehicle == currentVehicleModel then
                                TriggerServerEvent('ud-boosting:rewardPlayer', contract.reward)
                                table.remove(selectedContracts, i)
                                break
                            end
                        end
                        currentVehicleModel = nil
                        return
                    end
                end
            end
        end
    end)
end)