-- zidanx-hostage/client.lua
local QBCore = exports['qb-core']:GetCoreObject()
local surrendered = {}

local function getCfg(key, default)
    if Config and Config.Hostage and Config.Hostage[key] ~= nil then
        return Config.Hostage[key]
    end
    return default
end

local function ShowHelpNotification(text)
    BeginTextCommandDisplayHelp("STRING")
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayHelp(0, false, true, -1)
end

local function Notify(msg, type)
    QBCore.Functions.Notify(msg, type or "primary")
end

local function sendPoliceAlert(title, coords, description)
    TriggerServerEvent("zidanx-hostage:server:SendAlert", {
        title = title,
        coords = coords,
        description = description
    })
end

local function hostagePanicLoop(entity)
    Citizen.CreateThread(function()
        while surrendered[entity] do
            Citizen.Wait(math.random(8000, 15000))
            if not surrendered[entity] or not DoesEntityExist(entity) then break end

            if getCfg("EnableHostageScreams", true) then
                PlayAmbientSpeech1(entity, "GENERIC_FRIGHTENED_HIGH", "SPEECH_PARAMS_FORCE")
            end

            if getCfg("EscapeChance", 15) > 0 and math.random(1, 100) <= getCfg("EscapeChance", 15) then
                Notify("¡El rehén intentó escapar!", "error")
                ClearPedTasks(entity)
                TaskSmartFleePed(entity, PlayerPedId(), 50.0, -1, true, true)
                surrendered[entity] = false
                sendPoliceAlert("Hostage Escape", GetEntityCoords(entity), "Un rehén ha escapado de su captor.")
                break
            end
        end
    end)
end

-- menu 
local function openHostageMenu(entity)
    local opts = {
        {
            header = "🔗 Gestión del Rehén", -- modificar desde custom/config
            txt = "Opciones disponibles",
            isMenuHeader = true
        },
        {
            header = "🏃‍♂️ Liberar",
            txt = "Deja al rehén libre y lo deja escapar",
            params = { event = "surrender:release", args = { entity = entity } }
        },
        {
            header = "🧟 Seguir",
            txt = "El rehén caminará detrás de ti",
            params = { event = "surrender:follow", args = { entity = entity } }
        },
        {
            header = "🙏 Arrodillar",
            txt = "Haz que el rehén se arrodille en el suelo",
            params = { event = "surrender:kneel", args = { entity = entity } }
        },
        {
            header = "🚗 Subir al Vehículo",
            txt = "Forzar al rehén a entrar en el coche más cercano",
            params = { event = "surrender:vehicle", args = { entity = entity } }
        },
        {
            header = "👐 Cargar",
            txt = "Carga al rehén en tus brazos",
            params = { event = "surrender:carry", args = { entity = entity } }
        },
          {
            header = "✋ Soltar",
            txt = "Deja de cargar al rehén",
            params = { event = "surrender:dropcarry", args = { entity = entity } }
        },
        {
            header = "🔫 Amenazar",
            txt = "Mantén al rehén bajo tu control directo",
            params = { event = "surrender:threaten", args = { entity = entity } }
        },
        {
            header = "❌ Cerrar",
            txt = "Salir del menú",
            params = { event = "" } -- cerrar sin acción
        }
    }
    exports['qb-menu']:openMenu(opts)
end

local function startNegotiationTimer(entity)
    local duration = getCfg("NegotiationTime", 300) -- segundos
    if duration <= 0 then return end

    Citizen.CreateThread(function()
        local remaining = duration
        while surrendered[entity] and remaining > 0 and DoesEntityExist(entity) do
            Citizen.Wait(1000)
            remaining = remaining - 1
            if remaining == 60 or remaining == 30 then
                Notify("⏳ Queda " .. remaining .. "s antes de que llegue la policía", "info")
            end
        end

        if surrendered[entity] and remaining <= 0 and DoesEntityExist(entity) then
            sendPoliceAlert("Hostage Situation", GetEntityCoords(entity),
                "Tiempo de negociación agotado. Policía alertada automáticamente.")
        end
    end)
