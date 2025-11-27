local QBCore = exports['qb-core']:GetCoreObject()
local Inventories = {}
local Drops = {}
local Trunks = {}
local Gloveboxes = {}
local Stashes = {}
local PlayerInventoryOpen = {} -- Track who is viewing whose inventory
local dropId = 0

-- Load Player Inventory
RegisterNetEvent('qb-inventory:server:loadInventory', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if Player then
        local items = Player.PlayerData.items
        TriggerClientEvent('qb-inventory:client:updateInventory', src, items)
        TriggerClientEvent('qb-inventory:client:updateHotbar', src, GetHotbarItems(items))
    end
end)

-- Move Item
RegisterNetEvent('qb-inventory:server:moveItem', function(data)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    local fromSlot = data.fromSlot
    local toSlot = data.toSlot
    local fromInventory = data.fromInventory
    local toInventory = data.toInventory
    local amount = tonumber(data.amount) or 1
    
    -- Player to Player
    if fromInventory == "player" and toInventory == "player" then
        local items = Player.PlayerData.items
        local fromItem = items[fromSlot]
        
        if not fromItem then return end
        
        if fromSlot == toSlot then return end
        
        local toItem = items[toSlot]
        
        -- Stack items
        if toItem and toItem.name == fromItem.name and not fromItem.unique then
            toItem.amount = toItem.amount + amount
            if amount >= fromItem.amount then
                items[fromSlot] = nil
            else
                fromItem.amount = fromItem.amount - amount
            end
        else
            -- Swap items
            if amount >= fromItem.amount then
                items[fromSlot] = toItem
                items[toSlot] = fromItem
            else
                -- Split stack
                local newItem = {
                    name = fromItem.name,
                    amount = amount,
                    info = fromItem.info,
                    label = fromItem.label,
                    description = fromItem.description,
                    weight = fromItem.weight,
                    type = fromItem.type,
                    unique = fromItem.unique,
                    useable = fromItem.useable,
                    image = fromItem.image,
                    slot = toSlot
                }
                items[toSlot] = newItem
                fromItem.amount = fromItem.amount - amount
            end
        end
        
        Player.Functions.SetPlayerData("items", items)
        TriggerClientEvent('qb-inventory:client:updateInventory', src, items)
        TriggerClientEvent('qb-inventory:client:updateHotbar', src, GetHotbarItems(items))
    
    -- Player to Other (trunk, stash, drop)
    elseif fromInventory == "player" and toInventory == "other" then
        local items = Player.PlayerData.items
        local fromItem = items[fromSlot]
        
        if not fromItem then return end
        
        local otherInventory = GetOtherInventory(data.otherId, data.otherType)
        if not otherInventory then return end
        
        local success = AddItemToInventory(otherInventory, fromItem, toSlot, amount)
        if success then
            if amount >= fromItem.amount then
                items[fromSlot] = nil
            else
                fromItem.amount = fromItem.amount - amount
            end
            Player.Functions.SetPlayerData("items", items)
            TriggerClientEvent('qb-inventory:client:updateInventory', src, items)
            TriggerClientEvent('qb-inventory:client:updateOtherInventory', src, otherInventory.items)
            TriggerClientEvent('qb-inventory:client:updateHotbar', src, GetHotbarItems(items))
            SaveOtherInventory(data.otherId, data.otherType, otherInventory)
        else
            TriggerClientEvent('qb-inventory:client:notify', src, Lang:t('error.not_enough_space'), 'error')
        end
    
    -- Other to Player
    elseif fromInventory == "other" and toInventory == "player" then
        local otherInventory = GetOtherInventory(data.otherId, data.otherType)
        if not otherInventory then return end
        
        local fromItem = otherInventory.items[fromSlot]
        if not fromItem then return end
        
        local items = Player.PlayerData.items
        local itemInfo = QBCore.Shared.Items[fromItem.name]
        local weight = GetTotalWeight(items) + (itemInfo.weight * amount)
        
        if weight > Config.MaxInventoryWeight then
            TriggerClientEvent('qb-inventory:client:notify', src, Lang:t('error.too_heavy'), 'error')
            return
        end
        
        local toItem = items[toSlot]
        
        if toItem and toItem.name == fromItem.name and not fromItem.unique then
            toItem.amount = toItem.amount + amount
        else
            local newItem = {
                name = fromItem.name,
                amount = amount,
                info = fromItem.info,
                label = fromItem.label or itemInfo.label,
                description = fromItem.description or itemInfo.description,
                weight = itemInfo.weight,
                type = fromItem.type or itemInfo.type,
                unique = fromItem.unique or itemInfo.unique,
                useable = itemInfo.useable,
                image = fromItem.image or itemInfo.image,
                slot = toSlot
            }
            items[toSlot] = newItem
        end
        
        if amount >= fromItem.amount then
            otherInventory.items[fromSlot] = nil
        else
            fromItem.amount = fromItem.amount - amount
        end
        
        Player.Functions.SetPlayerData("items", items)
        TriggerClientEvent('qb-inventory:client:updateInventory', src, items)
        TriggerClientEvent('qb-inventory:client:updateOtherInventory', src, otherInventory.items)
        TriggerClientEvent('qb-inventory:client:updateHotbar', src, GetHotbarItems(items))
        SaveOtherInventory(data.otherId, data.otherType, otherInventory)
    end
end)

