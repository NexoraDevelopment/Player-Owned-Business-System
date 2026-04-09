Config = {}

Config.AdminGroups = { 'admin', 'superadmin' }
Config.SellRefundPercent = 0.67

-- Maximum distance at which business/wholesale peds are streamed in or out.
-- Keeping this low avoids spawning dozens of peds the player will never interact with.
Config.PedStreamDistance = 50.0

Config.Blips = {
    ['YouTool'] = { sprite = 52, color = 5, scale = 0.65, label = 'YouTool' },
    ['Food Shop'] = { sprite = 93, color = 46, scale = 0.65, label = 'Food Shop' },
    ['Drink Shop'] = { sprite = 74, color = 38, scale = 0.65, label = 'Drink Shop' },
    ['Weapon Shop'] = { sprite = 110, color = 6, scale = 0.65, label = 'Weapon Shop' }
}

Config.Wholesale = {
    coords = vector4(2681.1133, 3508.0647, 53.3037, 62.9013),
    pedModel = 'mp_m_shopkeep_01',
    zoneRadius = 2.0,
    zoneName = 'nexora_wholesale_supplier',
    blip = {
        enabled = true,
        sprite = 478,
        color = 5,
        scale = 0.65,
        label = 'Wholesale Supplier'
    }
}

Config.BusinessTypes = {
    ['YouTool'] = {
        label = 'YouTool',
        icon = 'fa-wrench',
        ped = 's_m_y_construct_01',
        allowedCategories = { ['Tools'] = true, ['Paint'] = true, ['Electrical'] = true, ['Safety'] = true }
    },
    ['Food Shop'] = {
        label = 'Food Shop',
        icon = 'fa-utensils',
        ped = 'a_f_m_beach_01',
        allowedCategories = { ['Food'] = true }
    },
    ['Drink Shop'] = {
        label = 'Drink Shop',
        icon = 'fa-mug-hot',
        ped = 'a_f_m_beach_01',
        allowedCategories = { ['Drinks'] = true }
    },
    ['Weapon Shop'] = {
        label = 'Weapon Shop',
        icon = 'fa-crosshairs',
        ped = 'mp_m_shopkeep_01',
        allowedCategories = { ['Weapons'] = true, ['Ammo'] = true }
    }
}

--[[
    Config.Items  defines every purchasable item across all business types.

    Fields:
      name          the ox_inventory item name (must match exactly)
      label         display name shown in the shop UI
      price         base retail price players pay when buying from the shop
      category      groups items in the UI; must match an allowedCategories key in the matching BusinessType or the item won't appear there
      icon          Font Awesome icon class shown next to the item in the UI (removed feature)
      businessType  which business type sells this item; must match a key in Config.BusinessTypes exactly (e.g. 'YouTool', 'Food Shop')

    To add a new item: copy any existing entry, change the fields, and make sure
    the businessType and category exist in Config.BusinessTypes.allowedCategories.
]]

