/**
 *  Copyright (C) 2025 Masatoshi Fukunaga
 *
 *  Permission is hereby granted, free of charge, to any person obtaining a copy
 *  of this software and associated documentation files (the "Software"), to
 *  deal in the Software without restriction, including without limitation the
 *  rights to use, copy, modify, merge, publish, distribute, sublicense,
 *  and/or sell copies of the Software, and to permit persons to whom the
 *  Software is furnished to do so, subject to the following conditions:
 *
 *  The above copyright notice and this permission notice shall be included in
 *  all copies or substantial portions of the Software.
 *
 *  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
 *  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 *  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 *  DEALINGS IN THE SOFTWARE.
 *
 */

#include <errno.h>
#include <fcntl.h>
#include <limits.h>
#include <stdint.h>
#include <stdio.h>
#include <unistd.h>
// lua
#include "lauxhlib.h"
#include "lua_errno.h"

#define MODULE_MT "os.urandom"

typedef struct {
    int fd;
    int ref_buf;
    size_t len;
    union {
        uint8_t *i8;
        uint16_t *i16;
        uint32_t *i32;
        char *buf;
    };
} urandom_t;

static int read_urandom(lua_State *L, urandom_t *u, size_t nbyte,
                        const char *op)
{
    char *buf     = NULL;
    char *ptr     = NULL;
    size_t remain = nbyte;

    if (u->fd == -1) {
        // fd is not opened
        lua_pushnil(L);
        errno = EBADF;
        lua_errno_new(L, errno, op);
        return 2;
    }

    buf = (nbyte != u->len) ? lua_newuserdata(L, nbyte) : u->buf;
    ptr = buf;
    while (remain > 0) {
        ssize_t n = read(u->fd, ptr, remain);
        if (n > 0) {
            remain -= (size_t)n;
            ptr += n;
            continue;
        }

        // got error
        if (n == 0) {
            errno = EIO;
        }
        lua_pushnil(L);
        lua_errno_new(L, errno, op);
        return 2;
    }

    if (buf != u->buf) {
        u->buf     = buf;
        u->len     = nbyte;
        u->ref_buf = lauxh_unref(L, u->ref_buf);
        u->ref_buf = lauxh_ref(L);
    }

    return 0;
}

static inline int getu_lua(lua_State *L, const char *op, int nbit)
{
    urandom_t *u = luaL_checkudata(L, 1, MODULE_MT);
    size_t count = (size_t)lauxh_checkpint(L, 2);
    int rc       = read_urandom(L, u, count * (nbit / 8), op);

    if (rc != 0) {
        // read error
        return rc;
    }

    lua_settop(L, 1);
    lua_createtable(L, count, 0);

#define push_ival(v)                                                           \
    do {                                                                       \
        typeof(v) p = (v);                                                     \
        for (size_t i = 1; i <= count; i++) {                                  \
            lauxh_pushint2arr(L, i, *p);                                       \
            p++;                                                               \
        }                                                                      \
    } while (0)

    if (nbit == 8) {
        push_ival(u->i8);
    } else if (nbit == 16) {
        push_ival(u->i16);
    } else if (nbit == 32) {
        push_ival(u->i32);
    }

#undef push_ival

    return 1;
}

static int get32u_lua(lua_State *L)
{
    return getu_lua(L, "os.urandom.get32u", 32);
}

static int get16u_lua(lua_State *L)
{
    return getu_lua(L, "os.urandom.get16u", 16);
}

static int get8u_lua(lua_State *L)
{
    return getu_lua(L, "os.urandom.get8u", 8);
}

static int bytes_lua(lua_State *L)
{
    urandom_t *u = luaL_checkudata(L, 1, MODULE_MT);
    size_t nbyte = (size_t)lauxh_checkpint(L, 2);
    int rc       = read_urandom(L, u, nbyte, "os.urandom.bytes");

    if (rc != 0) {
        // read error
        return rc;
    }
    lua_pushlstring(L, u->buf, nbyte);
    return 1;
}

static int close_lua(lua_State *L)
{
    urandom_t *u = luaL_checkudata(L, 1, MODULE_MT);

    if (u->fd != -1) {
        close(u->fd);
        u->fd = -1;
    }
    u->ref_buf = lauxh_unref(L, u->ref_buf);

    return 0;
}

static int tostring_lua(lua_State *L)
{
    luaL_checkudata(L, 1, MODULE_MT);
    lua_pushfstring(L, MODULE_MT ": %p", lua_topointer(L, 1));
    return 1;
}

static int gc_lua(lua_State *L)
{
    urandom_t *u = lua_touserdata(L, 1);

    if (u->fd != -1) {
        close(u->fd);
    }
    lauxh_unref(L, u->ref_buf);

    return 0;
}

static int new_lua(lua_State *L)
{
    urandom_t *u = lua_newuserdata(L, sizeof(urandom_t));

    *u = (urandom_t){
        .fd      = -1,
        .buf     = NULL,
        .len     = 0,
        .ref_buf = LUA_NOREF,
    };
    lauxh_setmetatable(L, MODULE_MT);

    // open the urandom file descriptor
    u->fd = open("/dev/urandom", O_RDONLY | O_CLOEXEC);
    if (u->fd < 0) {
        lua_pushnil(L);
        lua_errno_new(L, errno, "os.urandom");
        return 2;
    }

    return 1;
}

LUALIB_API int luaopen_os_urandom(lua_State *L)
{
    // create metatable
    if (luaL_newmetatable(L, MODULE_MT)) {
        struct luaL_Reg mmethod[] = {
            {"__gc",       gc_lua      },
            {"__tostring", tostring_lua},
            {NULL,         NULL        }
        };
        struct luaL_Reg method[] = {
            {"close",  close_lua },
            {"bytes",  bytes_lua },
            {"get8u",  get8u_lua },
            {"get16u", get16u_lua},
            {"get32u", get32u_lua},
            {NULL,     NULL      }
        };

        // metamethods
        for (struct luaL_Reg *ptr = mmethod; ptr->name; ptr++) {
            lauxh_pushfn2tbl(L, ptr->name, ptr->func);
        }
        // methods
        lua_newtable(L);
        for (struct luaL_Reg *ptr = method; ptr->name; ptr++) {
            lauxh_pushfn2tbl(L, ptr->name, ptr->func);
        }
        lua_setfield(L, -2, "__index");
        lua_pop(L, 1);
    }

    lua_errno_loadlib(L);
    lua_pushcfunction(L, new_lua);
    return 1;
}
