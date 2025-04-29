# lua-os-urandom

[![test](https://github.com/mah0x211/lua-os-urandom/actions/workflows/test.yml/badge.svg)](https://github.com/mah0x211/lua-os-urandom/actions/workflows/test.yml)
[![codecov](https://codecov.io/gh/mah0x211/lua-os-urandom/branch/master/graph/badge.svg)](https://codecov.io/gh/mah0x211/lua-os-urandom)


`lua-os-urandom` is a Lua module for safely obtaining random bytes and random integers from the operating system's entropy source `/dev/urandom`.


## Installation

```sh
luarocks install os-urandom
```


## Usage

```lua
local dump = require('dump')
local urandom = require('os.urandom')

-- open a `/dev/urandom` file descriptor and return an instance of os.urandom
local u = assert(urandom())
print(u) -- os.urandom: 0x600003e308d8

-- get the 5 bytes of string from the internal buffer.
local s = assert(u:bytes(5))
print(dump(s)) -- "k???k"

-- get the 4 elements of uint8 values
local arr = assert(u:get8u(4))
print(dump(arr))
-- {
--     [1] = 107,
--     [2] = 178,
--     [3] = 140,
--     [4] = 249
-- }

-- get the 4 elements of uint16 values
arr = assert(u:get16u(4))
print(dump(arr))
-- {
--     [1] = 45675,
--     [2] = 63884,
--     [3] = 4203,
--     [4] = 35505
-- }

-- get the 4 elements of uint32 values
arr = assert(u:get32u(4))
print(dump(arr))
-- {
--     [1] = 4186747499,
--     [2] = 2326859883,
--     [3] = 3084003331,
--     [4] = 1269583660
-- }

-- close the `/dev/urandom` file descriptor.
-- you cannot use this instance after calling this method.
u:close()
```


## Error Handling

the following functions return an `error` object created by https://github.com/mah0x211/lua-errno module.


## u, err = urandom( [pathname] )

open `/dev/urandom` or specified pathname and return an instance of `os.urandom`.

**Parameters**

- `pathname:string?`: path to the random source. if omitted, `/dev/urandom` will be opened by default.

**Returns**

- `u:os.urandom`: an `os.urandom` object.
- `err:any`: an error object if the operation fails.

**Example**

```lua
local urandom = require('os.urandom')

-- open the default random source (`/dev/urandom`).
local u = assert(urandom())
print(u) -- os.urandom: ...

-- open a custom random source.
u = assert(urandom('/dev/random'))
print(u) -- os.urandom: ...
```

## urandom:close()

close the `/dev/urandom` file descriptor and free the internal buffer. you cannot use this instance after calling this method.


## s, err = urandom:bytes( nbyte )

get specified number of bytes as a string.

**Parameters**

- `nbyte:pint`: number of bytes to get.
- `offset:pint`: starting byte offset. defaults to `1`.

**Returns**

- `s:string?`: string containing the specified number of bytes, or `nil` if an error occurs.
- `err:any`: error object if an error occurs.


## arr, err = urandom:get8u( count )

get uint8 integers.

**Parameters**

- `count:pint`: number of elements to get.

**Returns**

- `arr:table?`: table containing the specified number of integers, or `nil` if an error occurs.
- `err:any`: error object if an error occurs.


## arr, err = urandom:get16u( count )

get uint16 integers.

**Parameters**

same as `urandom:get8u()`.

**Returns**

same as `urandom:get8u()`.


## arr, err = urandom:get32u( [count] [, offset] )

get uint32 integers.

**Parameters**

same as `urandom:get8u()`.

**Returns**

same as `urandom:get8u()`.


## License

MIT License
