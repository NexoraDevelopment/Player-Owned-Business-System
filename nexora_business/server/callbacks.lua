lib.callback.register('nexora_business:getWallet', function(source)
    local player = ESX.GetPlayerFromId(source)
    if not player then return 0, 0 end
    return player.getMoney(), player.getAccount('bank').money
end)

lib.callback.register('nexora_business:getShopData', function(source, businessId)
    local business = Cache.Get(businessId)
    if not business then return nil end

    local unowned = not business.owner_identifier or business.owner_identifier == ''
    if not unowned and not business.is_open or business.is_open == 0 then return nil end

    local stock = {}
    if not unowned then
        stock = MySQL.query.await('SELECT * FROM business_stock WHERE business_id = ?', { businessId }) or {}
    end

    return { business = business, stock = stock, infinite = unowned }
end)

lib.callback.register('nexora_business:buyItem', function(source, businessId, itemName, quantity, method)
    local player = ESX.GetPlayerFromId(source)
    if not player then return false, 'not_found' end

    quantity = math.floor(tonumber(quantity) or 0)
    if quantity <= 0 or quantity > 100 then return false, 'invalid_qty' end
    if method ~= 'cash' and method ~= 'bank' then return false, 'invalid_method' end

    local business = Cache.Get(businessId)
    if not business then return false, 'not_found' end

    local unowned = not business.owner_identifier or business.owner_identifier == ''
    if not unowned and (business.is_open == 0 or business.is_open == false) then return false, 'closed' end

    local config = GetItemConfig(itemName)
    if not config then return false, 'no_item' end

    local unitPrice = config.price
    local total = unitPrice * quantity

    if not unowned then
        local stock = MySQL.query.await('SELECT quantity, price FROM business_stock WHERE business_id = ? AND item_name = ?', { businessId, itemName })
        if not stock or #stock == 0 then return false, 'no_stock' end
        if stock[1].quantity < quantity then return false, 'insufficient_stock' end
        total = stock[1].price * quantity
    end

    if not GetItemTotalWeight(source, itemName, quantity) then return false, 'overweight' end
    if not TakePayment(player, method, total) then return false, 'no_money' end
    
    AddItem(source, itemName, quantity)

    if not unowned then
        MySQL.update('UPDATE business_stock SET quantity = quantity - ? WHERE business_id = ? AND item_name = ?', { quantity, businessId, itemName })
        MySQL.update('UPDATE businesses SET earnings = earnings + ? WHERE id = ?', { total, businessId })
        Cache.UpdateField(businessId, 'earnings', (business.earnings or 0) + total)
    end

    MySQL.insert('INSERT INTO business_sales (business_id, item_name, quantity, total) VALUES (?, ?, ?, ?)', { businessId, itemName, quantity, total })
    return true, total
end)

lib.callback.register('nexora_business:getManageData', function(source, businessId)
    local authorized, isOwner = IsAuthorized(source, businessId)
    if not authorized then return nil end

    local business = Cache.Get(businessId)
    local stock = MySQL.query.await('SELECT * FROM business_stock WHERE business_id = ?', { businessId }) or {}
    local employees = MySQL.query.await('SELECT * FROM business_employees WHERE business_id = ?', { businessId }) or {}
    local sales = MySQL.query.await('SELECT COALESCE(SUM(total), 0) AS total FROM business_sales WHERE business_id = ? AND DATE(sold_at) = CURDATE()', { businessId })

    local totalStock = 0
    for i = 1, #stock do
        totalStock = totalStock + stock[i].quantity
    end

    return {
        business = business,
        stock = stock,
        employees = employees,
        todaySales = sales and sales[1] and sales[1].total or 0,
        totalStock = totalStock,
        isOwner = isOwner,
        sellRefundPercent = Config.SellRefundPercent or 0.5
    }
end)

