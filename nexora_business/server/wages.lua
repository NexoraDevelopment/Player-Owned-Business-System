local GetPlayers = ESX.GetPlayers
local GetPlayerFromId = ESX.GetPlayerFromId

CreateThread(function()
    while true do
        Wait(60000)
        local currentTime = os.time()

        Cache.Iterate(function(businessId, business)
            if business.wages_enabled ~= 1 then return end

            local interval = (business.wage_interval or 60) * 60
            if not business._lastWage then business._lastWage = currentTime end
            if (currentTime - business._lastWage) < interval then return end

            business._lastWage = currentTime

            local employees = MySQL.query.await('SELECT identifier, wage FROM business_employees WHERE business_id = ? AND wage_enabled = 1 AND wage > 0', { businessId })
            if not employees or #employees == 0 then return end

            local earnings = MySQL.query.await('SELECT earnings FROM businesses WHERE id = ?', { businessId })
            local liveEarnings = earnings and earnings[1] and earnings[1].earnings or 0

            for i = 1, #employees do
                local employee = employees[i]
                if liveEarnings >= employee.wage then
                    liveEarnings = liveEarnings - employee.wage
                    MySQL.update('UPDATE businesses SET earnings = earnings - ? WHERE id = ?', { employee.wage, businessId })

                    local players = GetPlayers()
                    for j = 1, #players do
                        local playerId = players[j]
                        if GetIdentifier(playerId) == employee.identifier then
                            local empPlayer = GetPlayerFromId(playerId)
                            if empPlayer then
                                empPlayer.addAccountMoney('bank', employee.wage)
                                TriggerClientEvent('nexora_business:notify', playerId, 'success', ('Received $%d wage from %s'):format(employee.wage, business.name))
                            end
                            break
                        end
                    end
                end
            end

            Cache.UpdateField(businessId, 'earnings', liveEarnings)
        end)
    end
end)