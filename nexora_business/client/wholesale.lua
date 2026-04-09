local supplierPed = nil
local supplierBlip = nil
local supplierSpawning = false
local Target = exports.ox_target

local STREAM_DIST = Config.PedStreamDistance

local function SpawnSupplierBlip()
    if supplierBlip and DoesBlipExist(supplierBlip) then return end
    local config = Config.Wholesale
    if not config.blip.enabled then return end

    local blip = AddBlipForCoord(config.coords.x, config.coords.y, config.coords.z)
    SetBlipSprite(blip, config.blip.sprite)
    SetBlipColour(blip, config.blip.color)
    SetBlipScale(blip, config.blip.scale)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString(config.blip.label)
    EndTextCommandSetBlipName(blip)
    supplierBlip = blip
end

local function SpawnSupplier()
    if supplierPed and DoesEntityExist(supplierPed) then return end
    if supplierSpawning then return end
    supplierSpawning = true

    local config = Config.Wholesale
    local coords = config.coords
    local model = joaat(config.pedModel)

    if not IsModelValid(model) then
        supplierSpawning = false
        return
    end

    RequestModel(model)
    local deadline = GetGameTimer() + 15000
    while not HasModelLoaded(model) do
        Wait(50)
        if GetGameTimer() > deadline then
            SetModelAsNoLongerNeeded(model)
            supplierSpawning = false
            return
        end
    end


    local playerCoords = GetEntityCoords(PlayerPedId())
    if #(playerCoords - vector3(coords.x, coords.y, coords.z)) > STREAM_DIST then
        SetModelAsNoLongerNeeded(model)
        supplierSpawning = false
        return
    end

    supplierPed = CreatePed(4, model, coords.x, coords.y, coords.z - 1.0, coords.w, false, true)
    SetModelAsNoLongerNeeded(model)

    if not DoesEntityExist(supplierPed) or supplierPed == 0 then
        supplierPed = nil
        supplierSpawning = false
        return
    end

    SetBlockingOfNonTemporaryEvents(supplierPed, true)
    FreezeEntityPosition(supplierPed, true)
    SetEntityInvincible(supplierPed, true)
    TaskStartScenarioInPlace(supplierPed, 'WORLD_HUMAN_CLIPBOARD', 0, true)

    Target:addSphereZone({
        coords = vector3(coords.x, coords.y, coords.z),
        radius = config.zoneRadius,
        name = config.zoneName,
        options = {
            {
                name = 'nexora_wholesale_open',
                icon = 'fa-solid fa-boxes-stacked',
                label = 'Wholesale Supplier',
                distance = config.zoneRadius,
                onSelect = function()
                    local data = lib.callback.await('nexora_business:getWholesaleData', false)
                    if not data or #data.ownedTypes == 0 then
                        lib.notify({ type = 'error', description = 'You must own a business to use the supplier.' })
                        return
                    end
                    local cash, bank = GetPlayerWallet()
                    SendNUIMessage({
                        type = 'openWholesale',
                        ownedTypes = data.ownedTypes,
                        businesses = data.businesses,
                        items = Config.Items,
                        wallet = cash,
                        bank = bank
                    })
                    OpenNUI()
                end
            }
        }
    })

    supplierSpawning = false
end

local function DespawnSupplier()
    if supplierPed and DoesEntityExist(supplierPed) then
        DeleteEntity(supplierPed)
    end
    supplierPed = nil
    Target:removeZone(Config.Wholesale.zoneName)
end

CreateThread(function()
    SpawnSupplierBlip()

    local coords = Config.Wholesale.coords
    local supplierCoords = vector3(coords.x, coords.y, coords.z)

    while true do
        Wait(500)
        local dist = #(GetEntityCoords(PlayerPedId()) - supplierCoords)

        if not supplierPed and not supplierSpawning and dist <= STREAM_DIST then
            CreateThread(SpawnSupplier)
        elseif supplierPed and dist > STREAM_DIST then
            DespawnSupplier()
        end
    end
end)

RegisterNUICallback('wholesaleBuy', function(data, callback)
    local success, result = lib.callback.await('nexora_business:wholesaleBuy', false, data.businessId, data.items, data.method)
    callback({ ok = success, result = result })
end)