-- Use Item
RegisterNetEvent('qb-inventory:server:useItem', function(slot)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    local items = Player.PlayerData.items
    local item = items[slot]
    
    if not item then return end
    
    local itemInfo = QBCore.Shared.Items[item.name]
    if not itemInfo then return end
    
    if itemInfo.useable then
        TriggerClientEvent('qb-inventory:client:useItemAnimation', src, item.name)
        TriggerEvent('qb-inventory:server:useItem:' .. item.name, src, item)
        
        -- Remove consumable items
        if itemInfo.type == "item" and not itemInfo.unique then
            item.amount = item.amount - 1
            if item.amount <= 0 then
                items[slot] = nil
            end
            Player.Functions.SetPlayerData("items", items)
            TriggerClientEvent('qb-inventory:client:updateInventory', src, items)
            TriggerClientEvent('qb-inventory:client:updateHotbar', src, GetHotbarItems(items))
        end
    end
end)

-- Use Hotbar Item
RegisterNetEvent('qb-inventory:server:useHotbarItem', function(slot)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    local items = Player.PlayerData.items
    local item = items[slot]
    
    if item then
        TriggerEvent('qb-inventory:server:useItem', slot)
    end
end)

-- Drop Item
RegisterNetEvent('qb-inventory:server:dropItem', function(slot, amount, coords)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    local items = Player.PlayerData.items
    local item = items[slot]
    
    if not item then return end
    
    amount = math.min(amount, item.amount)
    
    -- Create drop
    dropId = dropId + 1
    local drop = {
        id = dropId,
        coords = coords,
        items = {},
        maxSlots = Config.MaxDropSlots,
        maxWeight = Config.MaxDropWeight,
        time = os.time()
    }
    
    local newItem = {
        name = item.name,
        amount = amount,
        info = item.info,
        label = item.label,
        description = item.description,
        weight = item.weight,
        type = item.type,
        unique = item.unique,
        useable = item.useable,
        image = item.image,
        slot = 1
    }
    drop.items[1] = newItem
    Drops[dropId] = drop
    
    -- Remove from player
    item.amount = item.amount - amount
    if item.amount <= 0 then
        items[slot] = nil
    end
    
    Player.Functions.SetPlayerData("items", items)
    TriggerClientEvent('qb-inventory:client:updateInventory', src, items)
    TriggerClientEvent('qb-inventory:client:updateHotbar', src, GetHotbarItems(items))
    TriggerClientEvent('qb-inventory:client:notify', src, string.format(Lang:t('success.item_dropped'), item.label, amount), 'success')
end)