Config.Items = {
    { name = 'advancedkit', label = 'Advanced kit', price = 85, category = 'Tools', icon = 'fa-solid fa-hammer', businessType = 'YouTool' },
    { name = 'manual_gearbox', label = 'Manual gearbox', price = 120, category = 'Tools', icon = 'fa-solid fa-screwdriver', businessType = 'YouTool' },
    { name = 'performance_part', label = 'Performance part', price = 450, category = 'Tools', icon = 'fa-solid fa-bore-hole', businessType = 'YouTool' },
    { name = 'tyre_replacement', label = 'Tyre replacement', price = 95, category = 'Tools', icon = 'fa-solid fa-wrench', businessType = 'YouTool' },
    { name = 'air_filter', label = 'Air filter', price = 35, category = 'Tools', icon = 'fa-solid fa-ruler', businessType = 'YouTool' },
    { name = 'drift_tuning_kit', label = 'Drift tuning kit', price = 55, category = 'Tools', icon = 'fa-solid fa-ruler-horizontal', businessType = 'YouTool' },
    { name = 'duct_tape', label = 'Duct tape', price = 65, category = 'Tools', icon = 'fa-solid fa-gear', businessType = 'YouTool' },
    { name = 'engine_oil', label = 'Engine oil', price = 45, category = 'Paint', icon = 'fa-solid fa-fill-drip', businessType = 'YouTool' },
    { name = 'burger', label = 'Burger', price = 12, category = 'Food', icon = 'fa-solid fa-burger', businessType = 'Food Shop' },
    { name = 'burger_chicken', label = 'Burger chicken', price = 8, category = 'Food', icon = 'fa-solid fa-hotdog', businessType = 'Food Shop' },
    { name = 'ecola', label = 'Ecola', price = 15, category = 'Food', icon = 'fa-solid fa-pizza-slice', businessType = 'Food Shop' },
    { name = 'ecola_light', label = 'Ecola light', price = 10, category = 'Food', icon = 'fa-solid fa-utensils', businessType = 'Food Shop' },
    { name = 'fries', label = 'fries', price = 5, category = 'Food', icon = 'fa-solid fa-circle', businessType = 'Food Shop' },
    { name = 'pizza_ham_box', label = 'Pizza ham box', price = 4, category = 'Food', icon = 'fa-solid fa-bag-shopping', businessType = 'Food Shop' },
    { name = 'water', label = 'Water Bottle', price = 3, category = 'Drinks', icon = 'fa-solid fa-bottle-water', businessType = 'Drink Shop' },
    { name = 'ecola', label = 'Ecola', price = 5, category = 'Drinks', icon = 'fa-solid fa-wine-bottle', businessType = 'Drink Shop' },
    { name = 'ecola_light', label = 'ecola_light', price = 8, category = 'Drinks', icon = 'fa-solid fa-mug-hot', businessType = 'Drink Shop' },
    { name = 'weapon_assaultrifle', label = 'Assault Rifle', price = 9500, category = 'Weapons', icon = 'fa-solid fa-gun', businessType = 'Weapon Shop' },
    { name = 'weapon_carbinerifle', label = 'Carbine Rifle', price = 11000, category = 'Weapons', icon = 'fa-solid fa-gun', businessType = 'Weapon Shop' },
    { name = 'weapon_microsmg', label = 'Micro SMG', price = 5000, category = 'Weapons', icon = 'fa-solid fa-gun', businessType = 'Weapon Shop' },
    { name = 'weapon_combatpistol', label = 'Combat Pistol', price = 3200, category = 'Weapons', icon = 'fa-solid fa-gun', businessType = 'Weapon Shop' },
    { name = 'weapon_revolver', label = 'Heavy Revolver', price = 3800, category = 'Weapons', icon = 'fa-solid fa-gun', businessType = 'Weapon Shop' },
    { name = 'weapon_combatshotgun', label = 'Combat Shotgun', price = 7000, category = 'Weapons', icon = 'fa-solid fa-gun', businessType = 'Weapon Shop' },
    { name = 'weapon_sniperrifle', label = 'Sniper Rifle', price = 15000, category = 'Weapons', icon = 'fa-solid fa-gun', businessType = 'Weapon Shop' },
    { name = 'weapon_musket', label = 'Musket', price = 2200, category = 'Weapons', icon = 'fa-solid fa-gun', businessType = 'Weapon Shop' },
    { name = 'ammo-9', label = 'Ammo 9', price = 250, category = 'Ammo', icon = 'fa-solid fa-circle-dot', businessType = 'Weapon Shop' },
    { name = 'ammo-22', label = 'Ammo 22', price = 260, category = 'Ammo', icon = 'fa-solid fa-circle-dot', businessType = 'Weapon Shop' },
    { name = 'ammo-38', label = 'Ammo 38', price = 180, category = 'Ammo', icon = 'fa-solid fa-circle-dot', businessType = 'Weapon Shop' },
    { name = 'ammo-44', label = 'Ammo 44', price = 350, category = 'Ammo', icon = 'fa-solid fa-circle-dot', businessType = 'Weapon Shop' },
    { name = 'ammo-45', label = 'Ammo 45', price = 120, category = 'Ammo', icon = 'fa-solid fa-circle-dot', businessType = 'Weapon Shop' }
}

local itemMap = {}
for _, item in ipairs(Config.Items) do
    itemMap[item.name] = item
end
Config.ItemMap = itemMap