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
local urandom = require('os.urandom')

-- open a `/dev/urandom` file descriptor and return an instance of os.urandom
local u = assert(urandom())
print(u) -- os.urandom: ...

-- read 32 bytes of random data from `/dev/urandom` into the internal buffer.
assert(u:read(32))

-- get the 5 bytes of string from the internal buffer.
local s = assert(u:bytes(5))

-- get the 4 elements of uint8 values
local arr8 = assert(u:get8u(4))

-- get the 4 elements of uint16 values
local arr16 = assert(u:get16u(4))

-- get the 4 elements of uint32 values
local arr32 = assert(u:get32u(4))

-- close the `/dev/urandom` file descriptor.
-- you cannot use this instance after calling this method.
u:close()
```


## Error Handling

the following functions return an `error` object created by https://github.com/mah0x211/lua-errno module.


## u, err = urandom()

open `/dev/urandom` and return an `os.urandom` instance.

**Returns**

- `u:os.urandom`: an `os.urandom` object.
- `err:any`: an error object if the operation fails.

**Example**

```lua
local urandom = require('os.urandom')
local u, err = urandom()
print(u) -- os.urandom: ...
```

## urandom:close()

close the `/dev/urandom` file descriptor and free the internal buffer. you cannot use this instance after calling this method.


## nread, err = urandom:read( nbyte )

read a specified number of bytes from `/dev/urandom` into the internal buffer. this method replaces the old data with the new data.

**you must call this method before using the following methods: `bytes`, `get8u`, `get16u`, and `get32u`.**

**Parameters**

- `nbyte:pint`: number of bytes to read (must be positive). if omitted, read all remaining bytes.

**Returns**

- `nread:integer?`: number of bytes read, or `nil` if an error occurs.
- `err:any`: error object if an error occurs.


## s, err = urandom:bytes( [nbyte] [, offset] )

get specified number of bytes as a string from the internal buffer. 

you must call `urandom:read()` before calling this method.

**Parameters**

- `nbyte:pint`: number of bytes to get. if omitted, all remaining bytes are returned.
- `offset:pint`: starting byte offset. defaults to `1`.

**Returns**

- `s:string?`: string containing the specified number of bytes, or `nil` if `offset` exceeds available data or if an error occurs.
- `err:any`: error object if an error occurs.

**NOTE:** 

if the remaining bytes are fewer than `nbyte`, the available bytes are returned without an error.


## arr, err = urandom:get8u( [count] [, offset] )

get uint8 integers from the internal buffer.

you must call `urandom:read()` before calling this method.

**Parameters**

- `count:pint`: number of elements to get. if omitted, all remaining count are returned.
- `offset:pint`: starting element offset. default to `1`.

**Returns**

- `arr:table?`: table containing the specified number of integers, or `nil` if insufficient data or if an error occurs.
- `err:any`: error object if an error occurs.

**NOTE:**

if the remaining bytes are fewer than `count`, it returns an error.

for example, if you call `urandom:get8u(4, 5)` it means that gets `4` elements at element offset `5`. if the remaining bytes are fewer than `count * 8-bit(1-byte)`, it returns an insufficient error.


## arr, err = urandom:get16u( [count] [, offset] )

get uint16 integers from the internal buffer.

**Parameters**

same as `urandom:get8u()`.

**Returns**

same as `urandom:get8u()`.


## arr, err = urandom:get32u( [count] [, offset] )

get uint32 integers from the internal buffer.

**Parameters**

same as `urandom:get8u()`.

**Returns**

same as `urandom:get8u()`.


## License

MIT License