-- Open Drop
RegisterNetEvent('qb-inventory:server:openDrop', function(id)
    local src = source
    local drop = Drops[id]
    
    if drop then
        TriggerClientEvent('qb-inventory:client:openInventory', src, {
            type = "drop",
            id = id,
            label = "Ground",
            items = drop.items,
            maxSlots = drop.maxSlots,
            maxWeight = drop.maxWeight
        })
    end
end)

-- Give Item
RegisterNetEvent('qb-inventory:server:giveItem', function(targetId, slot, amount)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local Target = QBCore.Functions.GetPlayer(targetId)
    
    if not Player or not Target then return end
    
    local items = Player.PlayerData.items
    local item = items[slot]
    
    if not item then return end
    
    amount = math.min(amount, item.amount)
    
    local itemInfo = QBCore.Shared.Items[item.name]
    local targetItems = Target.PlayerData.items
    local targetWeight = GetTotalWeight(targetItems) + (itemInfo.weight * amount)
    
    if targetWeight > Config.MaxInventoryWeight then
        TriggerClientEvent('qb-inventory:client:notify', src, Lang:t('error.cannot_carry'), 'error')
        return
    end
    
    -- Find empty slot for target
    local targetSlot = GetFirstEmptySlot(targetItems)
    if not targetSlot then
        TriggerClientEvent('qb-inventory:client:notify', src, Lang:t('error.inventory_full'), 'error')
        return
    end
    
    -- Add to target
    local newItem = {
        name = item.name,
        amount = amount,
        info = item.info,
        label = item.label,
        description = item.description,
        weight = item.weight,
        type = item.type,
        unique = item.unique,
        useable = item.useable,
        image = item.image,
        slot = targetSlot
    }
    targetItems[targetSlot] = newItem
    
    -- Remove from player
    item.amount = item.amount - amount
    if item.amount <= 0 then
        items[slot] = nil
    end
    
    Player.Functions.SetPlayerData("items", items)
    Target.Functions.SetPlayerData("items", targetItems)
    
    TriggerClientEvent('qb-inventory:client:updateInventory', src, items)
    TriggerClientEvent('qb-inventory:client:updateInventory', targetId, targetItems)
    TriggerClientEvent('qb-inventory:client:updateHotbar', src, GetHotbarItems(items))
    TriggerClientEvent('qb-inventory:client:updateHotbar', targetId, GetHotbarItems(targetItems))
    
    TriggerClientEvent('qb-inventory:client:notify', src, string.format(Lang:t('success.item_given'), item.label, amount), 'success')
    TriggerClientEvent('qb-inventory:client:notify', targetId, string.format(Lang:t('success.item_received'), item.label, amount), 'success')
end)

-- Split Item
RegisterNetEvent('qb-inventory:server:splitItem', function(slot, amount)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    local items = Player.PlayerData.items
    local item = items[slot]
    
    if not item or item.amount <= amount then return end
    
    local emptySlot = GetFirstEmptySlot(items)
    if not emptySlot then
        TriggerClientEvent('qb-inventory:client:notify', src, Lang:t('error.inventory_full'), 'error')
        return
    end
    
    local newItem = {
        name = item.name,
        amount = amount,
        info = item.info,
        label = item.label,
        description = item.description,
        weight = item.weight,
        type = item.type,
        unique = item.unique,
        useable = item.useable,
        image = item.image,
        slot = emptySlot
    }
    
    items[emptySlot] = newItem
    item.amount = item.amount - amount
    
    Player.Functions.SetPlayerData("items", items)
    TriggerClientEvent('qb-inventory:client:updateInventory', src, items)
    TriggerClientEvent('qb-inventory:client:updateHotbar', src, GetHotbarItems(items))
end)