lib.callback.register('nexora_business:getDepositableItems', function(source, businessId)
    if not IsAuthorized(source, businessId) then return {} end

    local business = Cache.Get(businessId)
    if not business then return {} end

    local typeConfig = Config.BusinessTypes[business.type]
    if not typeConfig then return {} end

    local allowed = typeConfig.allowedCategories
    local inventory = GetInventoryItems(source)
    local grouped = {}
    local result = {}

    for i = 1, #inventory do
        local item = inventory[i]
        if not item then goto continue end
        local count = item.count or item.amount or 0
        if count > 0 and item.name then
            local key = item.name:lower()
            local config = GetItemConfig(key)
            if config and allowed[config.category] then
                if grouped[key] then
                    grouped[key].count = grouped[key].count + count
                else
                    grouped[key] = {
                        name = key,
                        label = config.label,
                        count = count,
                        price = config.price,
                        category = config.category
                    }
                    result[#result + 1] = grouped[key]
                end
            end
        end
        ::continue::
    end

    return result
end)

lib.callback.register('nexora_business:depositStock', function(source, businessId, deposits)
    if not IsAuthorized(source, businessId) then return false end

    local business = Cache.Get(businessId)
    if not business then return false end

    local typeConfig = Config.BusinessTypes[business.type]
    if not typeConfig then return false end

    local allowed = typeConfig.allowedCategories

    for i = 1, #deposits do
        local deposit = deposits[i]
        local quantity = math.floor(tonumber(deposit.qty) or 0)
        if quantity > 0 then
            local itemName = deposit.itemName and deposit.itemName:lower()
            if itemName then
                local config = GetItemConfig(itemName)
                if config and config.businessType == business.type and allowed[config.category] then
                    local playerCount = GetItemCount(source, itemName)
                    if playerCount >= quantity then
                        local current = MySQL.query.await('SELECT quantity FROM business_stock WHERE business_id = ? AND item_name = ?', { businessId, itemName })
                        local currentQty = current and current[1] and current[1].quantity or 0
                        local toAdd = math.min(quantity, 9999 - currentQty)
                        if toAdd > 0 then
                            RemoveItem(source, itemName, toAdd)
                            MySQL.insert('INSERT INTO business_stock (business_id, item_name, quantity, price) VALUES (?, ?, ?, ?) ON DUPLICATE KEY UPDATE quantity = quantity + ?', { businessId, itemName, toAdd, config.price, toAdd })
                        end
                    end
                end
            end
        end
    end
    return true
end)

lib.callback.register('nexora_business:withdrawEarnings', function(source, businessId, amount)
    if not IsOwner(source, businessId) then return false end

    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return false end

    local rows = MySQL.query.await('SELECT earnings FROM businesses WHERE id = ?', { businessId })
    if not rows or #rows == 0 then return false end

    local liveEarnings = rows[1].earnings or 0
    if amount > liveEarnings then return false end

    local player = ESX.GetPlayerFromId(source)
    if not player then return false end

    MySQL.update('UPDATE businesses SET earnings = earnings - ? WHERE id = ?', { amount, businessId })
    Cache.UpdateField(businessId, 'earnings', liveEarnings - amount)
    player.addAccountMoney('bank', amount)
    return true
end)

lib.callback.register('nexora_business:removeStock', function(source, businessId, itemName, quantity)
    if not IsOwner(source, businessId) then return false, 'not_owner' end

    itemName = type(itemName) == 'string' and itemName:lower() or nil
    if not itemName or not GetItemConfig(itemName) then return false, 'invalid_item' end

    quantity = math.floor(tonumber(quantity) or 0)
    if quantity <= 0 then return false, 'invalid_qty' end

    local rows = MySQL.query.await('SELECT quantity FROM business_stock WHERE business_id = ? AND item_name = ?', { businessId, itemName })
    if not rows or #rows == 0 then return false, 'no_stock' end

    local current = rows[1].quantity
    local toGive = math.min(quantity, current)

    if not GetItemTotalWeight(source, itemName, toGive) then return false, 'overweight' end

    AddItem(source, itemName, toGive)

    if toGive >= current then
        MySQL.update('DELETE FROM business_stock WHERE business_id = ? AND item_name = ?', { businessId, itemName })
    else
        MySQL.update('UPDATE business_stock SET quantity = quantity - ? WHERE business_id = ? AND item_name = ?', { toGive, businessId, itemName })
    end

    return true, toGive
end)

lib.callback.register('nexora_business:updateSettings', function(source, businessId, settings)
    if not IsOwner(source, businessId) then return false end

    local allowed = { is_open = true, wages_enabled = true, wage_interval = true }
    local clauses = {}
    local params = {}

    for key, value in pairs(settings) do
        if allowed[key] then
            if key == 'is_open' or key == 'wages_enabled' then
                value = (value == true or value == 1) and 1 or 0
            elseif key == 'wage_interval' then
                value = math.max(5, math.min(1440, math.floor(tonumber(value) or 60)))
            end
            clauses[#clauses + 1] = ('`%s` = ?'):format(key)
            params[#params + 1] = value
        end
    end

    if #clauses == 0 then return false end

    params[#params + 1] = businessId
    MySQL.update('UPDATE businesses SET ' .. table.concat(clauses, ', ') .. ' WHERE id = ?', params)

    for key, value in pairs(settings) do
        if allowed[key] then
            Cache.UpdateField(businessId, key, value)
        end
    end

    if settings.is_open ~= nil then
        TriggerClientEvent('nexora_business:setOpenStatus', -1, businessId, settings.is_open == 1)
    end

    return true
end)

lib.callback.register('nexora_business:hireEmployee', function(source, businessId, targetId)
    if not IsOwner(source, businessId) then return false, 'not_owner' end

    local target = ESX.GetPlayerFromId(tonumber(targetId))
    if not target then return false, 'player_not_found' end

    local targetIdentifier = GetIdentifier(tonumber(targetId))
    local targetName = GetPlayerName(tonumber(targetId))
    local business = Cache.Get(businessId)

    if business and business.owner_identifier == targetIdentifier then return false, 'is_owner' end

    local existing = MySQL.query.await('SELECT id FROM business_employees WHERE business_id = ? AND identifier = ?', { businessId, targetIdentifier })
    if existing and #existing > 0 then return false, 'already_hired' end

    MySQL.insert('INSERT INTO business_employees (business_id, identifier, name) VALUES (?, ?, ?)', { businessId, targetIdentifier, targetName })
    TriggerClientEvent('nexora_business:notify', tonumber(targetId), 'success', ('You have been hired at %s!'):format(business.name))
    return true
end)

lib.callback.register('nexora_business:fireEmployee', function(source, businessId, employeeId)
    if not IsOwner(source, businessId) then return false end
    MySQL.update('DELETE FROM business_employees WHERE id = ? AND business_id = ?', { math.floor(tonumber(employeeId) or 0), businessId })
    return true
end)

lib.callback.register('nexora_business:toggleEmployeeWage', function(source, businessId, employeeId, enabled)
    if not IsOwner(source, businessId) then return false end
    MySQL.update('UPDATE business_employees SET wage_enabled = ? WHERE id = ? AND business_id = ?', { enabled and 1 or 0, math.floor(tonumber(employeeId) or 0), businessId })
    return true
end)

lib.callback.register('nexora_business:setEmployeeWage', function(source, businessId, employeeId, amount)
    if not IsOwner(source, businessId) then return false end
    amount = math.max(0, math.floor(tonumber(amount) or 0))
    MySQL.update('UPDATE business_employees SET wage = ? WHERE id = ? AND business_id = ?', { amount, math.floor(tonumber(employeeId) or 0), businessId })
    return true
end)

lib.callback.register('nexora_business:sellToServer', function(source, businessId)
    if not IsOwner(source, businessId) then return false, 'not_owner' end

    local business = Cache.Get(businessId)
    if not business then return false, 'not_found' end

    local refund = math.floor((business.price or 0) * (Config.SellRefundPercent or 0.5))
    local player = ESX.GetPlayerFromId(source)
    if not player then return false, 'not_found' end

    player.addAccountMoney('bank', refund)
    MySQL.update('UPDATE businesses SET owner_identifier = NULL, owner_name = NULL, earnings = 0, for_sale = 0, sale_price = 0 WHERE id = ?', { businessId })
    MySQL.update('DELETE FROM business_stock WHERE business_id = ?', { businessId })

    Cache.UpdateField(businessId, 'owner_identifier', nil)
    Cache.UpdateField(businessId, 'owner_name', nil)
    Cache.UpdateField(businessId, 'earnings', 0)
    Cache.UpdateField(businessId, 'for_sale', 0)
    Cache.UpdateField(businessId, 'sale_price', 0)

    TriggerClientEvent('nexora_business:updateBusiness', -1, Cache.Get(businessId))
    return true, refund
end)

lib.callback.register('nexora_business:setForSale', function(source, businessId, forSale, salePrice)
    if not IsOwner(source, businessId) then return false end

    local forSaleInt = (forSale == true or forSale == 1) and 1 or 0
    salePrice = math.max(0, math.floor(tonumber(salePrice) or 0))

    MySQL.update('UPDATE businesses SET for_sale = ?, sale_price = ? WHERE id = ?', { forSaleInt, salePrice, businessId })
    Cache.UpdateField(businessId, 'for_sale', forSaleInt)
    Cache.UpdateField(businessId, 'sale_price', salePrice)
    TriggerClientEvent('nexora_business:updateBusiness', -1, Cache.Get(businessId))
    return true
end)

lib.callback.register('nexora_business:purchaseBusiness', function(source, businessId, method)
    local business = Cache.Get(businessId)
    if not business then return false, 'not_found' end

    local unowned = not business.owner_identifier or business.owner_identifier == ''
    local forSale = (business.for_sale == 1 or business.for_sale == true) and not unowned
    if not unowned and not forSale then return false, 'not_for_sale' end

    if forSale and business.owner_identifier == GetIdentifier(source) then return false, 'own_business' end

    local price = forSale and (business.sale_price or 0) or (business.price or 0)
    local buyer = ESX.GetPlayerFromId(source)
    if not buyer then return false, 'not_found' end
    if not TakePayment(buyer, method, price) then return false, 'no_money' end

    local identifier = GetIdentifier(source)
    local name = GetPlayerName(source)

    if forSale then
        local oldOwner = business.owner_identifier
        local sellerOnline = false

        for _, playerId in ipairs(ESX.GetPlayers()) do
            if GetIdentifier(playerId) == oldOwner then
                local seller = ESX.GetPlayerFromId(playerId)
                if seller then
                    sellerOnline = true
                    seller.addAccountMoney('bank', price)
                    TriggerClientEvent('nexora_business:notify', playerId, 'success', ('Your business "%s" was sold for $%d!'):format(business.name, price))
                end
                break
            end
        end

        if not sellerOnline then
            MySQL.update('UPDATE accounts SET money = money + ? WHERE identifier = ? AND name = ?', { price, oldOwner, 'bank' })
        end

        MySQL.update('UPDATE businesses SET owner_identifier = ?, owner_name = ?, for_sale = 0, sale_price = 0 WHERE id = ?', { identifier, name, businessId })
    else
        MySQL.update('UPDATE businesses SET owner_identifier = ?, owner_name = ? WHERE id = ?', { identifier, name, businessId })
        MySQL.update('DELETE FROM business_stock WHERE business_id = ?', { businessId })
    end

    Cache.UpdateField(businessId, 'owner_identifier', identifier)
    Cache.UpdateField(businessId, 'owner_name', name)
    Cache.UpdateField(businessId, 'for_sale', 0)
    Cache.UpdateField(businessId, 'sale_price', 0)
    TriggerClientEvent('nexora_business:updateBusiness', -1, Cache.Get(businessId))
    TriggerClientEvent('nexora_business:notify', source, 'success', ('You are now the owner of %s!'):format(business.name))
    return true
end)

lib.callback.register('nexora_business:updateItemPrice', function(source, businessId, itemName, price)
    if not IsOwner(source, businessId) then return false end
    itemName = type(itemName) == 'string' and itemName:lower() or nil
    if not itemName then return false end
    price = math.max(0, math.floor(tonumber(price) or 0))
    MySQL.update('UPDATE business_stock SET price = ? WHERE business_id = ? AND item_name = ?', { price, businessId, itemName })
    return true
end)

lib.callback.register('nexora_business:adminGetData', function(source)
    if not IsAdmin(source) then return nil end
    return MySQL.query.await('SELECT * FROM businesses') or {}
end)

lib.callback.register('nexora_business:adminCreateBusiness', function(source, data)
    if not IsAdmin(source) then return false, nil end

    local id = MySQL.insert.await('INSERT INTO businesses (name, type, target_x, target_y, target_z, ped_x, ped_y, ped_z, ped_h, price) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)', {
        data.name, data.type, data.target_x, data.target_y, data.target_z,
        data.ped_x, data.ped_y, data.ped_z, data.ped_h or 0, data.price or 0
    })

    if not id then return false, nil end

    local rows = MySQL.query.await('SELECT * FROM businesses WHERE id = ?', { id })
    local newBusiness = rows and rows[1]

    if newBusiness then
        Cache.Set(id, newBusiness)
        TriggerClientEvent('nexora_business:addBusiness', -1, newBusiness)
    end

    return true, newBusiness
end)

lib.callback.register('nexora_business:adminDeleteBusiness', function(source, businessId)
    if not IsAdmin(source) then return false end
    MySQL.update('DELETE FROM businesses WHERE id = ?', { businessId })
    Cache.Remove(businessId)
    TriggerClientEvent('nexora_business:removeBusiness', -1, businessId)
    return true
end)

lib.callback.register('nexora_business:getWholesaleData', function(source)
    local identifier = GetIdentifier(source)
    local ownedTypes = {}
    local typeSet = {}
    local businesses = {}
    local index = 1

    Cache.Iterate(function(_, business)
        if business.owner_identifier == identifier then
            businesses[index] = { id = business.id, name = business.name, type = business.type }
            index = index + 1
            if not typeSet[business.type] then
                typeSet[business.type] = true
                ownedTypes[#ownedTypes + 1] = business.type
            end
        end
    end)

    if #ownedTypes == 0 then return { ownedTypes = {}, businesses = {} } end
    return { ownedTypes = ownedTypes, businesses = businesses }
end)

lib.callback.register('nexora_business:wholesaleBuy', function(source, businessId, items, method)
    if not IsOwner(source, businessId) then return false, 'not_owner' end

    local business = Cache.Get(businessId)
    if not business then return false, 'not_found' end
    if method ~= 'cash' and method ~= 'bank' then return false, 'invalid_method' end

    local player = ESX.GetPlayerFromId(source)
    if not player then return false, 'not_found' end

    local typeConfig = Config.BusinessTypes[business.type]
    if not typeConfig then return false, 'invalid_type' end

    local allowed = typeConfig.allowedCategories
    local validated = {}
    local total = 0

    for i = 1, #items do
        local item = items[i]
        local quantity = math.floor(tonumber(item.qty) or 0)
        if quantity > 0 then
            local itemName = type(item.name) == 'string' and item.name:lower() or nil
            if itemName then
                local config = GetItemConfig(itemName)
                if config and config.businessType == business.type and allowed[config.category] then
                    quantity = math.min(quantity, 100)
                    validated[#validated + 1] = { name = itemName, quantity = quantity }
                    total = total + config.price * quantity
                end
            end
        end
    end

    if #validated == 0 then return false, 'no_items' end

    for i = 1, #validated do
        if not GetItemTotalWeight(source, validated[i].name, validated[i].quantity) then
            return false, 'overweight'
        end
    end

    if not TakePayment(player, method, total) then return false, 'no_money' end

    for i = 1, #validated do
        AddItem(source, validated[i].name, validated[i].quantity)
    end

    return true, total
end)