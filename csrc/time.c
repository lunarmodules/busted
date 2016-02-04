#include <lua.h>
#include <lauxlib.h>

#ifdef _WIN32
#include <windows.h>
#else
#include <time.h>
#include <sys/time.h>
#endif

#include "compat.h"

/*-------------------------------------------------------------------------
 * Gets time in s, relative to January 1, 1970 (UTC)
 * Returns
 *   time in s.
 *-------------------------------------------------------------------------*/
#ifdef _WIN32
static double time_gettime(void) {
    FILETIME ft;
    double t;
    GetSystemTimeAsFileTime(&ft);
    /* Windows file time (time since January 1, 1601 (UTC)) */
    t  = ft.dwLowDateTime/1.0e7 + ft.dwHighDateTime*(4294967296.0/1.0e7);
    /* convert to Unix Epoch time (time since January 1, 1970 (UTC)) */
    return (t - 11644473600.0);
}
#else
static double time_gettime(void) {
    struct timeval v;
    gettimeofday(&v, (struct timezone *) NULL);
    /* Unix Epoch time (time since January 1, 1970 (UTC)) */
    return v.tv_sec + v.tv_usec/1.0e6;
}
#endif

/*-------------------------------------------------------------------------
 * Returns the time the system has been up, in secconds.
 *-------------------------------------------------------------------------*/
static int time_lua_gettime(lua_State *L)
{
    lua_pushnumber(L, time_gettime());
    return 1;
}

/*-------------------------------------------------------------------------
 * Sleep for n seconds.
 *-------------------------------------------------------------------------*/
#ifdef _WIN32
static int time_lua_sleep(lua_State *L)
{
    double n = luaL_checknumber(L, 1);
    if (n < 0.0) n = 0.0;
    if (n < DBL_MAX/1000.0) n *= 1000.0;
    if (n > INT_MAX) n = INT_MAX;
    Sleep((int)n);
    return 0;
}
#else
static int time_lua_sleep(lua_State *L)
{
    double n = luaL_checknumber(L, 1);
    struct timespec t, r;
    if (n < 0.0) n = 0.0;
    if (n > INT_MAX) n = INT_MAX;
    t.tv_sec = (int) n;
    n -= t.tv_sec;
    t.tv_nsec = (int) (n * 1000000000);
    if (t.tv_nsec >= 1000000000) t.tv_nsec = 999999999;
    while (nanosleep(&t, &r) != 0) {
        t.tv_sec = r.tv_sec;
        t.tv_nsec = r.tv_nsec;
    }
    return 0;
}
#endif

static luaL_Reg func[] = {
    { "gettime", time_lua_gettime },
    { "sleep", time_lua_sleep },
    { NULL, NULL }
};

/*-------------------------------------------------------------------------
 * Initializes module
 *-------------------------------------------------------------------------*/
void time_open(lua_State *L) {
    luaL_setfuncs(L, func, 0);
}
