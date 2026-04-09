Businesses = {}
SpawnedPeds = {}
SpawnedBlips = {}
local Target = exports.ox_target

local STREAM_DIST = Config.PedStreamDistance

local function CreateBusinessBlip(business)
    if not business.target_x then return end
    local config = Config.Blips[business.type]
    if not config then return end

    local blip = AddBlipForCoord(business.target_x, business.target_y, business.target_z)
    SetBlipSprite(blip, config.sprite)
    SetBlipColour(blip, config.color)
    SetBlipScale(blip, config.scale)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString(business.name)
    EndTextCommandSetBlipName(blip)
    SpawnedBlips[business.id] = blip
end

local function RemoveBusinessBlip(businessId)
    local blip = SpawnedBlips[businessId]
    if blip and DoesBlipExist(blip) then
        RemoveBlip(blip)
    end
    SpawnedBlips[businessId] = nil
end

local function IsUnowned(business)
    return not business.owner_identifier or business.owner_identifier == ''
end

local function IsForSale(business)
    return business.for_sale == 1 or business.for_sale == true
end

local function IsLocalOwner(business)
    if not business.owner_identifier then return false end
    local data = ESX.GetPlayerData()
    if not data then return false end
    return data.identifier:match(':(.+)$') or data.identifier == business.owner_identifier:match(':(.+)$') or business.owner_identifier
end

local function BuildShopOptions(business)
    local options = {}
    local unowned = IsUnowned(business)

    if unowned or business.is_open == 1 or business.is_open == true then
        options[#options + 1] = {
            name = ('shop_browse_%d'):format(business.id),
            icon = 'fa-solid fa-store',
            label = ('Browse %s'):format(business.name),
            distance = 2.5,
            onSelect = function()
                local data = lib.callback.await('nexora_business:getShopData', false, business.id)
                if not data then
                    lib.notify({ type = 'error', description = 'This shop is currently closed.' })
                    return
                end
                local cash, bank = GetPlayerWallet()
                SendNUIMessage({
                    type = 'openShop',
                    business = data.business,
                    stock = data.stock,
                    infinite = data.infinite,
                    items = Config.Items,
                    wallet = cash,
                    bank = bank
                })
                OpenNUI()
            end
        }
    end

    return options
end

local function BuildPedOptions(business)
    local options = {}
    local unowned = IsUnowned(business)
    local forSale = IsForSale(business)
    local isOwner = IsLocalOwner(business)

    if unowned or (forSale and not isOwner) then
        local price = forSale and (business.sale_price or business.price or 0) or (business.price or 0)
        local label = forSale and 'Buy from Owner' or 'Purchase Business'

        options[#options + 1] = {
            name = ('shop_purchase_%d'):format(business.id),
            icon = 'fa-solid fa-money-bill-wave',
            label = label,
            distance = 2.5,
            onSelect = function()
                local cash, bank = GetPlayerWallet()
                SendNUIMessage({
                    type = 'openPurchase',
                    business = business,
                    price = price,
                    wallet = cash,
                    bank = bank,
                    forSale = forSale
                })
                OpenNUI()
            end
        }
    end

    if not unowned then
        options[#options + 1] = {
            name = ('shop_manage_%d'):format(business.id),
            icon = 'fa-solid fa-screwdriver-wrench',
            label = 'Manage Business',
            distance = 2.5,
            onSelect = function()
                local manageData = lib.callback.await('nexora_business:getManageData', false, business.id)
                if not manageData then
                    lib.notify({ type = 'error', description = 'You are not authorised to manage this business.' })
                    return
                end
                local inv = lib.callback.await('nexora_business:getDepositableItems', false, business.id)
                manageData.inventory = inv or {}
                manageData.configItems = Config.Items
                SendNUIMessage({ type = 'openManage', data = manageData })
                OpenNUI()
            end
        }
    end

    return options
end

