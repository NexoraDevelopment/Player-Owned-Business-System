Cache = {}
local data = {}

function Cache.Load(callback)
    MySQL.query('SELECT * FROM businesses', {}, function(rows)
        data = {}
        for i = 1, #rows do
            local row = rows[i]
            data[row.id] = row
        end
        if callback then callback() end
    end)
end

function Cache.Get(id)
    return data[id]
end

function Cache.Set(id, row)
    data[id] = row
end

function Cache.Remove(id)
    data[id] = nil
end

function Cache.UpdateField(id, key, value)
    if data[id] then
        data[id][key] = value
    end
end

function Cache.GetAll()
    local result = {}
    local index = 1
    for _, v in pairs(data) do
        result[index] = v
        index = index + 1
    end
    return result
end

function Cache.Iterate(callback)
    for id, business in pairs(data) do
        callback(id, business)
    end
end