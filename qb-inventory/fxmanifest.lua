fx_version 'cerulean'
game 'gta5'

description 'QB-Inventory - NoPixel 4.0 Inspired 3D UI'
author 'Sixth-RP'
version '1.0.0'

shared_scripts {
    '@qb-core/shared/locale.lua',
    'locales/en.lua',
    'config.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/css/style.css',
    'html/js/app.js',
    'html/img/*.png',
    'html/fonts/*.ttf',
    'html/fonts/*.woff',
    'html/fonts/*.woff2'
}

lua54 'yes'

dependencies {
    'qb-core',
    'oxmysql'
}
