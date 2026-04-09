PickMode = false

RegisterNUICallback('startPick', function(data, callback)
    callback('ok')
    SendNUIMessage({ type = 'pickHide' })
    SetNuiFocus(false, false)
    PickMode = true

    local field = data.field

    CreateThread(function()
        lib.showTextUI('[LMB] Click a location in the world | [ESC] Cancel', {
            position = 'bottom-center',
            icon = 'crosshairs'
        })

        while PickMode do
            Wait(0)

            if IsControlJustPressed(0, 24) then
                local camPos = GetGameplayCamCoords()
                local camRot = GetGameplayCamRot(2)
                local dir = RotToDir(camRot)
                local dest = camPos + dir * 200.0
                local ray = StartExpensiveSynchronousShapeTestLosProbe(camPos.x, camPos.y, camPos.z, dest.x, dest.y, dest.z, -1, PlayerPedId(), 4)
                local _, hit, hitCoords = GetShapeTestResult(ray)

                if hit == 1 then
                    PickMode = false
                    lib.hideTextUI()
                    SetNuiFocus(true, true)
                    SendNUIMessage({
                        type = 'pickResult',
                        field = field,
                        x = math.floor(hitCoords.x * 100) / 100,
                        y = math.floor(hitCoords.y * 100) / 100,
                        z = math.floor(hitCoords.z * 100) / 100,
                        h = math.floor(GetEntityHeading(PlayerPedId()) * 100) / 100
                    })
                end
            elseif IsControlJustPressed(0, 322) then
                PickMode = false
                lib.hideTextUI()
                SetNuiFocus(true, true)
                SendNUIMessage({ type = 'pickCancelled', field = field })
            end
        end
    end)
end)