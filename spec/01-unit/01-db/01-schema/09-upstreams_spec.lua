local inspect = require "inspect"
local Schema = require "kong.db.schema"
local certificates = require "kong.db.schema.entities.certificates"
local upstreams = require "kong.db.schema.entities.upstreams"

local function setup_global_env()
  _G.kong = _G.kong or {}
  _G.kong.log = _G.kong.log or {
    debug = function(msg)
      ngx.log(ngx.DEBUG, msg)
    end,
    error = function(msg)
      ngx.log(ngx.ERR, msg)
    end,
    warn = function (msg)
      ngx.log(ngx.WARN, msg)
    end
  }
end

assert(Schema.new(certificates))
local Upstreams = Schema.new(upstreams)

local function validate(b)
  return Upstreams:validate(Upstreams:process_auto_fields(b, "insert"))
end


describe("load upstreams", function()
  local a_valid_uuid = "cbb297c0-a956-486d-ad1d-f9b42df9465a"
  local uuid_pattern = "^" .. ("%x"):rep(8) .. "%-" .. ("%x"):rep(4) .. "%-"
                           .. ("%x"):rep(4) .. "%-" .. ("%x"):rep(4) .. "%-"
                           .. ("%x"):rep(12) .. "$"

  setup_global_env()
  it("validates a valid load upstream", function()
    local u = {
      id              = a_valid_uuid,
      name            = "my_service",
      hash_on         = "header",
      hash_on_header  = "X-Balance",
      hash_fallback   = "cookie",
      hash_on_cookie  = "a_cookie",
    }
    assert(validate(u))
  end)

  it("invalid name produces error", function()
    local ok, errs = validate({ name = "1234" })
    assert.falsy(ok)
    assert.truthy(errs["name"])

    ok, errs = validate({ name = "fafa fafa" })
    assert.falsy(ok)
    assert.truthy(errs["name"])

    ok, errs = validate({ name = "192.168.0.1" })
    assert.falsy(ok)
    assert.truthy(errs["name"])

    ok, errs = validate({ name = "myserver:8000" })
    assert.falsy(ok)
    assert.truthy(errs["name"])
  end)

  it("invalid hash_on_cookie produces error", function()
    local ok, errs = validate({ hash_on_cookie = "a cookie" })
    assert.falsy(ok)
    assert.truthy(errs["hash_on_cookie"])
  end)

  it("invalid healthckecks.active.timeout produces error", function()
    local ok, errs = validate({ healthchecks = { active = { timeout = -1 } } } )
    assert.falsy(ok)
    assert.truthy(errs.healthchecks.active.timeout)
  end)

  it("invalid healthckecks.active.concurrency produces error", function()
    local ok, errs = validate({ healthchecks = { active = { concurrency = -1 } } } )
    assert.falsy(ok)
    assert.truthy(errs.healthchecks.active.concurrency)
  end)

  it("invalid healthckecks.active.headers produces error", function()
    local ok, errs = validate({ healthchecks = { active = { headers = { 114514 } } } } )
    assert.falsy(ok)
    assert.truthy(errs.healthchecks.active.headers)
  end)

  it("invalid healthckecks.active.http_path produces error", function()
    local ok, errs = validate({ healthchecks = { active = { http_path = "potato" } } } )
    assert.falsy(ok)
    assert.truthy(errs.healthchecks.active.http_path)
  end)

  it("invalid healthckecks.active.healthy.interval produces error", function()
    local ok, errs = validate({ healthchecks = { active = { healthy = { interval = -1 } } } } )
    assert.falsy(ok)
    assert.truthy(errs.healthchecks.active.healthy.interval)
  end)

  it("invalid healthckecks.active.healthy.successes produces error", function()
    local ok, errs = validate({ healthchecks = { active = { healthy = { successes = -1 } } } } )
    assert.falsy(ok)
    assert.truthy(errs.healthchecks.active.healthy.successes)
  end)

  it("invalid healthckecks.active.healthy.http_statuses produces error", function()
    local ok, errs = validate({ healthchecks = { active = { healthy = { http_statuses = "potato" } } } } )
    assert.falsy(ok)
    assert.truthy(errs.healthchecks.active.healthy.http_statuses)
  end)

  -- not testing active.unhealthy.* and passive.*.* since they are defined like healthy.*.*

  it("hash_on = 'header' makes hash_on_header required", function()
    local ok, errs = validate({ hash_on = "header" })
    assert.falsy(ok)
    assert.truthy(errs.hash_on_header)
  end)

  it("hash_fallback = 'header' makes hash_fallback_header required", function()
    local ok, errs = validate({ hash_fallback = "header" })
    assert.falsy(ok)
    assert.truthy(errs.hash_fallback_header)
  end)

  it("hash_on = 'cookie' makes hash_on_cookie required", function()
    local ok, errs = validate({ hash_on = "cookie" })
    assert.falsy(ok)
    assert.truthy(errs.hash_on_cookie)
  end)

  it("hash_on = 'cookie' makes hash_on_cookie required", function()
    local ok, errs = validate({ hash_fallback = "cookie" })
    assert.falsy(ok)
    assert.truthy(errs.hash_on_cookie)
  end)

  it("hash_on = 'none' requires that hash_fallback is also none", function()
    local ok, errs = validate({ hash_on = "none", hash_fallback = "header" })
    assert.falsy(ok)
    assert.truthy(errs.hash_fallback)
  end)

  it("hash_on = 'cookie' requires that hash_fallback is also none", function()
    local ok, errs = validate({ hash_on = "cookie", hash_fallback = "header" })
    assert.falsy(ok)
    assert.truthy(errs.hash_fallback)
  end)

  it("hash_on must be different from hash_fallback", function()
    local ok, errs = validate({ hash_on = "consumer", hash_fallback = "consumer" })
    assert.falsy(ok)
    assert.truthy(errs.hash_fallback)
    ok, errs = validate({ hash_on = "ip", hash_fallback = "ip" })
    assert.falsy(ok)
    assert.truthy(errs.hash_fallback)
    ok, errs = validate({ hash_on = "path", hash_fallback = "path" })
    assert.falsy(ok)
    assert.truthy(errs.hash_fallback)
  end)

  it("hash_on = 'query_arg' makes hash_on_query_arg required", function()
    local ok, errs = validate({ hash_on = "query_arg" })
    assert.falsy(ok)
    assert.truthy(errs.hash_on_query_arg)
  end)

  it("hash_fallback = 'query_arg' makes hash_fallback_query_arg required", function()
    local ok, errs = validate({ hash_on = "ip", hash_fallback = "query_arg" })
    assert.falsy(ok)
    assert.truthy(errs.hash_fallback_query_arg)
  end)

  it("hash_on and hash_fallback must be different query args", function()
    local ok, errs = validate({ hash_on = "query_arg", hash_on_query_arg = "same",
                                hash_fallback = "query_arg", hash_fallback_query_arg = "same" })
    assert.falsy(ok)
    assert.not_nil(errs["@entity"])
    assert.same(
      {
        "values of these fields must be distinct: 'hash_on_query_arg', 'hash_fallback_query_arg'"
      },
      errs["@entity"]
    )
  end)

  it("hash_on_query_arg and hash_fallback_query_arg must not be empty strings", function()
    local ok, errs = validate({
      name = "test",
      hash_on = "query_arg",
      hash_on_query_arg = "",
    })
    assert.is_nil(ok)
    assert.not_nil(errs.hash_on_query_arg)

    ok, errs = validate({
      name = "test",
      hash_on = "query_arg",
      hash_on_query_arg = "ok",
      hash_fallback = "query_arg",
      hash_fallback_query_arg = "",
    })
    assert.is_nil(ok)
    assert.not_nil(errs.hash_fallback_query_arg)
  end)

  it("hash_on and hash_fallback must be different uri captures", function()
    local ok, errs = validate({ hash_on = "uri_capture", hash_on_uri_capture = "same",
                                hash_fallback = "uri_capture", hash_fallback_uri_capture = "same" })
    assert.falsy(ok)
    assert.not_nil(errs["@entity"])
    assert.same(
      {
        "values of these fields must be distinct: 'hash_on_uri_capture', 'hash_fallback_uri_capture'"
      },
      errs["@entity"]
    )
  end)

  it("hash_on_uri_capture and hash_fallback_uri_capture must not be empty strings", function()
    local ok, errs = validate({
      name = "test",
      hash_on = "uri_capture",
      hash_on_uri_capture = "",
    })
    assert.is_nil(ok)
    assert.not_nil(errs.hash_on_uri_capture)

    ok, errs = validate({
      name = "test",
      hash_on = "uri_capture",
      hash_on_uri_capture = "ok",
      hash_fallback = "uri_capture",
      hash_fallback_uri_capture = "",
    })
    assert.is_nil(ok)
    assert.not_nil(errs.hash_fallback_uri_capture)
  end)

  it("produces set use_srv_name flag", function()
    local u = {
      name = "www.example.com",
      use_srv_name = true,
    }
    u = Upstreams:process_auto_fields(u, "insert")
    local ok, err = Upstreams:validate(u)
    assert.truthy(ok)
    assert.is_nil(err)
    assert.same(u.name, "www.example.com")
    assert.same(u.use_srv_name, true)
  end)

  it("produces defaults", function()
    local u = {
      name = "www.example.com",
    }
    u = Upstreams:process_auto_fields(u, "insert")
    local ok, err = Upstreams:validate(u)
    assert.truthy(ok)
    assert.is_nil(err)
    assert.match(uuid_pattern, u.id)
    assert.same(u.name, "www.example.com")
    assert.same(u.hash_on, "none")
    assert.same(u.hash_fallback, "none")
    assert.same(u.hash_on_cookie_path, "/")
    assert.same(u.slots, 10000)
    assert.same(u.use_srv_name, false)
    assert.same(u.healthchecks, {
      active = {
        type = "http",
        timeout = 1,
        concurrency = 10,
        http_path = "/",
        https_verify_certificate = true,
        healthy = {
          interval = 0,
          http_statuses = { 200, 302 },
          successes = 0,
        },
        unhealthy = {
          interval = 0,
          http_statuses = { 429, 404,
                            500, 501, 502, 503, 504, 505 },
          tcp_failures = 0,
          timeouts = 0,
          http_failures = 0,
        },
      },
      passive = {
        type = "http",
        healthy = {
          http_statuses = { 200, 201, 202, 203, 204, 205, 206, 207, 208, 226,
                            300, 301, 302, 303, 304, 305, 306, 307, 308 },
          successes = 0,
        },
        unhealthy = {
          http_statuses = { 429, 500, 503 },
          tcp_failures = 0,
          timeouts = 0,
          http_failures = 0,
        },
      },
    })
  end)

  describe("name attribute", function()
    -- refusals
    it("requires a valid name with no port", function()
      local ok, err = Upstreams:validate({})
      assert.falsy(ok)
      assert.same({ name = "required field missing" }, err)

      ok, err = Upstreams:validate({ name = "123.123.123.123" })
      assert.falsy(ok)
      assert.same({ name = "Invalid name ('123.123.123.123'); no ip addresses allowed" }, err)

      ok, err = Upstreams:validate({ name = "\\\\bad\\\\////name////" })
      assert.falsy(ok)
      assert.same({ name = "Invalid name ('\\\\bad\\\\////name////'); must be a valid hostname" }, err)

      ok, err = Upstreams:validate({ name = "name:80" })
      assert.falsy(ok)
      assert.same({ name = "Invalid name ('name:80'); no port allowed" }, err)
    end)

    -- acceptance
    it("accepts valid names", function()
      local ok, err = Upstreams:validate({ name = "valid.host.name" })
      assert.truthy(ok)
      assert.is_nil(err)
    end)
  end)

  describe("upstream attribute", function()
    -- refusals
    it("requires a valid hostname", function()
      local ok, err

      ok, err = Upstreams:validate({
        name = "host.test",
        host_header = "http://ahostname.test" }
      )
      assert.falsy(ok)
      assert.same({ host_header = "invalid hostname: http://ahostname.test" }, err)

      ok, err = Upstreams:validate({
        name = "host.test",
        host_header = "ahostname-" }
      )
      assert.falsy(ok)
      assert.same({ host_header = "invalid hostname: ahostname-" }, err)

      ok, err = Upstreams:validate({
        name = "host.test",
        host_header = "a hostname" }
      )
      assert.falsy(ok)
      assert.same({ host_header = "invalid hostname: a hostname" }, err)
    end)

    -- acceptance
    it("accepts valid hostnames", function()
      local ok, err = Upstreams:validate({
        name = "host.test",
        host_header = "ahostname" }
      )
      assert.truthy(ok)
      assert.is_nil(err)

      ok, err = Upstreams:validate({
        name = "host.test",
        host_header = "a.hostname.test" }
      )
      assert.truthy(ok)
      assert.is_nil(err)
    end)
  end)

  describe("healthchecks attribute", function()
    -- refusals
    it("rejects invalid configurations", function()
      local seconds = "value should be between 0 and 65535"
      local pos_integer = "value should be between 1 and 2147483648"
      local zero_integer = "value should be between 0 and 255"
      local status_code = "value should be between 100 and 999"
      local integer = "expected an integer"
      local boolean = "expected a boolean"
      local number = "expected a number"
      local array = "expected an array"
      local string = "expected a string"
      local map = "expected a map"
      local len_min_default = "length must be at least 1"
      local invalid_host = "invalid value: "
      local invalid_host_port = "must not have a port"
      local invalid_ip = "must not be an IP"
      local threshold = "value should be between 0 and 100"
      local tests = {
        {{ active = { timeout = -1 }}, seconds },
        {{ active = { timeout = 1e+42 }}, seconds },
        {{ active = { concurrency = 0.5 }}, integer },
        {{ active = { concurrency = 0 }}, pos_integer },
        {{ active = { concurrency = -10 }}, pos_integer },
        {{ active = { http_path = "" }}, len_min_default },
        {{ active = { http_path = "ovo" }}, "should start with: /" },
        {{ active = { https_sni = "127.0.0.1", }}, invalid_ip },
        {{ active = { https_sni = "127.0.0.1:8080", }}, invalid_ip },
        {{ active = { https_sni = "/example", }}, invalid_host },
        {{ active = { https_sni = ".example", }}, invalid_host },
        {{ active = { https_sni = "example:", }}, invalid_host },
        {{ active = { https_sni = "mock;bin", }}, invalid_host },
        {{ active = { https_sni = "example.com/org", }}, invalid_host },
        {{ active = { https_sni = "example-.org", }}, invalid_host },
        {{ active = { https_sni = "example.org-", }}, invalid_host },
        {{ active = { https_sni = "hello..example.com", }}, invalid_host },
        {{ active = { https_sni = "hello-.example.com", }}, invalid_host },
        {{ active = { https_sni = "example.com:1234", }}, invalid_host_port },
        {{ active = { https_verify_certificate = "ovo", }}, boolean },
        {{ active = { headers = 0, }}, map },
        {{ active = { headers = { 0 }, }}, string },
        {{ active = { headers = { "" }, }}, string },
        {{ active = { headers = { ["x-header"] = 123 }, }}, array },
        {{ active = { healthy = { interval = -1 }}}, seconds },
        {{ active = { healthy = { interval = 1e+42 }}}, seconds },
        {{ active = { healthy = { http_statuses = 404 }}}, array },
        {{ active = { healthy = { http_statuses = { "ovo" }}}}, integer },
        {{ active = { healthy = { http_statuses = { -1 }}}}, status_code },
        {{ active = { healthy = { http_statuses = { 99 }}}}, status_code },
        {{ active = { healthy = { http_statuses = { 1000 }}}}, status_code },
        {{ active = { healthy = { http_statuses = { 111.314 }}}}, integer },
        {{ active = { healthy = { successes = 0.5 }}}, integer },
        {{ active = { unhealthy = { timeouts = 1 }}, threshold = -1}, threshold },
        {{ active = { unhealthy = { timeouts = 1 }}, threshold = 101}, threshold },
        {{ active = { unhealthy = { timeouts = 1 }}, threshold = "50"}, number },
        {{ active = { unhealthy = { timeouts = 1 }}, threshold = true}, number },
        --{{ active = { healthy = { successes = 0 }}}, "must be an integer" },
        {{ active = { healthy = { successes = -1 }}}, zero_integer },
        {{ active = { healthy = { successes = 256 }}}, zero_integer },
        {{ active = { unhealthy = { interval = -1 }}}, seconds },
        {{ active = { unhealthy = { interval = 1e+42 }}}, seconds },
        {{ active = { unhealthy = { http_statuses = 404 }}}, array },
        {{ active = { unhealthy = { http_statuses = { "ovo" }}}}, integer },
        {{ active = { unhealthy = { http_statuses = { -1 }}}}, status_code },
        {{ active = { unhealthy = { http_statuses = { 99 }}}}, status_code },
        {{ active = { unhealthy = { http_statuses = { 1000 }}}}, status_code },
        {{ active = { unhealthy = { tcp_failures = 0.5 }}}, integer },
        {{ active = { unhealthy = { tcp_failures = 256 }}}, zero_integer },
        --{{ active = { unhealthy = { tcp_failures = 0 }}}, integer },
        {{ active = { unhealthy = { tcp_failures = -1 }}}, zero_integer },
        {{ active = { unhealthy = { timeouts = 0.5 }}}, integer },
        {{ active = { unhealthy = { timeouts = 256 }}}, zero_integer },
        --{{ active = { unhealthy = { timeouts = 0 }}}, integer },
        {{ active = { unhealthy = { timeouts = -1 }}}, zero_integer },
        {{ active = { unhealthy = { http_failures = 0.5 }}}, integer},
        {{ active = { unhealthy = { http_failures = -1 }}}, zero_integer },
        {{ active = { unhealthy = { http_failures = 256 }}}, zero_integer },
        {{ passive = { healthy = { http_statuses = 404 }}}, array },
        {{ passive = { healthy = { http_statuses = { "ovo" }}}}, integer },
        {{ passive = { healthy = { http_statuses = { -1 }}}}, status_code },
        {{ passive = { healthy = { http_statuses = { 99 }}}}, status_code },
        {{ passive = { healthy = { http_statuses = { 1000 }}}}, status_code },
        {{ passive = { healthy = { successes = 0.5 }}}, integer },
        --{{ passive = { healthy = { successes = 0 }}}, integer },
        {{ passive = { healthy = { successes = -1 }}}, zero_integer },
        {{ passive = { unhealthy = { http_statuses = 404 }}}, array },
        {{ passive = { unhealthy = { http_statuses = { "ovo" }}}}, integer },
        {{ passive = { unhealthy = { http_statuses = { -1 }}}}, status_code },
        {{ passive = { unhealthy = { http_statuses = { 99 }}}}, status_code },
        {{ passive = { unhealthy = { http_statuses = { 1000 }}}}, status_code },
        {{ passive = { unhealthy = { tcp_failures = 0.5 }}}, integer },
        --{{ passive = { unhealthy = { tcp_failures = 0 }}}, integer },
        {{ passive = { unhealthy = { tcp_failures = -1 }}}, zero_integer },
        {{ passive = { unhealthy = { tcp_failures = 256 }}}, zero_integer },
        {{ passive = { unhealthy = { timeouts = 0.5 }}}, integer },
        {{ passive = { unhealthy = { timeouts = 256 }}}, zero_integer },
        --{{ passive = { unhealthy = { timeouts = 0 }}}, integer },
        {{ passive = { unhealthy = { timeouts = -1 }}}, zero_integer },
        {{ passive = { unhealthy = { http_failures = 0.5 }}}, integer },
        --{{ passive = { unhealthy = { http_failures = 0 }}}, integer },
        {{ passive = { unhealthy = { http_failures = -1 }}}, zero_integer },
        {{ passive = { unhealthy = { http_failures = 256 }}}, zero_integer },
        {{ passive = { unhealthy = { timeouts = 1 }}, threshold = -1}, threshold },
        {{ passive = { unhealthy = { timeouts = 1 }}, threshold = 101}, threshold },
        {{ passive = { unhealthy = { timeouts = 1 }}, threshold = "50"}, number },
        {{ passive = { unhealthy = { timeouts = 1 }}, threshold = true}, number },

        --]]
      }

      for _, test in ipairs(tests) do
        local entity = {
          name = "x",
          healthchecks = test[1],
        }
        local ok, err = Upstreams:validate(entity)
        assert.falsy(ok)

        local leaf = err
        repeat
          leaf = leaf[next(leaf)]
          local tnext = type(leaf) == "table" and type(next(leaf))
        until type(leaf) ~= "table" or not (tnext == "string" or tnext == "number")
        assert.match(test[2], leaf, 1, true, inspect(err))
      end
    end)

    -- acceptance
    it("accepts inputs with the correct values", function()
      local tests = {
        { active = { timeout = 0.5 }},
        { active = { timeout = 1 }},
        { active = { concurrency = 2 }},
        { active = { http_path = "/" }},
        { active = { http_path = "/test" }},
        { active = { https_sni = "example.com" }},
        { active = { https_sni = "example.test.", }},
        { active = { https_verify_certificate = false }},
        { active = { healthy = { interval = 0 }}},
        { active = { healthy = { http_statuses = { 200, 300 } }}},
        { active = { healthy = { successes = 2 }}},
        { active = { healthy = { successes = 255 }}},
        { active = { unhealthy = { interval = 0 }}},
        { active = { unhealthy = { http_statuses = { 404 }}}},
        { active = { unhealthy = { tcp_failures = 3 }}},
        { active = { unhealthy = { tcp_failures = 255 }}},
        { active = { unhealthy = { timeouts = 9 }}},
        { active = { unhealthy = { timeouts = 255 }}},
        { active = { unhealthy = { http_failures = 2 }}},
        { active = { unhealthy = { http_failures = 2 }}, threshold = 0},
        { active = { unhealthy = { http_failures = 2 }}, threshold = 50.50},
        { active = { unhealthy = { http_failures = 2 }}, threshold = 100},
        { passive = { healthy = { http_statuses = { 200, 201 } }}},
        { passive = { healthy = { successes = 2 }}},
        { passive = { healthy = { successes = 255 }}},
        { passive = { unhealthy = { http_statuses = { 400, 500 } }}},
        { passive = { unhealthy = { tcp_failures = 8 }}},
        { passive = { unhealthy = { tcp_failures = 255 }}},
        { passive = { unhealthy = { timeouts = 1 }}},
        { passive = { unhealthy = { timeouts = 255 }}},
        { passive = { unhealthy = { http_failures = 2 }}},
        { passive = { unhealthy = { http_failures = 255 }}},
        { passive = { unhealthy = { http_failures = 2 }}, threshold = 0},
        { passive = { unhealthy = { http_failures = 2 }}, threshold = 50.50},
        { passive = { unhealthy = { http_failures = 2 }}, threshold = 100},
      }
      for _, test in ipairs(tests) do
        local entity = {
          name = "x",
          healthchecks = test,
        }
        local ok, err = Upstreams:validate(entity)
        assert.truthy(ok)
        assert.is_nil(err)
      end
    end)
  end)
end)
