-- Config file for ZidanX Hostage v2
Config = {}

-- Choose dispatch system:
-- "ORIGIN_DISPATCH" | "QB_DISPATCH" | "OX_DISPATCH" | "CD_DISPATCH" | "PS_DISPATCH" | "RC_DISPATCH" | "CUSTOM"
Config.DispatchSystem = "QB_DISPATCH"

-- If using CUSTOM, set the event name to trigger on server (server will TriggerEvent)
Config.CustomDispatchEvent = "custom-dispatch:server:sendAlert"

-- Map blip / alert settings
Config.AlertRadius = 200.0
Config.AlertRequirePoliceJob = true

-- ELK Menu integration: "qb-menu", "ox_lib", "native"
Config.ELKMenu = "qb-menu" -- fallback supported: "ox_lib", "native"

-- Permissions: admin group name(s) that can use admin options
Config.AdminGroups = {"admin","superadmin"} 

-- General toggles
Config.EnableSurrender = true
Config.EnableThreaten = true
Config.EnableKneel = true

-- Language / text
Config.Locale = {
    hostage_prompt = "Presiona ~INPUT_CONTEXT~ para Someter al NPC",
    elk_title = "Opciones de Rehenes",
    elk_take_hostage = "Tomar como rehén",
    elk_release = "Liberar",
    elk_kill = "Rematar",
}

Config.Hostage = {
    FailChance = 20,          -- % de que el civil no obedezca
    EscapeChance = 15,        -- % chance cada ciclo de que intente escapar
    EnableHostageScreams = true,
    NegotiationTime = 300,    -- segundos antes de alerta automática
}

Config.Hostage = {
    EnableTestCommand = true,  -- Habilitar/deshabilitar comando de prueba
    TestCommandName = "testhostage", -- commando 
    TestNPCModel = "a_m_m_business_01" -- tipo de npc para la prueba ( x )
}