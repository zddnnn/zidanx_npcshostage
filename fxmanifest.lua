fx_version 'cerulean'
game 'gta5'

description 'Sistema de sometimiento y rehenes (QBCore)'
author 'ZidanxNetwork'

client_scripts {
    'config/config.lua',
    'client/client.lua',
    'custom/client.lua'
}

server_scripts {
    'config/config.lua',
    'server/client.lua'
}

dependencies {
    'qb-core',
    'qb-menu'
}
