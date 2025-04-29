local assert = require('assert')
local testcase = require('testcase')
local urandom = require('os.urandom')

function testcase.urandom()
    -- test that create a urandom instance
    local u, err = urandom()
    assert.is_nil(err)
    assert.re_match(u, '^os.urandom: ')

    -- test that use /dev/random to get random bytes
    u, err = urandom('/dev/random')
    assert.is_nil(err)
    assert.re_match(u, '^os.urandom: ')

    -- test that return error with invalid path
    u, err = urandom('/invalid/path')
    assert.not_nil(err)
    assert.is_nil(u)
end

function testcase.bytes()
    local u = assert(urandom())

    -- test that get N bytes
    local data = assert(u:bytes(9))
    assert.equal(#data, 9)

    -- test that throws error with no argument
    local err = assert.throws(u.bytes, u)
    assert.match(err, 'positive integer expected, got no value')
end

function testcase.get8u()
    local u = assert(urandom())

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
    local u = assert(urandom())

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
    local u = assert(urandom())

    -- test that get as uint32 array
    local arr = assert(u:get32u(4))
    assert.equal(#arr, 4)
    -- confirm that list of integer
    for i = 1, #arr do
        assert.is_int(arr[i])
        assert.less(arr[i], 4294967296)
    end
end

function testcase.close()
    local u = assert(urandom())

    -- test that close the urandom instance
    u:close()

    -- test that return EBADF error
    for _, method in ipairs({
        'bytes',
        'get8u',
        'get16u',
        'get32u',
    }) do
        local _, err = u[method](u, 1)
        assert.match(err, 'EBADF')
    end
end
