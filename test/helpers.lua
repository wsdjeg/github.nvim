-- test/helpers.lua
-- Shared test helpers for mocking github.util

local M = {}

--- Set up mocks for github.util sync/async request methods
--- @return table captured, function restore
---   captured.sync: array of {path, args, output?} for each util.request/download call
---   captured.async: array of {method, path, body?, output?} for each async call
---   restore(): restores original methods
function M.mock_util()
  local util = require('github.util')
  local captured = { sync = {}, async = {} }

  local orig = {
    request = util.request,
    request_async = util.request_async,
    get_async = util.get_async,
    post_async = util.post_async,
    patch_async = util.patch_async,
    put_async = util.put_async,
    delete_async = util.delete_async,
    download = util.download,
    download_async = util.download_async,
    unzip = util.unzip,
  }

  -- Mock sync request
  util.request = function(path, args)
    table.insert(captured.sync, { path = path, args = args })
    return { _mock = true, path = path }
  end

  -- Mock sync download
  util.download = function(path, output)
    table.insert(captured.sync, { path = path, output = output })
    return true, 200
  end

  -- Mock unzip (default: no-op, tests can override)
  util.unzip = function(zip_path, dest_dir)
    return true
  end

  -- Mock async methods
  util.request_async = function(path, args, callbacks, opts)
    table.insert(captured.async, { method = 'REQUEST', path = path, args = args })
    return 1
  end

  util.get_async = function(path, callbacks, opts)
    table.insert(captured.async, { method = 'GET', path = path })
    return 1
  end

  util.post_async = function(path, body, callbacks, opts)
    table.insert(captured.async, { method = 'POST', path = path, body = body })
    return 1
  end

  util.patch_async = function(path, body, callbacks, opts)
    table.insert(captured.async, { method = 'PATCH', path = path, body = body })
    return 1
  end

  util.put_async = function(path, body, callbacks, opts)
    table.insert(captured.async, { method = 'PUT', path = path, body = body })
    return 1
  end

  util.delete_async = function(path, callbacks, opts)
    table.insert(captured.async, { method = 'DELETE', path = path })
    return 1
  end

  util.download_async = function(path, output, callbacks, opts)
    table.insert(captured.async, { method = 'DOWNLOAD', path = path, output = output })
    return 1
  end

  local function restore()
    util.request = orig.request
    util.request_async = orig.request_async
    util.get_async = orig.get_async
    util.post_async = orig.post_async
    util.patch_async = orig.patch_async
    util.put_async = orig.put_async
    util.delete_async = orig.delete_async
    util.download = orig.download
    util.download_async = orig.download_async
    util.unzip = orig.unzip
  end

  return captured, restore
end

return M

