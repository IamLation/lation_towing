-- Discord: https://discord.gg/9EbY4nM5uu

fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'iamlation'
description 'A fun & simple towing job for FiveM'
version '1.0.1'

client_scripts {
    'client/*.lua',
}

server_scripts {
    'server/*.lua',
}

shared_scripts {
    'config.lua',
    '@es_extended/imports.lua',
    '@ox_lib/init.lua'
}