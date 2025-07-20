local assert = require('assert')
local testcase = require('testcase')
local urandom = require('os.urandom')

function testcase.urandom()
    -- test that create a urandom instance
    local u = urandom()
    assert.re_match(u, '^os.urandom: ')
end

function testcase.bytes()
    local u = urandom()

    -- test that get N bytes
    local data = assert(u:bytes(9))
    assert.equal(#data, 9)

    -- test that throws error with no argument
    local err = assert.throws(u.bytes, u)
    assert.match(err, 'positive integer expected, got no value')
end

function testcase.get8u()
    local u = urandom()

    -- test that get 5 elements as 8bit integer array
    local arr = assert(u:get8u(5))
    assert.equal(#arr, 5)
    -- confirm that list of uint8 integer
    for i = 1, #arr do
        assert.is_int(arr[i])
        assert.less(arr[i], 256)
    end

    -- test that throws error with no argument
    local err = assert.throws(u.get8u, u)
    assert.match(err, 'positive integer expected, got no value')
end

function testcase.get16u()
    local u = urandom()

    -- test that get as uint16 array
    local arr = assert(u:get16u(8))
    assert.equal(#arr, 8)
    -- confirm that list of integer
    for i = 1, #arr do
        assert.is_int(arr[i])
        assert.less(arr[i], 65536)
    end
end

function testcase.get32u()
    local u = urandom()

    -- test that get as uint32 array
    local arr = assert(u:get32u(4))
    assert.equal(#arr, 4)
    -- confirm that list of integer
    for i = 1, #arr do
        assert.is_int(arr[i])
        assert.less(arr[i], 4294967296)
    end
end

function testcase.overflow()
    local u = urandom()

    -- test that returns error for count overflow
    -- INT_MAX + 1 should trigger the lua_createtable limit check
    local int_max_plus_one = 0x7FFFFFFF + 1  -- INT_MAX + 1 (2^31)
    local data, err = u:get32u(int_max_plus_one)
    assert.is_nil(data)
    assert.match(err, 'ERANGE')
end

function testcase.close()
    local u = urandom()

    -- test that close the urandom file descriptor if it is open
    u:close()

    -- test that can still call methods after close
    -- this is to ensure that the instance is not destroyed
    -- and can still be used
    for _, method in ipairs({
        'bytes',
        'get8u',
        'get16u',
        'get32u',
    }) do
        local data, err = u[method](u, 1)
        if method == 'bytes' then
            assert.is_string(data)
        else
            assert.is_table(data)
        end
        assert.equal(#data, 1)
        assert.is_nil(err)
    end
end
