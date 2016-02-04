#include <lua.h>
#include <lauxlib.h>

#ifdef _WIN32
#define LUAEXPORT __declspec(dllexport)
#else
#define LUAEXPORT __attribute__((visibility("default")))
#endif

void time_open(lua_State *L);

/*-------------------------------------------------------------------------
 * Initializes all library modules.
 *-------------------------------------------------------------------------*/
LUAEXPORT int luaopen_busted_ccore(lua_State *L) {
    lua_newtable(L);
    time_open(L);
    return 1;
}