-- Purchase Item
RegisterNetEvent('qb-inventory:server:purchaseItem', function(shopId, itemName, amount)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    local shop = Config.Shops[shopId]
    if not shop then return end
    
    local shopItem = nil
    for _, item in pairs(shop.items) do
        if item.name == itemName then
            shopItem = item
            break
        end
    end
    
    if not shopItem then return end
    if shopItem.amount and shopItem.amount < amount then
        TriggerClientEvent('qb-inventory:client:notify', src, Lang:t('error.item_limit_reached'), 'error')
        return
    end
    
    local totalPrice = shopItem.price * amount
    local cash = Player.PlayerData.money.cash
    
    if cash < totalPrice then
        TriggerClientEvent('qb-inventory:client:notify', src, Lang:t('error.not_enough_money'), 'error')
        return
    end
    
    local itemInfo = QBCore.Shared.Items[itemName]
    if not itemInfo then return end
    
    local items = Player.PlayerData.items
    local weight = GetTotalWeight(items) + (itemInfo.weight * amount)
    
    if weight > Config.MaxInventoryWeight then
        TriggerClientEvent('qb-inventory:client:notify', src, Lang:t('error.too_heavy'), 'error')
        return
    end
    
    Player.Functions.RemoveMoney('cash', totalPrice, 'shop-purchase')
    
    local slot = GetFirstEmptySlot(items)
    if not slot then
        TriggerClientEvent('qb-inventory:client:notify', src, Lang:t('error.inventory_full'), 'error')
        return
    end
    
    local newItem = {
        name = itemName,
        amount = amount,
        info = {},
        label = itemInfo.label,
        description = itemInfo.description,
        weight = itemInfo.weight,
        type = itemInfo.type,
        unique = itemInfo.unique,
        useable = itemInfo.useable,
        image = itemInfo.image,
        slot = slot
    }
    
    items[slot] = newItem
    Player.Functions.SetPlayerData("items", items)
    TriggerClientEvent('qb-inventory:client:updateInventory', src, items)
    TriggerClientEvent('qb-inventory:client:updateHotbar', src, GetHotbarItems(items))
    TriggerClientEvent('qb-inventory:client:notify', src, string.format(Lang:t('success.purchased'), itemInfo.label, amount, totalPrice), 'success')
end)

-- Open Trunk
RegisterNetEvent('qb-inventory:server:openTrunk', function(plate, slots, weight)
    local src = source
    
    if not Trunks[plate] then
        Trunks[plate] = {
            items = {},
            maxSlots = slots,
            maxWeight = weight
        }
    end
    
    TriggerClientEvent('qb-inventory:client:openInventory', src, {
        type = "trunk",
        id = plate,
        label = "Trunk - " .. plate,
        items = Trunks[plate].items,
        maxSlots = Trunks[plate].maxSlots,
        maxWeight = Trunks[plate].maxWeight
    })
end)

-- Open Glovebox
RegisterNetEvent('qb-inventory:server:openGlovebox', function(plate, slots, weight)
    local src = source
    
    if not Gloveboxes[plate] then
        Gloveboxes[plate] = {
            items = {},
            maxSlots = slots,
            maxWeight = weight
        }
    end
    
    TriggerClientEvent('qb-inventory:client:openInventory', src, {
        type = "glovebox",
        id = plate,
        label = "Glovebox - " .. plate,
        items = Gloveboxes[plate].items,
        maxSlots = Gloveboxes[plate].maxSlots,
        maxWeight = Gloveboxes[plate].maxWeight
    })
end)

-- Open Stash
RegisterNetEvent('qb-inventory:server:openStash', function(stashId, slots, weight)
    local src = source
    
    if not Stashes[stashId] then
        Stashes[stashId] = {
            items = {},
            maxSlots = slots,
            maxWeight = weight
        }
        
        -- Load from database
        MySQL.Async.fetchScalar('SELECT items FROM stashitems WHERE stash = ?', {stashId}, function(result)
            if result then
                Stashes[stashId].items = json.decode(result)
            end
        end)
    end
    
    TriggerClientEvent('qb-inventory:client:openInventory', src, {
        type = "stash",
        id = stashId,
        label = Config.Stashes[stashId] and Config.Stashes[stashId].name or "Stash",
        items = Stashes[stashId].items,
        maxSlots = Stashes[stashId].maxSlots,
        maxWeight = Stashes[stashId].maxWeight
    })
end)

