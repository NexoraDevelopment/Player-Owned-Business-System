local SQL_TABLES = {
    [[CREATE TABLE IF NOT EXISTS `businesses` (
        `id` INT(11) NOT NULL AUTO_INCREMENT,
        `name` VARCHAR(100) NOT NULL,
        `type` VARCHAR(50) NOT NULL,
        `owner_identifier` VARCHAR(100) DEFAULT NULL,
        `owner_name` VARCHAR(100) DEFAULT NULL,
        `target_x` FLOAT DEFAULT NULL,
        `target_y` FLOAT DEFAULT NULL,
        `target_z` FLOAT DEFAULT NULL,
        `ped_x` FLOAT DEFAULT NULL,
        `ped_y` FLOAT DEFAULT NULL,
        `ped_z` FLOAT DEFAULT NULL,
        `ped_h` FLOAT DEFAULT 0,
        `price` DOUBLE DEFAULT 0,
        `earnings` DOUBLE DEFAULT 0,
        `is_open` TINYINT(1) DEFAULT 1,
        `wages_enabled` TINYINT(1) DEFAULT 1,
        `wage_interval` INT(11) DEFAULT 60,
        `max_stock` INT(11) DEFAULT 50,
        `for_sale` TINYINT(1) DEFAULT 0,
        `sale_price` DOUBLE DEFAULT 0,
        PRIMARY KEY (`id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]],
    [[CREATE TABLE IF NOT EXISTS `business_stock` (
        `id` INT(11) NOT NULL AUTO_INCREMENT,
        `business_id` INT(11) NOT NULL,
        `item_name` VARCHAR(100) NOT NULL,
        `quantity` INT(11) DEFAULT 0,
        `price` INT(11) NOT NULL,
        PRIMARY KEY (`id`),
        UNIQUE KEY `uq_biz_item` (`business_id`, `item_name`),
        CONSTRAINT `fk_stock_biz` FOREIGN KEY (`business_id`) REFERENCES `businesses` (`id`) ON DELETE CASCADE
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]],
    [[CREATE TABLE IF NOT EXISTS `business_employees` (
        `id` INT(11) NOT NULL AUTO_INCREMENT,
        `business_id` INT(11) NOT NULL,
        `identifier` VARCHAR(100) NOT NULL,
        `name` VARCHAR(100) NOT NULL,
        `role` VARCHAR(50) DEFAULT 'Employee',
        `wage` INT(11) DEFAULT 0,
        `wage_enabled` TINYINT(1) DEFAULT 0,
        `hired_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        PRIMARY KEY (`id`),
        UNIQUE KEY `uq_biz_emp` (`business_id`, `identifier`),
        CONSTRAINT `fk_emp_biz` FOREIGN KEY (`business_id`) REFERENCES `businesses` (`id`) ON DELETE CASCADE
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]],
    [[CREATE TABLE IF NOT EXISTS `business_sales` (
        `id` INT(11) NOT NULL AUTO_INCREMENT,
        `business_id` INT(11) NOT NULL,
        `item_name` VARCHAR(100) NOT NULL,
        `quantity` INT(11) NOT NULL,
        `total` DOUBLE NOT NULL,
        `sold_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        PRIMARY KEY (`id`),
        CONSTRAINT `fk_sales_biz` FOREIGN KEY (`business_id`) REFERENCES `businesses` (`id`) ON DELETE CASCADE
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4]]
}

AddEventHandler('onResourceStart', function(res)
    if res ~= GetCurrentResourceName() then return end
    SetTimeout(1000, function()
        MySQL.query("ALTER TABLE `businesses` ADD COLUMN IF NOT EXISTS `price` DOUBLE DEFAULT 0", {})
        MySQL.query("ALTER TABLE `businesses` ADD COLUMN IF NOT EXISTS `for_sale` TINYINT(1) DEFAULT 0", {})
        MySQL.query("ALTER TABLE `businesses` ADD COLUMN IF NOT EXISTS `sale_price` DOUBLE DEFAULT 0", {})

        local count = #SQL_TABLES
        for _, sql in ipairs(SQL_TABLES) do
            MySQL.query(sql, {}, function()
                count = count - 1
                if count == 0 then
                    Cache.Load(function()
                        local list = Cache.GetAll()
                        local players = GetPlayers()
                        for i = 1, #players do
                            TriggerClientEvent('nexora_business:syncBusinesses', tonumber(players[i]), list)
                        end
                    end)
                end
            end)
        end
    end)
end)

AddEventHandler('playerConnecting', function(_, _, deferrals)
    local src = source
    deferrals.defer()
    SetTimeout(1000, function()
        TriggerClientEvent('nexora_business:syncBusinesses', src, Cache.GetAll())
        deferrals.done()
    end)
end)

AddEventHandler('esx:playerLoaded', function(playerId)
    SetTimeout(2000, function()
        TriggerClientEvent('nexora_business:syncBusinesses', playerId, Cache.GetAll())
    end)
end)

RegisterNetEvent('nexora_business:notify', function() end)