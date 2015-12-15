def build(bld):

    if not bld.env.TARGET_LUA_PATH:
        bld.fatal('No LUA_PATH set in configuration.')

    bld(
        target='busted',
        features='install_list use',
        install_list='install_list.txt',
        use='lua-term lua-cliargs luassert mediator-lua'
    )
