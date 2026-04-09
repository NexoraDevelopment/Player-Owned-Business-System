RegisterCommand('managebusiness', function()
    local rows = lib.callback.await('nexora_business:adminGetData', false)
    if not rows then
        lib.notify({ type = 'error', description = 'You do not have permission to do that.' })
        return
    end
    SendNUIMessage({ type = 'openAdmin', businesses = rows, types = Config.BusinessTypes })
    OpenNUI()
end, false)

CreateThread(function()
    while true do
        Wait(0)
        if NUI_Open and not PickMode and IsControlJustPressed(0, 322) then
            CloseNUI()
        end
    end
end)

RegisterNUICallback('closePanel', function(_, callback)
    CloseNUI()
    callback('ok')
end)

RegisterNUICallback('buyItem', function(data, callback)
    local success, result = lib.callback.await('nexora_business:buyItem', false, data.businessId, data.itemName, data.qty, data.method)
    callback({ ok = success, result = result })
end)

RegisterNUICallback('refreshManage', function(data, callback)
    local manageData = lib.callback.await('nexora_business:getManageData', false, data.businessId)
    if manageData then
        local inv = lib.callback.await('nexora_business:getDepositableItems', false, data.businessId)
        manageData.inventory = inv or {}
        manageData.configItems = Config.Items
    end
    callback(manageData or {})
end)

RegisterNUICallback('depositStock', function(data, callback)
    local success = lib.callback.await('nexora_business:depositStock', false, data.businessId, data.deposits)
    callback({ ok = success })
end)

RegisterNUICallback('removeStock', function(data, callback)
    local success, result = lib.callback.await('nexora_business:removeStock', false, data.businessId, data.itemName, data.qty)
    callback({ ok = success, result = result })
end)

RegisterNUICallback('withdrawEarnings', function(data, callback)
    local success = lib.callback.await('nexora_business:withdrawEarnings', false, data.businessId, data.amount)
    callback({ ok = success })
end)

RegisterNUICallback('hireEmployee', function(data, callback)
    local success, error = lib.callback.await('nexora_business:hireEmployee', false, data.businessId, data.targetId)
    callback({ ok = success, err = error })
end)

RegisterNUICallback('fireEmployee', function(data, callback)
    local success = lib.callback.await('nexora_business:fireEmployee', false, data.businessId, data.employeeId)
    callback({ ok = success })
end)

RegisterNUICallback('toggleEmployeeWage', function(data, callback)
    local success = lib.callback.await('nexora_business:toggleEmployeeWage', false, data.businessId, data.employeeId, data.enabled)
    callback({ ok = success })
end)

RegisterNUICallback('setEmployeeWage', function(data, callback)
    local success = lib.callback.await('nexora_business:setEmployeeWage', false, data.businessId, data.employeeId, data.amount)
    callback({ ok = success })
end)

RegisterNUICallback('updateSettings', function(data, callback)
    local success = lib.callback.await('nexora_business:updateSettings', false, data.businessId, data.settings)
    callback({ ok = success })
end)

RegisterNUICallback('adminCreateBusiness', function(data, callback)
    local success, business = lib.callback.await('nexora_business:adminCreateBusiness', false, data)
    callback({ ok = success, business = business })
end)

RegisterNUICallback('adminDeleteBusiness', function(data, callback)
    local success = lib.callback.await('nexora_business:adminDeleteBusiness', false, data.businessId)
    callback({ ok = success })
end)

RegisterNUICallback('purchaseBusiness', function(data, callback)
    local success, error = lib.callback.await('nexora_business:purchaseBusiness', false, data.businessId, data.method)
    callback({ ok = success, err = error })
end)

RegisterNUICallback('sellToServer', function(data, callback)
    local success, result = lib.callback.await('nexora_business:sellToServer', false, data.businessId)
    callback({ ok = success, result = result })
end)

RegisterNUICallback('setForSale', function(data, callback)
    local success = lib.callback.await('nexora_business:setForSale', false, data.businessId, data.forSale, data.salePrice)
    callback({ ok = success })
end)

RegisterNUICallback('updateItemPrice', function(data, callback)
    local success = lib.callback.await('nexora_business:updateItemPrice', false, data.businessId, data.itemName, data.price)
    callback({ ok = success })
end)