-- Get Nearby Drops
RegisterNetEvent('qb-inventory:server:getNearbyDrops', function(coords)
    local src = source
    local nearby = {}
    
    for id, drop in pairs(Drops) do
        local distance = #(vector3(coords.x, coords.y, coords.z) - vector3(drop.coords.x, drop.coords.y, drop.coords.z))
        if distance < 20.0 then
            table.insert(nearby, {
                id = id,
                coords = drop.coords
            })
        end
    end
    
    TriggerClientEvent('qb-inventory:client:updateNearbyDrops', src, nearby)
end)

-- Open Other Player Inventory
RegisterNetEvent('qb-inventory:server:openPlayerInventory', function(targetId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local Target = QBCore.Functions.GetPlayer(targetId)
    
    if not Player or not Target then
        TriggerClientEvent('qb-inventory:client:notify', src, Lang:t('error.no_nearby_player'), 'error')
        return
    end
    
    -- Check if player has permission (police job or admin)
    local hasPermission = false
    if Player.PlayerData.job then
        if Player.PlayerData.job.name == 'police' or Player.PlayerData.job.name == 'ambulance' then
            hasPermission = true
        end
    end
    
    -- Check admin permission
    if QBCore.Functions.HasPermission(src, 'admin') or QBCore.Functions.HasPermission(src, 'god') then
        hasPermission = true
    end
    
    if not hasPermission then
        TriggerClientEvent('qb-inventory:client:notify', src, Lang:t('error.no_access'), 'error')
        return
    end
    
    local targetName = Target.PlayerData.charinfo.firstname .. " " .. Target.PlayerData.charinfo.lastname
    local targetItems = Target.PlayerData.items
    local targetWeight = GetTotalWeight(targetItems)
    
    -- Store the connection for syncing
    PlayerInventoryOpen[src] = targetId
    
    TriggerClientEvent('qb-inventory:client:openPlayerInventory', src, targetId, targetName, targetItems, targetWeight, Config.MaxInventoryWeight)
end)

-- Sync player inventory changes when viewing another player
RegisterNetEvent('qb-inventory:server:syncPlayerInventory', function(targetId)
    local src = source
    local Target = QBCore.Functions.GetPlayer(targetId)
    
    if Target then
        local targetItems = Target.PlayerData.items
        local targetWeight = GetTotalWeight(targetItems)
        TriggerClientEvent('qb-inventory:client:updateOtherInventory', src, targetItems, targetWeight)
    end
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

function GetFirstEmptySlot(items)
    for i = 1, Config.MaxInventorySlots do
        if not items[i] then
            return i
        end
    end
    return nil
end

function GetHotbarItems(items)
    local hotbar = {}
    for i = 1, Config.HotbarSlots do
        hotbar[i] = items[i]
    end
    return hotbar
end

function GetOtherInventory(id, type)
    if type == "trunk" then
        return Trunks[id]
    elseif type == "glovebox" then
        return Gloveboxes[id]
    elseif type == "stash" then
        return Stashes[id]
    elseif type == "drop" then
        return Drops[id]
    elseif type == "player" then
        local Target = QBCore.Functions.GetPlayer(id)
        if Target then
            return {
                items = Target.PlayerData.items,
                maxSlots = Config.MaxInventorySlots,
                maxWeight = Config.MaxInventoryWeight
            }
        end
    end
    return nil
end

function AddItemToInventory(inventory, item, slot, amount)
    local itemInfo = QBCore.Shared.Items[item.name]
    local weight = GetTotalWeight(inventory.items) + (itemInfo.weight * amount)
    
    if weight > inventory.maxWeight then
        return false
    end
    
    local existingItem = inventory.items[slot]
    
    if existingItem and existingItem.name == item.name and not item.unique then
        existingItem.amount = existingItem.amount + amount
    else
        local targetSlot = slot
        if inventory.items[slot] then
            for i = 1, inventory.maxSlots do
                if not inventory.items[i] then
                    targetSlot = i
                    break
                end
            end
        end
        
        local newItem = {
            name = item.name,
            amount = amount,
            info = item.info,
            label = item.label,
            description = item.description,
            weight = item.weight,
            type = item.type,
            unique = item.unique,
            useable = item.useable,
            image = item.image,
            slot = targetSlot
        }
        inventory.items[targetSlot] = newItem
    end
    
    return true
end

function SaveOtherInventory(id, type, inventory)
    if type == "stash" then
        MySQL.Async.execute('INSERT INTO stashitems (stash, items) VALUES (?, ?) ON DUPLICATE KEY UPDATE items = ?', 
            {id, json.encode(inventory.items), json.encode(inventory.items)})
    end
end

-- Clean up drops
CreateThread(function()
    while true do
        Wait(60000) -- Check every minute
        local currentTime = os.time()
        for id, drop in pairs(Drops) do
            if currentTime - drop.time > Config.DropDespawnTime then
                Drops[id] = nil
            end
        end
    end
end)

-- Exports
exports('AddItem', function(source, item, amount, info, slot)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return false end
    
    local itemInfo = QBCore.Shared.Items[item]
    if not itemInfo then return false end
    
    local items = Player.PlayerData.items
    local weight = GetTotalWeight(items) + (itemInfo.weight * amount)
    
    if weight > Config.MaxInventoryWeight then
        return false
    end
    
    local targetSlot = slot or GetFirstEmptySlot(items)
    if not targetSlot then return false end
    
    local newItem = {
        name = item,
        amount = amount,
        info = info or {},
        label = itemInfo.label,
        description = itemInfo.description,
        weight = itemInfo.weight,
        type = itemInfo.type,
        unique = itemInfo.unique,
        useable = itemInfo.useable,
        image = itemInfo.image,
        slot = targetSlot
    }
    
    items[targetSlot] = newItem
    Player.Functions.SetPlayerData("items", items)
    TriggerClientEvent('qb-inventory:client:updateInventory', source, items)
    TriggerClientEvent('qb-inventory:client:updateHotbar', source, GetHotbarItems(items))
    
    return true
end)

exports('RemoveItem', function(source, item, amount, slot)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return false end
    
    local items = Player.PlayerData.items
    
    if slot then
        local slotItem = items[slot]
        if slotItem and slotItem.name == item then
            slotItem.amount = slotItem.amount - amount
            if slotItem.amount <= 0 then
                items[slot] = nil
            end
        end
    else
        for i, slotItem in pairs(items) do
            if slotItem and slotItem.name == item then
                slotItem.amount = slotItem.amount - amount
                if slotItem.amount <= 0 then
                    items[i] = nil
                end
                break
            end
        end
    end
    
    Player.Functions.SetPlayerData("items", items)
    TriggerClientEvent('qb-inventory:client:updateInventory', source, items)
    TriggerClientEvent('qb-inventory:client:updateHotbar', source, GetHotbarItems(items))
    
    return true
end)

exports('HasItem', function(source, item, amount)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return false end
    
    amount = amount or 1
    local items = Player.PlayerData.items
    
    for _, slotItem in pairs(items) do
        if slotItem and slotItem.name == item and slotItem.amount >= amount then
            return true
        end
    end
    
    return false
end)

exports('GetItemCount', function(source, item)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return 0 end
    
    local count = 0
    local items = Player.PlayerData.items
    
    for _, slotItem in pairs(items) do
        if slotItem and slotItem.name == item then
            count = count + slotItem.amount
        end
    end
    
    return count
end)

local player, distance = QBCore.Functions.GetClosestPlayer()
if player ~= -1 and distance < 3.0 then
    local targetServerId = GetPlayerServerId(player)
    TriggerServerEvent('qb-inventory:server:openPlayerInventory', targetServerId)
end
