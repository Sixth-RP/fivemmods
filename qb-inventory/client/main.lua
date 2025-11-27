local QBCore = exports['qb-core']:GetCoreObject()
local PlayerData = {}
local isInventoryOpen = false
local currentOtherInventory = nil
local inVehicle = false
local currentVehicle = nil
local nearbyDrops = {}

-- Initialize
CreateThread(function()
    while not QBCore do
        QBCore = exports['qb-core']:GetCoreObject()
        Wait(100)
    end
    
    PlayerData = QBCore.Functions.GetPlayerData()
end)

-- Events
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    PlayerData = QBCore.Functions.GetPlayerData()
    TriggerServerEvent('qb-inventory:server:loadInventory')
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    PlayerData = {}
    CloseInventory()
end)

RegisterNetEvent('QBCore:Player:SetPlayerData', function(val)
    PlayerData = val
end)

-- Open Inventory
RegisterNetEvent('qb-inventory:client:openInventory', function(data)
    if isInventoryOpen then return end
    
    local playerPed = PlayerPedId()
    
    if IsPedDeadOrDying(playerPed) or IsPedFalling(playerPed) then
        return
    end
    
    isInventoryOpen = true
    currentOtherInventory = data
    
    SetNuiFocus(true, true)
    
    local inventoryData = {
        action = "openInventory",
        playerInventory = {
            items = PlayerData.items or {},
            maxWeight = Config.MaxInventoryWeight,
            maxSlots = Config.MaxInventorySlots,
            weight = GetTotalWeight(PlayerData.items)
        },
        otherInventory = nil,
        playerData = {
            name = PlayerData.charinfo and (PlayerData.charinfo.firstname .. " " .. PlayerData.charinfo.lastname) or "Unknown",
            cash = PlayerData.money and PlayerData.money.cash or 0,
            bank = PlayerData.money and PlayerData.money.bank or 0
        }
    }
    
    if data then
        inventoryData.otherInventory = {
            type = data.type,
            id = data.id,
            label = data.label,
            items = data.items or {},
            maxWeight = data.maxWeight or 100000,
            maxSlots = data.maxSlots or 50,
            weight = GetTotalWeight(data.items)
        }
    end
    
    SendNUIMessage(inventoryData)
    
    if Config.UI.blur then
        TriggerScreenblurFadeIn(250)
    end
    
    PlaySoundFrontend(-1, "Highlight_Nav_Up", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
end)

-- Close Inventory
function CloseInventory()
    if not isInventoryOpen then return end
    
    isInventoryOpen = false
    currentOtherInventory = nil
    
    SetNuiFocus(false, false)
    
    SendNUIMessage({
        action = "closeInventory"
    })
    
    if Config.UI.blur then
        TriggerScreenblurFadeOut(250)
    end
    
    PlaySoundFrontend(-1, "Highlight_Nav_Down", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
end

-- NUI Callbacks
RegisterNUICallback('closeInventory', function(data, cb)
    CloseInventory()
    cb('ok')
end)

RegisterNUICallback('moveItem', function(data, cb)
    TriggerServerEvent('qb-inventory:server:moveItem', data)
    PlaySoundFrontend(-1, "PICK_UP", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
    cb('ok')
end)

RegisterNUICallback('useItem', function(data, cb)
    TriggerServerEvent('qb-inventory:server:useItem', data.slot)
    PlaySoundFrontend(-1, "SELECT", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
    cb('ok')
end)

RegisterNUICallback('dropItem', function(data, cb)
    local coords = GetEntityCoords(PlayerPedId())
    TriggerServerEvent('qb-inventory:server:dropItem', data.slot, data.amount, coords)
    PlaySoundFrontend(-1, "DROP_WEAPON", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
    cb('ok')
end)

RegisterNUICallback('giveItem', function(data, cb)
    local player, distance = QBCore.Functions.GetClosestPlayer()
    if player ~= -1 and distance < 3.0 then
        local targetServerId = GetPlayerServerId(player)
        TriggerServerEvent('qb-inventory:server:giveItem', targetServerId, data.slot, data.amount)
        PlaySoundFrontend(-1, "PICK_UP", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
    else
        QBCore.Functions.Notify(Lang:t('error.no_nearby_player'), 'error')
    end
    cb('ok')
end)

RegisterNUICallback('splitItem', function(data, cb)
    TriggerServerEvent('qb-inventory:server:splitItem', data.slot, data.amount)
    PlaySoundFrontend(-1, "PICK_UP", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
    cb('ok')
end)

RegisterNUICallback('purchaseItem', function(data, cb)
    TriggerServerEvent('qb-inventory:server:purchaseItem', data.shop, data.item, data.amount)
    cb('ok')
end)

RegisterNUICallback('getItemInfo', function(data, cb)
    local itemInfo = QBCore.Shared.Items[data.item]
    cb(itemInfo or {})
end)

-- Update Inventory
RegisterNetEvent('qb-inventory:client:updateInventory', function(items)
    PlayerData.items = items
    
    if isInventoryOpen then
        SendNUIMessage({
            action = "updateInventory",
            playerInventory = {
                items = items,
                maxWeight = Config.MaxInventoryWeight,
                maxSlots = Config.MaxInventorySlots,
                weight = GetTotalWeight(items)
            }
        })
    end
end)

-- Update Other Inventory
RegisterNetEvent('qb-inventory:client:updateOtherInventory', function(items)
    if isInventoryOpen and currentOtherInventory then
        SendNUIMessage({
            action = "updateOtherInventory",
            items = items,
            weight = GetTotalWeight(items)
        })
    end
end)

-- Hotbar
RegisterNetEvent('qb-inventory:client:updateHotbar', function(hotbar)
    SendNUIMessage({
        action = "updateHotbar",
        hotbar = hotbar
    })
end)

-- Show Notification
RegisterNetEvent('qb-inventory:client:notify', function(message, type)
    QBCore.Functions.Notify(message, type)
end)

-- Item Animation
RegisterNetEvent('qb-inventory:client:useItemAnimation', function(item)
    local animData = Config.ItemAnimations[item]
    if animData then
        local playerPed = PlayerPedId()
        RequestAnimDict(animData.dict)
        while not HasAnimDictLoaded(animData.dict) do
            Wait(10)
        end
        TaskPlayAnim(playerPed, animData.dict, animData.anim, 8.0, -8.0, animData.time, 49, 0, false, false, false)
        Wait(animData.time)
        ClearPedTasks(playerPed)
    end
end)

-- Keybind
RegisterCommand('inventory', function()
    if not isInventoryOpen then
        TriggerEvent('qb-inventory:client:openInventory')
    else
        CloseInventory()
    end
end, false)

RegisterKeyMapping('inventory', 'Open Inventory', 'keyboard', Config.OpenInventoryKey)

-- Hotbar Keys
for i = 1, #Config.HotbarKeys do
    RegisterCommand('hotbar' .. i, function()
        TriggerServerEvent('qb-inventory:server:useHotbarItem', i)
    end, false)
    RegisterKeyMapping('hotbar' .. i, 'Hotbar Slot ' .. i, 'keyboard', Config.HotbarKeys[i])
end

-- Vehicle Trunk/Glovebox
CreateThread(function()
    while true do
        Wait(500)
        local playerPed = PlayerPedId()
        inVehicle = IsPedInAnyVehicle(playerPed, false)
        
        if inVehicle then
            currentVehicle = GetVehiclePedIsIn(playerPed, false)
        else
            currentVehicle = nil
        end
    end
end)

-- Open Trunk
RegisterNetEvent('qb-inventory:client:openTrunk', function()
    local playerPed = PlayerPedId()
    local vehicle = QBCore.Functions.GetClosestVehicle()
    
    if vehicle and vehicle ~= 0 then
        local plate = GetVehicleNumberPlateText(vehicle)
        local vehicleClass = GetVehicleClass(vehicle)
        local trunkConfig = Config.VehicleTrunks[vehicleClass] or Config.VehicleTrunks[1]
        
        TriggerServerEvent('qb-inventory:server:openTrunk', plate, trunkConfig.slots, trunkConfig.weight)
    else
        QBCore.Functions.Notify(Lang:t('error.no_vehicle_nearby'), 'error')
    end
end)

-- Open Glovebox
RegisterNetEvent('qb-inventory:client:openGlovebox', function()
    if inVehicle and currentVehicle then
        local plate = GetVehicleNumberPlateText(currentVehicle)
        TriggerServerEvent('qb-inventory:server:openGlovebox', plate, Config.GloveboxSize.slots, Config.GloveboxSize.weight)
    else
        QBCore.Functions.Notify(Lang:t('error.not_in_vehicle'), 'error')
    end
end)

-- Open Stash
RegisterNetEvent('qb-inventory:client:openStash', function(stashId)
    local stash = Config.Stashes[stashId]
    if stash then
        if stash.job then
            if PlayerData.job and PlayerData.job.name == stash.job and PlayerData.job.grade.level >= stash.jobGrade then
                TriggerServerEvent('qb-inventory:server:openStash', stashId, stash.slots, stash.weight)
            else
                QBCore.Functions.Notify(Lang:t('error.no_access'), 'error')
            end
        else
            TriggerServerEvent('qb-inventory:server:openStash', stashId, stash.slots, stash.weight)
        end
    end
end)

-- Open Shop
RegisterNetEvent('qb-inventory:client:openShop', function(shopId)
    local shop = Config.Shops[shopId]
    if shop then
        TriggerEvent('qb-inventory:client:openInventory', {
            type = "shop",
            id = shopId,
            label = shop.name,
            items = shop.items,
            maxSlots = #shop.items,
            maxWeight = 0
        })
    end
end)

-- Open Other Player Inventory
RegisterNetEvent('qb-inventory:client:openPlayerInventory', function(targetId, targetName, targetItems, targetWeight, targetMaxWeight)
    TriggerEvent('qb-inventory:client:openInventory', {
        type = "player",
        id = targetId,
        label = targetName .. "'s Inventory",
        items = targetItems,
        maxSlots = Config.MaxInventorySlots,
        maxWeight = targetMaxWeight or Config.MaxInventoryWeight
    })
end)

-- Helper Functions
function GetTotalWeight(items)
    local weight = 0
    if items then
        for _, item in pairs(items) do
            if item then
                local itemInfo = QBCore.Shared.Items[item.name]
                if itemInfo then
                    weight = weight + (itemInfo.weight * (item.amount or 1))
                end
            end
        end
    end
    return weight
end

-- Ground Items
CreateThread(function()
    while true do
        Wait(1000)
        local playerCoords = GetEntityCoords(PlayerPedId())
        TriggerServerEvent('qb-inventory:server:getNearbyDrops', playerCoords)
    end
end)

RegisterNetEvent('qb-inventory:client:updateNearbyDrops', function(drops)
    nearbyDrops = drops
end)

-- Draw 3D Text
CreateThread(function()
    while true do
        local sleep = 1000
        local playerCoords = GetEntityCoords(PlayerPedId())
        
        for _, drop in pairs(nearbyDrops) do
            local distance = #(playerCoords - vector3(drop.coords.x, drop.coords.y, drop.coords.z))
            if distance < 10.0 then
                sleep = 0
                DrawMarker(2, drop.coords.x, drop.coords.y, drop.coords.z - 0.9, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.3, 0.3, 0.2, 30, 144, 255, 150, false, true, 2, false, nil, nil, false)
                
                if distance < 2.0 then
                    Draw3DText(drop.coords.x, drop.coords.y, drop.coords.z, "[E] Pickup Items")
                    if IsControlJustPressed(0, 38) then -- E Key
                        TriggerServerEvent('qb-inventory:server:openDrop', drop.id)
                    end
                end
            end
        end
        
        Wait(sleep)
    end
end)

function Draw3DText(x, y, z, text)
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(true)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(true)
    AddTextComponentString(text)
    SetDrawOrigin(x, y, z, 0)
    DrawText(0.0, 0.0)
    local factor = (string.len(text)) / 370
    DrawRect(0.0, 0.0 + 0.0125, 0.017 + factor, 0.03, 0, 0, 0, 75)
    ClearDrawOrigin()
end

-- Exports
exports('GetPlayerItems', function()
    return PlayerData.items
end)

exports('HasItem', function(item, amount)
    amount = amount or 1
    if PlayerData.items then
        for _, v in pairs(PlayerData.items) do
            if v and v.name == item and v.amount >= amount then
                return true
            end
        end
    end
    return false
end)

exports('GetItemCount', function(item)
    local count = 0
    if PlayerData.items then
        for _, v in pairs(PlayerData.items) do
            if v and v.name == item then
                count = count + v.amount
            end
        end
    end
    return count
end)
