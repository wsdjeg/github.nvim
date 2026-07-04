-- test/issues_spec.lua
local lu = require('luaunit')
local helpers = require('helpers')
local issues = require('github.issues')

TestIssues = {}

-- ============================================================
-- Sync API
-- ============================================================

function TestIssues:testGet()
  local captured, restore = helpers.mock_util()
  issues.get('wsdjeg', 'github.nvim', 42)
  restore()

  lu.assertEquals(#captured.sync, 1)
  lu.assertEquals(captured.sync[1].path, 'repos/wsdjeg/github.nvim/issues/42')
  lu.assertIsNil(captured.sync[1].args)
end

function TestIssues:testCreateIssue()
  local captured, restore = helpers.mock_util()
  local issue = { title = 'Bug report', body = 'Something is wrong' }
  issues.create_issue('wsdjeg', 'github.nvim', issue)
  restore()

  lu.assertEquals(#captured.sync, 1)
  lu.assertEquals(captured.sync[1].path, 'repos/wsdjeg/github.nvim/issues')
  lu.assertNotNil(captured.sync[1].args)
  lu.assertEquals(captured.sync[1].args[1], '-X')
  lu.assertEquals(captured.sync[1].args[2], 'POST')
  lu.assertEquals(captured.sync[1].args[3], '-d')
  local body = vim.json.decode(captured.sync[1].args[4])
  lu.assertEquals(body.title, 'Bug report')
end

function TestIssues:testUpdateIssue()
  local captured, restore = helpers.mock_util()
  issues.update_issue('wsdjeg', 'github.nvim', 42, { state = 'closed' })
  restore()

  lu.assertEquals(captured.sync[1].path, 'repos/wsdjeg/github.nvim/issues/42')
  lu.assertEquals(captured.sync[1].args[2], 'PATCH')
  local body = vim.json.decode(captured.sync[1].args[4])
  lu.assertEquals(body.state, 'closed')
end

-- ============================================================
-- Async API
-- ============================================================

function TestIssues:testGetAsync()
  local captured, restore = helpers.mock_util()
  issues.get_async('wsdjeg', 'github.nvim', 42, {})
  restore()

  lu.assertEquals(#captured.async, 1)
  lu.assertEquals(captured.async[1].method, 'GET')
  lu.assertEquals(captured.async[1].path, 'repos/wsdjeg/github.nvim/issues/42')
end

function TestIssues:testCreateIssueAsync()
  local captured, restore = helpers.mock_util()
  issues.create_issue_async('wsdjeg', 'github.nvim', { title = 'New' }, {})
  restore()

  lu.assertEquals(captured.async[1].method, 'POST')
  lu.assertEquals(captured.async[1].path, 'repos/wsdjeg/github.nvim/issues')
  local body = vim.json.decode(captured.async[1].body)
  lu.assertEquals(body.title, 'New')
end

function TestIssues:testUpdateIssueAsync()
  local captured, restore = helpers.mock_util()
  issues.update_issue_async('wsdjeg', 'github.nvim', 42, { state = 'open' }, {})
  restore()

  lu.assertEquals(captured.async[1].method, 'PATCH')
  lu.assertEquals(captured.async[1].path, 'repos/wsdjeg/github.nvim/issues/42')
end

return TestIssues

