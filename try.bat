call luarocks remove busted --force
call luarocks make --pin
cls
call busted %*