end

function DoSurrender(entity)
    if not DoesEntityExist(entity) or surrendered[entity] then return end
    math.randomseed(GetGameTimer())

    if math.random(0, 100) < getCfg("FailChance", 20) then
        sendPoliceAlert("Attempted Kidnapping", GetEntityCoords(PlayerPedId()),
            "Un civil reporta un intento fallido de secuestro.")
        TaskReactAndFleePed(entity, PlayerPedId())
        Notify("El civil ignoró tu amenaza y escapó", "error")
        return
    end

    RequestAnimDict("random@arrests")
    RequestAnimDict("random@arrests@busted")
    while not HasAnimDictLoaded("random@arrests") or not HasAnimDictLoaded("random@arrests@busted") do
        Citizen.Wait(0)
    end

    TaskPlayAnim(entity, "random@arrests", "idle_2_hands_up", 8.0, 1.0, -1, 2, 0, 0, 0, 0)
    Citizen.Wait(2000)
    TaskPlayAnim(entity, "random@arrests", "kneeling_arrest_idle", 8.0, 1.0, -1, 2, 0, 0, 0, 0)
    Citizen.Wait(1000)
    TaskPlayAnim(entity, "random@arrests@busted", "enter", 8.0, 1.0, -1, 2, 0, 0, 0, 0)
    Citizen.Wait(1000)
    TaskPlayAnim(entity, "random@arrests@busted", "idle_a", 8.0, 1.0, -1, 9, 0, 0, 0, 0)

    SetEntityAsMissionEntity(entity, true, true)
    surrendered[entity] = true

    hostagePanicLoop(entity)
    startNegotiationTimer(entity)

    sendPoliceAlert("Hostage Taken", GetEntityCoords(entity), "Un rehén ha sido tomado.")
end

Citizen.CreateThread(function()
    while true do
        local sleep = 1000
        local ped = PlayerPedId()

        if IsPedArmed(ped, 7) and (IsPedInMeleeCombat(ped) or IsPlayerFreeAiming(PlayerId())) then
            local found, target = GetEntityPlayerIsFreeAimingAt(PlayerId())
            if not found then
                found, target = GetPlayerTargetEntity(PlayerId())
            end

            if found and IsEntityAPed(target) and not IsPedAPlayer(target) and GetEntityHealth(target) > 0 then
                sleep = 5
                ShowHelpNotification("Presiona ~INPUT_CONTEXT~ para someter al civil")
                if IsControlJustPressed(0, 38) then
                    DoSurrender(target)
                    Citizen.Wait(500)
                    openHostageMenu(target)
                end
            end
        end

        Citizen.Wait(sleep)
    end
end)

RegisterNetEvent("surrender:release", function(data)
    local entity = data.entity
    if not DoesEntityExist(entity) then return end
    surrendered[entity] = false
    ClearPedTasks(entity)
    DetachEntity(entity, true, true)
    TaskSmartFleePed(entity, PlayerPedId(), 50.0, -1, true, true)
    Notify("Liberaste al rehén", "success")
end)

RegisterNetEvent("surrender:follow", function(data)
    local entity = data.entity
    if not DoesEntityExist(entity) then return end
    surrendered[entity] = "follow"
    TaskFollowToOffsetOfEntity(entity, PlayerPedId(), 0.5, -1.0, 0.0, 3.0, -1, 1.0, true)
end)

RegisterNetEvent("surrender:kneel", function(data)
    local entity = data.entity
    if not DoesEntityExist(entity) then return end
    surrendered[entity] = "kneel"
    TaskPlayAnim(entity, "random@arrests@busted", "idle_a", 8.0, 1.0, -1, 9, 0, 0, 0, 0)
end)

