local QBCore = exports['qb-core']:GetCoreObject()
-- Unified server alert event. Use this in server-side code to notify police according to Config.DispatchSystem
RegisterNetEvent("zidanx-hostage:server:SendAlert", function(data)
    local src = source
    local players = QBCore.Functions.GetPlayers()
    local dispatch = Config and Config.DispatchSystem or "ORIGIN_DISPATCH"

    -- Build a standardized payload
    local payload = {
        title = data.title or "Hostage Situation",
        coords = data.coords or vector3(0.0,0.0,0.0),
        description = data.description or "",
        id = src
    }

    if dispatch == "ORIGIN_DISPATCH" then
        for i = 1, #players do
            local Player = QBCore.Functions.GetPlayer(players[i])
            if Player and Player.PlayerData.job and Player.PlayerData.job.name == "police" then
                TriggerClientEvent('origen-police:client:sendAlert', players[i], payload)
            end
        end

    elseif dispatch == "QB_DISPATCH" then
        local ok, _ = pcall(function()
            TriggerEvent('qb-dispatch:server:SendAlert', payload)
        end)
        if not ok then
            pcall(function() TriggerEvent('qb-dispatch:server:sendAlert', payload) end)
        end

    elseif dispatch == "OX_DISPATCH" then
        pcall(function()
            TriggerEvent('ox_dispatch:svNotify', payload)
        end)

    elseif dispatch == "CD_DISPATCH" then
        -- cd_dispatch expects special format
        pcall(function()
            TriggerEvent('cd_dispatch:AddNotification', {
                job_table = {'police'}, -- jobs to notify
                coords = payload.coords,
                title = payload.title,
                message = payload.description,
                flash = 0,
                unique_id = tostring(math.random(11111,99999)),
                blip = {
                    sprite = 161, scale = 1.2, colour = 3, flashes = false, text = payload.title
                },
                sound = 1
            })
        end)

    elseif dispatch == "PS_DISPATCH" then
        -- ps-dispatch export based system
        pcall(function()
            exports['ps-dispatch']:SuspiciousActivity({
                coords = payload.coords,
                gender = "male",
                weapon = "unknown",
                description = payload.description or "Hostage situation in progress",
            })
        end)

    elseif dispatch == "RC_DISPATCH" then
        -- rcore_dispatch event
        pcall(function()
            TriggerEvent('rcore_dispatch:server:sendAlert', {
                coords = payload.coords,
                title = payload.title,
                message = payload.description,
                jobs = {"police"},
                code = "10-32",
                color = 3,
                blip = {
                    sprite = 161, scale = 1.2, colour = 1
                }
            })
        end)

    elseif dispatch == "CUSTOM" then
        local ev = Config and Config.CustomDispatchEvent or "custom-dispatch:server:sendAlert"
        pcall(function() TriggerEvent(ev, payload) end)

    else
        print("^1[zidanx-hostage] Unknown dispatch system: "..tostring(dispatch).."^0")
    end
end)

-- Backwards-compatibility original event name
RegisterNetEvent("SendAlert:police", function(data)
    TriggerEvent("zidanx-hostage:server:SendAlert", data)
end)
