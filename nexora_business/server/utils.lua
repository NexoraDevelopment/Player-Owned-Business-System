local oxInventory = exports.ox_inventory

function GetIdentifier(source)
    return GetPlayerIdentifier(source, 0)
end

function IsAdmin(source)
    local player = ESX.GetPlayerFromId(source)
    if not player then return false end
    local group = player.getGroup()
    for i = 1, #Config.AdminGroups do
        if group == Config.AdminGroups[i] then return true end
    end
    return false
end

function IsOwner(source, businessId)
    local business = Cache.Get(businessId)
    return business and business.owner_identifier == GetIdentifier(source)
end

function IsEmployee(identifier, businessId)
    local result = MySQL.query.await('SELECT 1 FROM business_employees WHERE business_id = ? AND identifier = ? LIMIT 1', { businessId, identifier })
    return result and #result > 0
end

function IsAuthorized(source, businessId)
    local identifier = GetIdentifier(source)
    local business = Cache.Get(businessId)
    if not business then return false, false end
    if business.owner_identifier == identifier then return true, true end
    return IsEmployee(identifier, businessId), false
end

function GetItemConfig(name)
    if not name then return nil end
    return Config.ItemMap[name:lower()]
end

function TakePayment(player, method, amount)
    if method == 'cash' then
        if player.getMoney() < amount then return false end
        player.removeMoney(amount)
        return true
    elseif method == 'bank' then
        if player.getAccount('bank').money < amount then return false end
        player.removeAccountMoney('bank', amount)
        return true
    end
    return false
end

function GetItemTotalWeight(source, item, count)
    return oxInventory:CanCarryItem(source, item, count)
end

function AddItem(source, item, count)
    return oxInventory:AddItem(source, item, count)
end

function RemoveItem(source, item, count)
    return oxInventory:RemoveItem(source, item, count)
end

function GetInventoryItems(source)
    return oxInventory:GetInventoryItems(source) or {}
end

function GetItemCount(source, item)
    return oxInventory:GetItemCount(source, item) or 0
end