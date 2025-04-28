local assert = require('assert')
local testcase = require('testcase')
local urandom = require('os.urandom')

-- helper function to get the endianness of the system
local ENDIAN = string.dump(function()
end):byte(7) == 0x0 and 'BE' or 'LE'

-- helper function to convert bytes to uint8 array
local function tou8arr(bytes)
    local t = {}
    for i = 1, #bytes do
        t[i] = string.byte(bytes, i)
    end
    return t
end

-- helper function to convert bytes to uint16 array
local function tou16arr(bytes)
    local t = {}
    local len = #bytes
    local idx = 1
    local toint = ENDIAN == 'LE' and function(b1, b2)
        -- little endian
        return b1 + (b2 * 256)
    end or function(b1, b2)
        -- big endian
        return (b1 * 256) + b2
    end

    for i = 1, len - 1, 2 do
        local b1 = string.byte(bytes, i)
        local b2 = string.byte(bytes, i + 1)
        t[idx] = toint(b1, b2)
        idx = idx + 1
    end
    return t
end

-- helper function to convert bytes to uint32 array
local function tou32arr(bytes)
    local t = {}
    local len = #bytes
    local idx = 1
    local toint = ENDIAN == 'LE' and function(b1, b2, b3, b4)
        -- little endian
        return b1 + (b2 * 256) + (b3 * 65536) + (b4 * 16777216)
    end or function(b1, b2, b3, b4)
        -- big endian
        return (b1 * 16777216) + (b2 * 65536) + (b3 * 256) + b4
    end
    for i = 1, len - 3, 4 do
        local b1 = string.byte(bytes, i)
        local b2 = string.byte(bytes, i + 1)
        local b3 = string.byte(bytes, i + 2)
        local b4 = string.byte(bytes, i + 3)
        t[idx] = toint(b1, b2, b3, b4)
        idx = idx + 1
    end
    return t
end

function testcase.urandom()
    -- test that create a urandom instance
    local u, err = urandom()
    assert.is_nil(err)
    assert.re_match(u, '^os.urandom: ')
end

function testcase.read()
    local u = assert(urandom())

    -- test that read 16 bytes
    local actual, err = u:read(16)
    assert.is_nil(err)
    assert.equal(actual, 16)

    -- test that throws error if size is not positive integer
    for _, v in ipairs({
        -1,
        0,
        1.5,
        'a',
        {},
        true,
        false,
    }) do
        err = assert.throws(u.read, u, v)
        assert.match(err, 'positive integer expected')
    end
end

function testcase.bytes()
    local u = assert(urandom())
    assert.equal(u:read(16), 16)

    -- test that get whole data
    local data, err = u:bytes()
    assert.is_nil(err)
    assert.equal(#data, 16)

    -- test that get N bytes
    local chunk = assert(u:bytes(9))
    assert.equal(chunk, data:sub(1, 9))

    -- test that get N bytes with offset
    chunk = assert(u:bytes(nil, 5))
    assert.equal(chunk, data:sub(5))

    -- test that get N bytes with offset and length
    chunk = assert(u:bytes(5, 2))
    assert.equal(chunk, data:sub(2, 6))

    -- test that get remaining bytes with offset
    chunk = assert(u:bytes(10, 10))
    assert.equal(#chunk, 7)
    assert.equal(chunk, data:sub(10))

    -- test that return nil if no data in specified range
    chunk, err = u:bytes(5, 17)
    assert.is_nil(chunk)
    assert.is_nil(err)
end

function testcase.get8u()
    local u = assert(urandom())
    assert.equal(u:read(16), 16)
    local data = assert(u:bytes())

    -- test that get as uint8 array
    local arr, err = u:get8u()
    assert.is_nil(err)
    assert.equal(#arr, 16)
    -- confirm that list of integer
    for i = 1, #arr do
        assert.is_int(arr[i])
    end
    assert.equal(arr, tou8arr(data))

    -- test that get as 8bit integer array with count
    arr, err = u:get8u(3)
    assert.is_nil(err)
    -- confirm that list of integer
    for i = 1, #arr do
        assert.is_int(arr[i])
    end
    assert.equal(arr, tou8arr(data:sub(1, 3)))

    -- test that get as uint8 array with offset
    arr = assert(u:get8u(nil, 2))
    assert.equal(arr, tou8arr(data:sub(2)))

    -- test that get as uint8 array with count and offset
    arr = assert(u:get8u(5, 2))
    assert.equal(arr, tou8arr(data:sub(2, 6)))

    -- test that return nil and error if offset is out of range
    arr, err = u:get8u(nil, 17)
    assert.re_match(err, 'get elements .+8-bit .+ offset 17.+ out of range')
    assert.is_nil(arr)

    -- test that return nil and error if number of elements and offset is out of range
    arr, err = u:get8u(2, 16)
    assert.re_match(err, 'get 2 elements .+8-bit .+ offset 16.+ insufficient')
    assert.is_nil(arr)
end

function testcase.get16u()
    local u = assert(urandom())
    assert.equal(u:read(16), 16)
    local data = assert(u:bytes())

    -- test that get as uint16 array
    local arr, err = u:get16u()
    assert.is_nil(err)
    assert.equal(#arr, 8)
    -- confirm that list of integer
    for i = 1, #arr do
        assert.is_int(arr[i])
    end
    assert.equal(arr, tou16arr(data))
end

function testcase.get32u()
    local u = assert(urandom())
    assert.equal(u:read(16), 16)
    local data = assert(u:bytes())

    -- test that get as uint32 array
    local arr, err = u:get32u()
    assert.is_nil(err)
    assert.equal(#arr, 4)
    -- confirm that list of integer
    for i = 1, #arr do
        assert.is_int(arr[i])
    end
    assert.equal(arr, tou32arr(data))
end

function testcase.close()
    local u = assert(urandom())

    -- test that close the urandom instance
    u:close()

    -- test that return EBADF error
    for _, method in ipairs({
        'read',
        'bytes',
        'get8u',
        'get16u',
        'get32u',
    }) do
        local _, err = u[method](u, 1)
        assert.match(err, 'EBADF')
    end
end
