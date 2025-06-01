fx_version 'cerulean'
game 'gta5'

author 'Tribal_Developments'
description 'Emergency Vehicle Lane Merge System'
version '1.2.0'

shared_scripts {
    '@qb-core/shared/locale.lua',
    'config.lua'
}

client_scripts {
    'client.lua'
}

server_scripts {
    'server.lua'
}

dependencies {
    'qb-core'
}
