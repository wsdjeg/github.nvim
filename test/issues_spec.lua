-- test/issues_spec.lua
local lu = require('luaunit')
local helpers = require('helpers')
local issues = require('github.issues')

TestIssues = {}

-- ============================================================
-- Sync API
-- ============================================================

function TestIssues:testList()
  local captured, restore = helpers.mock_util()
  issues.list('wsdjeg', 'github.nvim')
  restore()

  lu.assertEquals(#captured.sync, 1)
  lu.assertEquals(captured.sync[1].path, 'repos/wsdjeg/github.nvim/issues?state=open')
  lu.assertIsNil(captured.sync[1].args)
end

function TestIssues:testListWithParams()
  local captured, restore = helpers.mock_util()
  issues.list('wsdjeg', 'github.nvim', { state = 'closed', sort = 'updated', direction = 'asc', per_page = 20 })
  restore()

  lu.assertEquals(
    captured.sync[1].path,
    'repos/wsdjeg/github.nvim/issues?state=closed&sort=updated&direction=asc&per_page=20'
  )
end

function TestIssues:testListWithLabelsArray()
  local captured, restore = helpers.mock_util()
  issues.list('wsdjeg', 'github.nvim', { labels = { 'bug', 'help wanted' } })
  restore()

  -- comma is legal in a query string so vim.uri_encode leaves it as-is;
  -- space still becomes %20
  lu.assertEquals(captured.sync[1].path, 'repos/wsdjeg/github.nvim/issues?state=open&labels=bug,help%20wanted')
end

function TestIssues:testListDoesNotMutateParams()
  local captured, restore = helpers.mock_util()
  local params = { sort = 'created' }
  issues.list('wsdjeg', 'github.nvim', params)
  restore()

  lu.assertIsNil(params.state)
  lu.assertEquals(params.sort, 'created')
end

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

function TestIssues:testListComments()
  local captured, restore = helpers.mock_util()
  issues.list_comments('wsdjeg', 'github.nvim', 42)
  restore()

  lu.assertEquals(captured.sync[1].path, 'repos/wsdjeg/github.nvim/issues/42/comments')
end

function TestIssues:testListCommentsWithParams()
  local captured, restore = helpers.mock_util()
  issues.list_comments('wsdjeg', 'github.nvim', 42, { per_page = 10, page = 2 })
  restore()

  lu.assertEquals(captured.sync[1].path, 'repos/wsdjeg/github.nvim/issues/42/comments?per_page=10&page=2')
end

function TestIssues:testCreateComment()
  local captured, restore = helpers.mock_util()
  issues.create_comment('wsdjeg', 'github.nvim', 42, 'Thanks for the report!')
  restore()

  lu.assertEquals(captured.sync[1].path, 'repos/wsdjeg/github.nvim/issues/42/comments')
  lu.assertEquals(captured.sync[1].args[2], 'POST')
  local body = vim.json.decode(captured.sync[1].args[4])
  lu.assertEquals(body.body, 'Thanks for the report!')
end

function TestIssues:testListLabels()
  local captured, restore = helpers.mock_util()
  issues.list_labels('wsdjeg', 'github.nvim', 42)
  restore()

  lu.assertEquals(captured.sync[1].path, 'repos/wsdjeg/github.nvim/issues/42/labels')
end

function TestIssues:testListEvents()
  local captured, restore = helpers.mock_util()
  issues.list_events('wsdjeg', 'github.nvim', 42)
  restore()

  lu.assertEquals(captured.sync[1].path, 'repos/wsdjeg/github.nvim/issues/42/events')
end

function TestIssues:testListEventsWithParams()
  local captured, restore = helpers.mock_util()
  issues.list_events('wsdjeg', 'github.nvim', 42, { per_page = 5 })
  restore()

  lu.assertEquals(captured.sync[1].path, 'repos/wsdjeg/github.nvim/issues/42/events?per_page=5')
end

-- ============================================================
-- Async API
-- ============================================================

function TestIssues:testListAsync()
  local captured, restore = helpers.mock_util()
  issues.list_async('wsdjeg', 'github.nvim', nil, {})
  restore()

  lu.assertEquals(#captured.async, 1)
  lu.assertEquals(captured.async[1].method, 'GET')
  lu.assertEquals(captured.async[1].path, 'repos/wsdjeg/github.nvim/issues?state=open')
end

function TestIssues:testListAsyncWithParams()
  local captured, restore = helpers.mock_util()
  issues.list_async('wsdjeg', 'github.nvim', { state = 'closed', assignee = 'wsdjeg' }, {})
  restore()

  lu.assertEquals(captured.async[1].path, 'repos/wsdjeg/github.nvim/issues?state=closed&assignee=wsdjeg')
end

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

function TestIssues:testListCommentsAsync()
  local captured, restore = helpers.mock_util()
  issues.list_comments_async('wsdjeg', 'github.nvim', 42, nil, {})
  restore()

  lu.assertEquals(captured.async[1].method, 'GET')
  lu.assertEquals(captured.async[1].path, 'repos/wsdjeg/github.nvim/issues/42/comments')
end

function TestIssues:testCreateCommentAsync()
  local captured, restore = helpers.mock_util()
  issues.create_comment_async('wsdjeg', 'github.nvim', 42, 'Nice', {})
  restore()

  lu.assertEquals(captured.async[1].method, 'POST')
  lu.assertEquals(captured.async[1].path, 'repos/wsdjeg/github.nvim/issues/42/comments')
  local body = vim.json.decode(captured.async[1].body)
  lu.assertEquals(body.body, 'Nice')
end

function TestIssues:testListLabelsAsync()
  local captured, restore = helpers.mock_util()
  issues.list_labels_async('wsdjeg', 'github.nvim', 42, {})
  restore()

  lu.assertEquals(captured.async[1].method, 'GET')
  lu.assertEquals(captured.async[1].path, 'repos/wsdjeg/github.nvim/issues/42/labels')
end

function TestIssues:testListEventsAsync()
  local captured, restore = helpers.mock_util()
  issues.list_events_async('wsdjeg', 'github.nvim', 42, { page = 3 }, {})
  restore()

  lu.assertEquals(captured.async[1].method, 'GET')
  lu.assertEquals(captured.async[1].path, 'repos/wsdjeg/github.nvim/issues/42/events?page=3')
end

return TestIssues

