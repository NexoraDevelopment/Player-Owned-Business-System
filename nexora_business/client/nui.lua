RegisterNUICallback('closePanel', function(_, cb)
    CloseNUI()
    cb('ok')
end)

RegisterNUICallback('buyItem', function(data, cb)
    local ok, result = lib.callback.await('nexora_business:buyItem', false, data.businessId, data.itemName, data.qty, data.method)
    cb({ ok = ok, result = result })
end)

RegisterNUICallback('refreshManage', function(data, cb)
    local manageData = lib.callback.await('nexora_business:getManageData', false, data.businessId)
    if manageData then
        local inv = lib.callback.await('nexora_business:getDepositableItems', false, data.businessId)
        manageData.inventory   = inv or {}
        manageData.configItems = Config.Items
    end
    cb(manageData or {})
end)

RegisterNUICallback('depositStock', function(data, cb)
    local ok = lib.callback.await('nexora_business:depositStock', false, data.businessId, data.deposits)
    cb({ ok = ok })
end)

RegisterNUICallback('removeStock', function(data, cb)
    local ok, result = lib.callback.await('nexora_business:removeStock', false, data.businessId, data.itemName, data.qty)
    cb({ ok = ok, result = result })
end)

RegisterNUICallback('withdrawEarnings', function(data, cb)
    local ok = lib.callback.await('nexora_business:withdrawEarnings', false, data.businessId, data.amount)
    cb({ ok = ok })
end)

RegisterNUICallback('hireEmployee', function(data, cb)
    local ok, err = lib.callback.await('nexora_business:hireEmployee', false, data.businessId, data.targetId)
    cb({ ok = ok, err = err })
end)

RegisterNUICallback('fireEmployee', function(data, cb)
    local ok = lib.callback.await('nexora_business:fireEmployee', false, data.businessId, data.employeeId)
    cb({ ok = ok })
end)

RegisterNUICallback('toggleEmployeeWage', function(data, cb)
    local ok = lib.callback.await('nexora_business:toggleEmployeeWage', false, data.businessId, data.employeeId, data.enabled)
    cb({ ok = ok })
end)

RegisterNUICallback('setEmployeeWage', function(data, cb)
    local ok = lib.callback.await('nexora_business:setEmployeeWage', false, data.businessId, data.employeeId, data.amount)
    cb({ ok = ok })
end)

RegisterNUICallback('updateSettings', function(data, cb)
    local ok = lib.callback.await('nexora_business:updateSettings', false, data.businessId, data.settings)
    cb({ ok = ok })
end)

RegisterNUICallback('transferOwnership', function(data, cb)
    local ok = lib.callback.await('nexora_business:transferOwnership', false, data.businessId, data.targetId)
    cb({ ok = ok })
end)

RegisterNUICallback('adminGetData', function(_, cb)
    local rows = lib.callback.await('nexora_business:adminGetData', false) cb({ businesses = rows or {} })
end)

RegisterNUICallback('adminCreateBusiness', function(data, cb)
    local ok, newBiz = lib.callback.await('nexora_business:adminCreateBusiness', false, data) cb({ ok = ok, business = newBiz })
end)

RegisterNUICallback('adminDeleteBusiness', function(data, cb)
    local ok = lib.callback.await('nexora_business:adminDeleteBusiness', false, data.businessId) cb({ ok = ok })
end)

RegisterNUICallback('purchaseBusiness', function(data, cb)
    local ok, err = lib.callback.await('nexora_business:purchaseBusiness', false, data.businessId, data.method) cb({ ok = ok, err = err })
end)

RegisterNUICallback('sellToServer', function(data, cb)
    local ok, result = lib.callback.await('nexora_business:sellToServer', false, data.businessId) cb({ ok = ok, result = result })
end)

RegisterNUICallback('setForSale', function(data, cb)
    local ok = lib.callback.await('nexora_business:setForSale', false, data.businessId, data.forSale, data.salePrice)
    cb({ ok = ok })
end)

RegisterNUICallback('updateItemPrice', function(data, cb)
    local ok = lib.callback.await('nexora_business:updateItemPrice', false, data.businessId, data.itemName, data.price)
    cb({ ok = ok })
end)