local QBCore = exports['qb-core']:GetCoreObject()

RegisterNetEvent('ud-boosting:rewardPlayer')
AddEventHandler('ud-boosting:rewardPlayer', function(reward)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if Player then
        Player.Functions.AddMoney('cash', reward)
        TriggerClientEvent('QBCore:Notify', src, "You received $" .. reward .. " for delivering the vehicle.", "success")
    end
end)

QBCore.Functions.CreateUseableItem("bcontracts", function(source, item)
    local Player = QBCore.Functions.GetPlayer(source)
    TriggerClientEvent('ud-boosting:InsertContractList', source)
    Player.Functions.RemoveItem("bcontracts", 1)
    TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items["bcontracts"], "remove") 
end)

QBCore.Functions.CreateUseableItem("btablet", function(source, item)
    local Player = QBCore.Functions.GetPlayer(source)
    TriggerClientEvent('ud-boosting:testBoostingMenu', source)
end)

QBCore.Functions.CreateUseableItem("tdisabler", function(source, item)
    local Player = QBCore.Functions.GetPlayer(source)
    TriggerClientEvent('ud-boosting:boostinghack', source)
    Player.Functions.RemoveItem("tdisabler", 1)
    TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items["tdisabler"], "remove") 
end)