local function SpawnPed(business)
    if not business.ped_x then return end
    if SpawnedPeds[business.id] then return end

    local typeConfig = Config.BusinessTypes[business.type]
    if not typeConfig then return end

    local model = joaat(typeConfig.ped)
    if not IsModelValid(model) then return end

    RequestModel(model)
    local deadline = GetGameTimer() + 15000
    while not HasModelLoaded(model) do
        Wait(50)
        if GetGameTimer() > deadline then
            SetModelAsNoLongerNeeded(model)
            return
        end
    end

    local playerCoords = GetEntityCoords(PlayerPedId())
    if #(playerCoords - vector3(business.ped_x, business.ped_y, business.ped_z)) > STREAM_DIST then
        SetModelAsNoLongerNeeded(model)
        return
    end

    local ped = CreatePed(4, model, business.ped_x, business.ped_y, business.ped_z - 1.0, business.ped_h or 0.0, false, true)
    SetModelAsNoLongerNeeded(model)

    if not DoesEntityExist(ped) or ped == 0 then return end

    SetBlockingOfNonTemporaryEvents(ped, true)
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    TaskStartScenarioInPlace(ped, 'WORLD_HUMAN_STAND_IMPATIENT', 0, true)
    SpawnedPeds[business.id] = ped

    if business.target_x then
        local shopOptions = BuildShopOptions(business)
        if #shopOptions > 0 then
            Target:addSphereZone({
                coords = vector3(business.target_x, business.target_y, business.target_z),
                radius = 1.5,
                name = ('nexora_biz_shop_%d'):format(business.id),
                options = shopOptions
            })
        end
    end

    local pedOptions = BuildPedOptions(business)
    if #pedOptions > 0 then
        Target:addSphereZone({
            coords = vector3(business.ped_x, business.ped_y, business.ped_z),
            radius = 1.5,
            name = ('nexora_biz_ped_%d'):format(business.id),
            options = pedOptions
        })
    end
end

local function DespawnPed(businessId)
    local ped = SpawnedPeds[businessId]
    if ped and DoesEntityExist(ped) then
        DeleteEntity(ped)
    end
    Target:removeZone(('nexora_biz_shop_%d'):format(businessId))
    Target:removeZone(('nexora_biz_ped_%d'):format(businessId))
    SpawnedPeds[businessId] = nil
end

local spawning = {}

CreateThread(function()
    while true do
        Wait(500)
        local playerCoords = GetEntityCoords(PlayerPedId())

        for id, business in pairs(Businesses) do
            if business.ped_x then
                local dist = #(playerCoords - vector3(business.ped_x, business.ped_y, business.ped_z))

                if not SpawnedPeds[id] and not spawning[id] and dist <= STREAM_DIST then
                    spawning[id] = true
                    CreateThread(function()
                        SpawnPed(business)
                        spawning[id] = nil
                    end)
                elseif SpawnedPeds[id] and dist > STREAM_DIST then
                    DespawnPed(id)
                end
            end
        end
    end
end)

function SetupBusiness(business)
    Businesses[business.id] = business
    CreateBusinessBlip(business)
end

function TeardownBusiness(businessId)
    DespawnPed(businessId)
    RemoveBusinessBlip(businessId)
    Businesses[businessId] = nil
    spawning[businessId] = nil
end

function RefreshBusinessTargets(businessId)
    local business = Businesses[businessId]
    if not business then return end
    DespawnPed(businessId)
end

RegisterNetEvent('nexora_business:syncBusinesses', function(list)
    for id in pairs(Businesses) do TeardownBusiness(id) end
    for i = 1, #list do SetupBusiness(list[i]) end
end)

RegisterNetEvent('nexora_business:addBusiness', function(business)
    SetupBusiness(business)
end)

RegisterNetEvent('nexora_business:removeBusiness', function(businessId)
    TeardownBusiness(businessId)
end)

RegisterNetEvent('nexora_business:updateBusiness', function(business)
    TeardownBusiness(business.id)
    SetupBusiness(business)
end)

RegisterNetEvent('nexora_business:setOpenStatus', function(businessId, isOpen)
    local business = Businesses[businessId]
    if not business then return end
    business.is_open = isOpen
    RefreshBusinessTargets(businessId)
end)

RegisterNetEvent('nexora_business:notify', function(notifyType, message)
    lib.notify({ type = notifyType, description = message })
end)