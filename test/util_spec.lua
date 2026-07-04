-- test/util_spec.lua
local lu = require('luaunit')
local util = require('github.util')
local job = require('job')

TestUtil = {}

-- ============================================================
-- set_base_url
-- ============================================================

function TestUtil:testSetBaseUrl()
  util.set_base_url('https://api.github.example.com/')
  -- Verify by checking that request uses the new URL
  local orig_systemlist = vim.fn.systemlist
  local captured_cmd = nil
  vim.fn.systemlist = function(cmd)
    captured_cmd = cmd
    return { '{"ok":true}' }
  end

  util.request('repos/test/repo')

  vim.fn.systemlist = orig_systemlist
  util.set_base_url('https://api.github.com/')

  lu.assertNotNil(captured_cmd)
  -- Last element should be the URL with custom base
  local url = captured_cmd[#captured_cmd]
  lu.assertStrContains(url, 'api.github.example.com')
end

-- ============================================================
-- request (sync)
-- ============================================================

function TestUtil:testRequestReturnsParsedJSON()
  local orig = vim.fn.systemlist
  vim.fn.systemlist = function(cmd)
    return { '{"id":1,"title":"test issue"}' }
  end

  local result = util.request('repos/test/repo/issues/1')

  vim.fn.systemlist = orig
  lu.assertEquals(result.id, 1)
  lu.assertEquals(result.title, 'test issue')
end

function TestUtil:testRequestReturnsEmptyTableOnInvalidJSON()
  local orig = vim.fn.systemlist
  vim.fn.systemlist = function(cmd)
    return { 'not json' }
  end

  local result = util.request('repos/test/repo/issues/1')

  vim.fn.systemlist = orig
  lu.assertEquals(type(result), 'table')
  lu.assertEquals(next(result), nil)
end

function TestUtil:testRequestIncludesHeaders()
  local orig = vim.fn.systemlist
  local captured = nil
  vim.fn.systemlist = function(cmd)
    captured = cmd
    return { '{}' }
  end

  util.request('repos/test/repo/issues/1')

  vim.fn.systemlist = orig
  local cmd_str = table.concat(captured, ' ')
  lu.assertStrContains(cmd_str, 'Accept: application/vnd.github+json')
  lu.assertStrContains(cmd_str, 'X-GitHub-Api-Version: 2022-11-28')
end

function TestUtil:testRequestIncludesToken()
  local orig_token = vim.env.GITHUB_TOKEN
  vim.env.GITHUB_TOKEN = 'my-test-token'

  local orig = vim.fn.systemlist
  local captured = nil
  vim.fn.systemlist = function(cmd)
    captured = cmd
    return { '{}' }
  end

  util.request('repos/test/repo')

  vim.fn.systemlist = orig
  vim.env.GITHUB_TOKEN = orig_token

  local cmd_str = table.concat(captured, ' ')
  lu.assertStrContains(cmd_str, 'Authorization: token my-test-token')
end

function TestUtil:testRequestIncludesExtraArgs()
  local orig = vim.fn.systemlist
  local captured = nil
  vim.fn.systemlist = function(cmd)
    captured = cmd
    return { '{}' }
  end

  util.request('repos/test/repo/issues', { '-X', 'POST', '-d', '{"title":"new"}' })

  vim.fn.systemlist = orig
  local cmd_str = table.concat(captured, ' ')
  lu.assertStrContains(cmd_str, '-X POST')
  lu.assertStrContains(cmd_str, '-d')
  lu.assertStrContains(cmd_str, '{"title":"new"}')
end

function TestUtil:testRequestUrlIsLastElement()
  local orig = vim.fn.systemlist
  local captured = nil
  vim.fn.systemlist = function(cmd)
    captured = cmd
    return { '{}' }
  end

  util.request('repos/test/repo/issues/1')

  vim.fn.systemlist = orig
  local last = captured[#captured]
  lu.assertStrContains(last, 'repos/test/repo/issues/1')
  lu.assertStrContains(last, 'api.github.com')
end

-- ============================================================
-- request_async
-- ============================================================

function TestUtil:setUp()
  job.reset()
end

function TestUtil:testRequestAsyncReturnsJobId()
  job.set_auto_response({
    stdout = { '{"id":1}', '200' },
    stderr = {},
    code = 0,
    signal = 0,
  })

  local jobid = util.request_async('repos/test/repo/issues/1', nil, {
    on_success = function() end,
  })

  lu.assertTrue(jobid > 0)
end

function TestUtil:testRequestAsyncOnSuccess()
  local received_data = nil
  local received_code = nil

  job.set_auto_response({
    stdout = { '{"id":1,"title":"test"}', '200' },
    stderr = {},
    code = 0,
    signal = 0,
  })

  util.request_async('repos/test/repo/issues/1', nil, {
    on_success = function(id, data, http_code)
      received_data = data
      received_code = http_code
    end,
  })

  lu.assertEquals(received_data.id, 1)
  lu.assertEquals(received_code, 200)
end

function TestUtil:testRequestAsyncOnError()
  local received_err = nil
  local received_code = nil

  job.set_auto_response({
    stdout = { '{"message":"Not Found"}', '404' },
    stderr = {},
    code = 0,
    signal = 0,
  })

  util.request_async('repos/test/repo/issues/1', nil, {
    on_error = function(id, err, http_code)
      received_err = err
      received_code = http_code
    end,
  })

  lu.assertEquals(received_err, 'Not Found')
  lu.assertEquals(received_code, 404)
end

function TestUtil:testRequestAsyncOnExit()
  local exit_code = nil
  local exit_signal = nil

  job.set_auto_response({
    stdout = { '{}', '200' },
    stderr = {},
    code = 0,
    signal = 0,
  })

  util.request_async('repos/test/repo', nil, {
    on_exit = function(id, code, signal)
      exit_code = code
      exit_signal = signal
    end,
  })

  lu.assertEquals(exit_code, 0)
  lu.assertEquals(exit_signal, 0)
end

function TestUtil:testRequestAsyncCurlFailure()
  local received_err = nil

  job.set_auto_response({
    stdout = {},
    stderr = { 'curl: connection refused' },
    code = 7,
    signal = 0,
  })

  util.request_async('repos/test/repo', nil, {
    on_error = function(id, err)
      received_err = err
    end,
  })

  lu.assertStrContains(received_err, 'connection refused')
end

function TestUtil:testRequestAsyncTimeout()
  local received_err = nil

  job.set_auto_response({
    stdout = {},
    stderr = {},
    code = 1,
    signal = 15,
  })

  util.request_async('repos/test/repo', nil, {
    on_error = function(id, err)
      received_err = err
    end,
  })

  lu.assertStrContains(received_err, 'timeout')
end

-- ============================================================
-- Convenience async methods
-- ============================================================

function TestUtil:testGetAsync()
  job.set_auto_response({ stdout = { '{}', '200' }, stderr = {}, code = 0, signal = 0 })
  local jobid = util.get_async('repos/test/repo/issues/1', { on_success = function() end })
  lu.assertTrue(jobid > 0)
end

function TestUtil:testPostAsync()
  local captured = nil
  job.set_auto_response({ stdout = { '{}', '201' }, stderr = {}, code = 0, signal = 0 })

  -- Mock request_async to capture args
  local orig = util.request_async
  util.request_async = function(path, args, callbacks, opts)
    captured = { path = path, args = args }
    return 1
  end

  util.post_async('repos/test/repo/issues', '{"title":"new"}', { on_success = function() end })

  util.request_async = orig
  lu.assertEquals(captured.path, 'repos/test/repo/issues')
  lu.assertEquals(captured.args[1], '-X')
  lu.assertEquals(captured.args[2], 'POST')
  lu.assertEquals(captured.args[3], '-d')
  lu.assertEquals(captured.args[4], '{"title":"new"}')
end

function TestUtil:testPatchAsync()
  local captured = nil
  local orig = util.request_async
  util.request_async = function(path, args, callbacks, opts)
    captured = { path = path, args = args }
    return 1
  end

  util.patch_async('repos/test/repo/issues/1', '{"state":"closed"}', { on_success = function() end })

  util.request_async = orig
  lu.assertEquals(captured.args[2], 'PATCH')
  lu.assertEquals(captured.args[4], '{"state":"closed"}')
end

function TestUtil:testPutAsync()
  local captured = nil
  local orig = util.request_async
  util.request_async = function(path, args, callbacks, opts)
    captured = { path = path, args = args }
    return 1
  end

  util.put_async('repos/test/repo/issues/1', '{"body":"updated"}', { on_success = function() end })

  util.request_async = orig
  lu.assertEquals(captured.args[2], 'PUT')
end

function TestUtil:testDeleteAsync()
  local captured = nil
  local orig = util.request_async
  util.request_async = function(path, args, callbacks, opts)
    captured = { path = path, args = args }
    return 1
  end

  util.delete_async('repos/test/repo/issues/1', { on_success = function() end })

  util.request_async = orig
  lu.assertEquals(captured.args[1], '-X')
  lu.assertEquals(captured.args[2], 'DELETE')
end

-- ============================================================
-- pending_count & cancel
-- ============================================================

function TestUtil:testPendingCountInitial()
  -- Clear pending
  for k in pairs(util._pending) do
    util._pending[k] = nil
  end
  lu.assertEquals(util.pending_count(), 0)
end
function TestUtil:testPendingCountAfterAsyncRequest()
  -- Clear pending
  for k in pairs(util._pending) do
    util._pending[k] = nil
  end

  -- Manually add entries to _pending to test pending_count
  util._pending[100] = { path = 'repos/test/repo', start_time = vim.loop.hrtime() }
  lu.assertEquals(util.pending_count(), 1)

  util._pending[101] = { path = 'repos/test/repo2', start_time = vim.loop.hrtime() }
  lu.assertEquals(util.pending_count(), 2)

  util._pending[100] = nil
  lu.assertEquals(util.pending_count(), 1)

  util._pending[101] = nil
  lu.assertEquals(util.pending_count(), 0)
end

function TestUtil:testCancel()
  for k in pairs(util._pending) do
    util._pending[k] = nil
  end

  -- Add a fake pending request
  util._pending[100] = { path = 'test', start_time = 0 }
  lu.assertEquals(util.pending_count(), 1)

  util.cancel(100)
  lu.assertEquals(util.pending_count(), 0)
end

return TestUtil