RegisterNetEvent("surrender:vehicle", function(data)
    local entity = data.entity
    if not DoesEntityExist(entity) then return end
    local veh = GetClosestVehicle(GetEntityCoords(PlayerPedId()), 5.0, 0, 70)
    if DoesEntityExist(veh) then
        TaskWarpPedIntoVehicle(entity, veh, 2) -- asiento trasero
        Notify("El rehén fue metido en el vehículo", "success")
    else
        Notify("No hay vehículo cercano", "error")
    end
end)

RegisterNetEvent("surrender:carry", function(data)
    local entity = data.entity
    if not DoesEntityExist(entity) then return end
    surrendered[entity] = "carry"
    
    RequestAnimDict("missfinale_c2mcs_1")
    while not HasAnimDictLoaded("missfinale_c2mcs_1") do Citizen.Wait(0) end
    
    TaskPlayAnim(PlayerPedId(), "missfinale_c2mcs_1", "fin_c2_mcs_1_camman", 8.0, 1.0, -1, 49, 0, 0, 0, 0)
    AttachEntityToEntity(entity, PlayerPedId(), 0, 0.27, 0.15, 0.63, 0.0, 0.0, 0.0, false, false, false, false, 2, false)
    Citizen.CreateThread(function()
        while surrendered[entity] == "carry" and DoesEntityExist(entity) do
            Citizen.Wait(0)
            if IsControlJustPressed(0, 177) then -- BACKSPACE
                TriggerEvent("surrender:dropcarry", { entity = entity })
            end
        end
    end)
end)

RegisterNetEvent("surrender:dropcarry", function(data)
    local entity = data.entity
    if not DoesEntityExist(entity) then return end

    surrendered[entity] = false
    DetachEntity(entity, true, false)
    ClearPedTasks(PlayerPedId())
    Notify("Has dejado de cargar al rehén", "success")
end)


RegisterNetEvent("surrender:threaten", function(data)
    local entity = data.entity
    if not DoesEntityExist(entity) then return end
    surrendered[entity] = "threaten"
    RequestAnimDict("anim@gangops@hostage@")
    while not HasAnimDictLoaded("anim@gangops@hostage@") do Citizen.Wait(0) end

    TaskPlayAnim(PlayerPedId(), "anim@gangops@hostage@", "perp_idle", 8.0, 1.0, -1, 49, 0, 0, 0, 0)
    TaskPlayAnim(entity, "anim@gangops@hostage@", "victim_idle", 8.0, 1.0, -1, 2, 0, 0, 0, 0)
    AttachEntityToEntity(entity, PlayerPedId(), 0, -0.24, 0.11, 0.0, 0.5, 0.5, 0.0, false, false, false, false, 2, false)

    Citizen.CreateThread(function()
        while surrendered[entity] == "threaten" and DoesEntityExist(entity) do
            Citizen.Wait(0)
            if IsControlJustPressed(0, 191) then 
                ClearPedTasks(PlayerPedId())
                DetachEntity(entity, true, false)
                SetEntityHealth(entity, 0)
                surrendered[entity] = false
                sendPoliceAlert("Hostage Killed", GetEntityCoords(entity), "El rehén ha sido ejecutado.")
            elseif IsControlJustPressed(0, 177) then 
                ClearPedTasks(PlayerPedId())
                DetachEntity(entity, true, false)
                TriggerEvent("surrender:kneel", { entity = entity })
            end
        end
    end)
end)

if Config.Hostage.EnableTestCommand then
    local cmd = Config.Hostage.TestCommandName or "testhostage"
    RegisterCommand(cmd, function()
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        local hash = GetHashKey(Config.Hostage.TestNPCModel or "a_m_m_business_01")
        RequestModel(hash)
        while not HasModelLoaded(hash) do Citizen.Wait(0) end
        local npc = CreatePed(4, hash, coords.x + 1, coords.y, coords.z, 0.0, true, true)
        SetEntityAsMissionEntity(npc, true, true)
        SetPedFleeAttributes(npc, 0, false)
        SetBlockingOfNonTemporaryEvents(npc, true)
        openHostageMenu(npc)
    end, false)
end

