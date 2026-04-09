fx_version 'cerulean'
game 'gta5'

name 'nexora_business'
description 'Player-owned Business System'
version '1.0.0'
author 'Nexora'

shared_scripts {
    '@es_extended/imports.lua',
    '@ox_lib/init.lua',
    'config.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/cache.lua',
    'server/utils.lua',
    'server/callbacks.lua',
    'server/wages.lua',
    'server/main.lua'
}

client_scripts {
    'client/utils.lua',
    'client/businesses.lua',
    'client/wholesale.lua',
    'client/pickmode.lua',
    'client/main.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/assets/index.css',
    'html/app.js'
}

dependencies {
    'ox_lib',
    'ox_target',
    'oxmysql',
    'es_extended',
    'ox_inventory'
}