NUI_Open = false

function OpenNUI()
    NUI_Open = true
    SetNuiFocus(true, true)
end

function CloseNUI()
    NUI_Open = false
    SetNuiFocus(false, false)
    SendNUIMessage({ type = 'closeAll' })
end

function RotToDir(rotation)
    local z = math.rad(rotation.z)
    local x = math.rad(rotation.x)
    return vector3(
        -math.sin(z) * math.abs(math.cos(x)),
        math.cos(z) * math.abs(math.cos(x)),
        math.sin(x)
    )
end

function GetPlayerWallet()
    return lib.callback.await('nexora_business:getWallet', false)
end