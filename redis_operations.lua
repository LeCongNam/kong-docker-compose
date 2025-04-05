local redis = require "resty.redis"

local function log(level, ...)
    ngx.log(level, ...)
end

local function connect_to_redis(host, port, timeout)
    local red = redis:new()
    red:set_timeout(timeout or 1000) -- default timeout is 1 second

    local ok, err = red:connect(host, port)
    if not ok then
        log(ngx.ERR, "Failed to connect to Redis: ", err)
        return nil, err
    end

    return red
end

local function set_key(host, port, key, value, ttl)
    local red, err = connect_to_redis(host, port)
    if not red then
        return nil, err
    end

    local ok, err = red:set(key, value)
    if not ok then
        log(ngx.ERR, "Failed to set key in Redis: ", err)
        return nil, err
    end

    if ttl then
        local ok_ttl, err_ttl = red:expire(key, ttl)
        if not ok_ttl then
            log(ngx.ERR, "Failed to set TTL for key: ", err_ttl)
            return nil, err_ttl
        end
    end

    red:set_keepalive(10000, 100)
    return true
end

local function delete_key(host, port, key)
    local red, err = connect_to_redis(host, port)
    if not red then
        return nil, err
    end

    local ok, err = red:del(key)
    if not ok then
        log(ngx.ERR, "Failed to delete key in Redis: ", err)
        return nil, err
    end

    red:set_keepalive(10000, 100)
    return true
end

local function update_key(host, port, key, new_value, ttl)
    local red, err = connect_to_redis(host, port)
    if not red then
        return nil, err
    end

    local exists, err = red:exists(key)
    if not exists or exists == 0 then
        log(ngx.ERR, "Key does not exist in Redis: ", key)
        return nil, "Key does not exist"
    end

    local ok, err = red:set(key, new_value)
    if not ok then
        log(ngx.ERR, "Failed to update key in Redis: ", err)
        return nil, err
    end

    if ttl then
        local ok_ttl, err_ttl = red:expire(key, ttl)
        if not ok_ttl then
            log(ngx.ERR, "Failed to update TTL for key: ", err_ttl)
            return nil, err_ttl
        end
    end

    red:set_keepalive(10000, 100)
    return true
end

-- Example usage
local host = "127.0.0.1"
local port = 6379

-- Set a key
local ok, err = set_key(host, port, "example_key", "example_value", 60)
if not ok then
    ngx.say("Failed to set key: ", err)
else
    ngx.say("Key set successfully")
end

-- Update a key
local ok, err = update_key(host, port, "example_key", "new_value", 120)
if not ok then
    ngx.say("Failed to update key: ", err)
else
    ngx.say("Key updated successfully")
end

-- Delete a key
local ok, err = delete_key(host, port, "example_key")
if not ok then
    ngx.say("Failed to delete key: ", err)
else
    ngx.say("Key deleted successfully")
end