-- test/github_issue_spec.lua
-- Tests for lua/chat/tools/github_issue.lua
local lu = require('luaunit')
local helpers = require('helpers')
local issue_tool = require('chat.tools.github_issue')

TestGithubIssueTool = {}

-- ============================================================
-- Helper: capture callbacks passed to the async API
-- ============================================================

--- Mock util and additionally capture the callbacks so tests can fire them
--- @return table captured, function restore, table cbs
local function mock_with_callbacks()
  local captured, restore = helpers.mock_util()
  local cbs = {}

  local util = require('github.util')

  -- helpers.lua mocks ignore the callbacks argument; re-wrap to capture them
  util.get_async = function(path, callbacks, opts)
    table.insert(captured.async, { method = 'GET', path = path })
    cbs.last = callbacks
    return 1
  end
  util.post_async = function(path, body, callbacks, opts)
    table.insert(captured.async, { method = 'POST', path = path, body = body })
    cbs.last = callbacks
    return 1
  end
  util.patch_async = function(path, body, callbacks, opts)
    table.insert(captured.async, { method = 'PATCH', path = path, body = body })
    cbs.last = callbacks
    return 1
  end

  -- single restore puts the real implementations back
  return captured, restore, cbs
end

--- Build a fake ctx that records callback invocations
local function make_ctx()
  local results = {}
  return {
    results = results,
    callback = function(r)
      table.insert(results, r)
    end,
  }
end

-- ============================================================
-- Validation
-- ============================================================

function TestGithubIssueTool:testMissingUser()
  local r = issue_tool.github_issue({ repo = 'r', operation = 'list' }, make_ctx())
  lu.assertNotNil(r.error)
  lu.assertStrContains(r.error, 'user')
end

function TestGithubIssueTool:testMissingRepo()
  local r = issue_tool.github_issue({ user = 'u', operation = 'list' }, make_ctx())
  lu.assertNotNil(r.error)
  lu.assertStrContains(r.error, 'repo')
end

function TestGithubIssueTool:testMissingOperation()
  local r = issue_tool.github_issue({ user = 'u', repo = 'r' }, make_ctx())
  lu.assertNotNil(r.error)
  lu.assertStrContains(r.error, 'operation')
end

function TestGithubIssueTool:testUnknownOperation()
  local r = issue_tool.github_issue({ user = 'u', repo = 'r', operation = 'nope' }, make_ctx())
  lu.assertNotNil(r.error)
  lu.assertStrContains(r.error, 'Unknown operation')
end

function TestGithubIssueTool:testIssueNumberRequired()
  local ops = { 'get', 'update_issue', 'list_comments', 'create_comment', 'list_labels', 'list_events' }
  for _, op in ipairs(ops) do
    local r = issue_tool.github_issue({ user = 'u', repo = 'r', operation = op }, make_ctx())
    lu.assertNotNil(r.error, 'expected error for ' .. op)
    lu.assertStrContains(r.error, 'issue_number')
  end
end

function TestGithubIssueTool:testCreateIssueRequiresTitle()
  local r = issue_tool.github_issue({ user = 'u', repo = 'r', operation = 'create_issue' }, make_ctx())
  lu.assertNotNil(r.error)
  lu.assertStrContains(r.error, 'title')
end

function TestGithubIssueTool:testCreateCommentRequiresBody()
  local r = issue_tool.github_issue(
    { user = 'u', repo = 'r', operation = 'create_comment', issue_number = 1 },
    make_ctx()
  )
  lu.assertNotNil(r.error)
  lu.assertStrContains(r.error, 'body')
end

function TestGithubIssueTool:testUpdateIssueRequiresField()
  local r = issue_tool.github_issue(
    { user = 'u', repo = 'r', operation = 'update_issue', issue_number = 1 },
    make_ctx()
  )
  lu.assertNotNil(r.error)
  lu.assertStrContains(r.error, 'at least one')
end

function TestGithubIssueTool:testUpdateIssueInvalidState()
  local r = issue_tool.github_issue(
    { user = 'u', repo = 'r', operation = 'update_issue', issue_number = 1, state = 'invalid' },
    make_ctx()
  )
  lu.assertNotNil(r.error)
  lu.assertStrContains(r.error, 'state')
end

-- ============================================================
-- Dispatch (async paths)
-- ============================================================

function TestGithubIssueTool:testListDispatches()
  local captured, restore, _cbs = mock_with_callbacks()
  local ctx = make_ctx()
  local r = issue_tool.github_issue({ user = 'wsdjeg', repo = 'github.nvim', operation = 'list' }, ctx)
  restore()

  lu.assertEquals(r.jobid, 1)
  lu.assertEquals(captured.async[1].method, 'GET')
  lu.assertEquals(captured.async[1].path, 'repos/wsdjeg/github.nvim/issues?state=open')
end

function TestGithubIssueTool:testListWithFilters()
  local captured, restore, _cbs = mock_with_callbacks()
  local ctx = make_ctx()
  issue_tool.github_issue({
    user = 'wsdjeg',
    repo = 'github.nvim',
    operation = 'list',
    state = 'closed',
    labels = { 'bug' },
    per_page = 10,
  }, ctx)
  restore()

  local path = captured.async[1].path
  lu.assertStrContains(path, 'state=closed')
  lu.assertStrContains(path, 'labels=bug')
  lu.assertStrContains(path, 'per_page=10')
end

function TestGithubIssueTool:testGetDispatches()
  local captured, restore, _cbs = mock_with_callbacks()
  local ctx = make_ctx()
  local r = issue_tool.github_issue({
    user = 'wsdjeg',
    repo = 'github.nvim',
    operation = 'get',
    issue_number = 42,
  }, ctx)
  restore()

  lu.assertEquals(r.jobid, 1)
  lu.assertEquals(captured.async[1].method, 'GET')
  lu.assertEquals(captured.async[1].path, 'repos/wsdjeg/github.nvim/issues/42')
end

function TestGithubIssueTool:testCreateIssueDispatches()
  local captured, restore, _cbs = mock_with_callbacks()
  local ctx = make_ctx()
  issue_tool.github_issue({
    user = 'wsdjeg',
    repo = 'github.nvim',
    operation = 'create_issue',
    title = 'Bug',
    body = 'desc',
    labels = { 'bug' },
  }, ctx)
  restore()

  lu.assertEquals(captured.async[1].method, 'POST')
  lu.assertEquals(captured.async[1].path, 'repos/wsdjeg/github.nvim/issues')
  local body = vim.json.decode(captured.async[1].body)
  lu.assertEquals(body.title, 'Bug')
  lu.assertEquals(body.body, 'desc')
  lu.assertEquals(body.labels[1], 'bug')
end

function TestGithubIssueTool:testUpdateIssueDispatches()
  local captured, restore, _cbs = mock_with_callbacks()
  local ctx = make_ctx()
  issue_tool.github_issue({
    user = 'wsdjeg',
    repo = 'github.nvim',
    operation = 'update_issue',
    issue_number = 42,
    state = 'closed',
  }, ctx)
  restore()

  lu.assertEquals(captured.async[1].method, 'PATCH')
  lu.assertEquals(captured.async[1].path, 'repos/wsdjeg/github.nvim/issues/42')
  local body = vim.json.decode(captured.async[1].body)
  lu.assertEquals(body.state, 'closed')
  lu.assertIsNil(body.title)
end

function TestGithubIssueTool:testListCommentsDispatches()
  local captured, restore, _cbs = mock_with_callbacks()
  local ctx = make_ctx()
  issue_tool.github_issue({
    user = 'wsdjeg',
    repo = 'github.nvim',
    operation = 'list_comments',
    issue_number = 42,
  }, ctx)
  restore()

  lu.assertEquals(captured.async[1].method, 'GET')
  lu.assertEquals(captured.async[1].path, 'repos/wsdjeg/github.nvim/issues/42/comments')
end

function TestGithubIssueTool:testCreateCommentDispatches()
  local captured, restore, _cbs = mock_with_callbacks()
  local ctx = make_ctx()
  issue_tool.github_issue({
    user = 'wsdjeg',
    repo = 'github.nvim',
    operation = 'create_comment',
    issue_number = 42,
    body = 'LGTM',
  }, ctx)
  restore()

  lu.assertEquals(captured.async[1].method, 'POST')
  lu.assertEquals(captured.async[1].path, 'repos/wsdjeg/github.nvim/issues/42/comments')
  local body = vim.json.decode(captured.async[1].body)
  lu.assertEquals(body.body, 'LGTM')
end

function TestGithubIssueTool:testListLabelsDispatches()
  local captured, restore, _cbs = mock_with_callbacks()
  local ctx = make_ctx()
  issue_tool.github_issue({
    user = 'wsdjeg',
    repo = 'github.nvim',
    operation = 'list_labels',
    issue_number = 42,
  }, ctx)
  restore()

  lu.assertEquals(captured.async[1].path, 'repos/wsdjeg/github.nvim/issues/42/labels')
end

function TestGithubIssueTool:testListEventsDispatches()
  local captured, restore, _cbs = mock_with_callbacks()
  local ctx = make_ctx()
  issue_tool.github_issue({
    user = 'wsdjeg',
    repo = 'github.nvim',
    operation = 'list_events',
    issue_number = 42,
  }, ctx)
  restore()

  lu.assertEquals(captured.async[1].path, 'repos/wsdjeg/github.nvim/issues/42/events')
end

-- ============================================================
-- Callback formatting
-- ============================================================

function TestGithubIssueTool:testOnSuccessList()
  local captured, restore, cbs = mock_with_callbacks()
  local ctx = make_ctx()
  issue_tool.github_issue({ user = 'wsdjeg', repo = 'github.nvim', operation = 'list' }, ctx)
  cbs.last.on_success(7, {
    {
      number = 1,
      title = 'First issue',
      state = 'open',
      user = { login = 'alice' },
      labels = { { name = 'bug' } },
    },
    {
      number = 2,
      title = 'Second issue',
      state = 'closed',
    },
  }, 200)
  restore()

  lu.assertEquals(#ctx.results, 1)
  lu.assertEquals(ctx.results[1].jobid, 7)
  local content = ctx.results[1].content
  lu.assertStrContains(content, 'Issues for wsdjeg/github.nvim (2)')
  lu.assertStrContains(content, '#1 First issue')
  lu.assertStrContains(content, '#2 Second issue')
  lu.assertStrContains(content, 'Author: alice')
  lu.assertStrContains(content, 'Labels: bug')
end

function TestGithubIssueTool:testOnSuccessGet()
  local captured, restore, cbs = mock_with_callbacks()
  local ctx = make_ctx()
  issue_tool.github_issue({
    user = 'wsdjeg',
    repo = 'github.nvim',
    operation = 'get',
    issue_number = 42,
  }, ctx)
  cbs.last.on_success(9, {
    number = 42,
    title = 'Crash on startup',
    state = 'open',
    body = 'line one\nline two',
    html_url = 'https://github.com/wsdjeg/github.nvim/issues/42',
  }, 200)
  restore()

  local content = ctx.results[1].content
  lu.assertStrContains(content, 'Issue wsdjeg/github.nvim#42')
  lu.assertStrContains(content, 'Title: Crash on startup')
  lu.assertStrContains(content, '    line one')
  lu.assertStrContains(content, '    line two')
  lu.assertStrContains(content, 'URL: https://github.com')
end

function TestGithubIssueTool:testOnSuccessComments()
  local captured, restore, cbs = mock_with_callbacks()
  local ctx = make_ctx()
  issue_tool.github_issue({
    user = 'wsdjeg',
    repo = 'github.nvim',
    operation = 'list_comments',
    issue_number = 5,
  }, ctx)
  cbs.last.on_success(3, {
    { id = 111, user = { login = 'bob' }, body = 'Thanks!' },
  }, 200)
  restore()

  local content = ctx.results[1].content
  lu.assertStrContains(content, 'Comments for wsdjeg/github.nvim#5 (1)')
  lu.assertStrContains(content, 'Comment ID: 111 by bob')
  lu.assertStrContains(content, '    Thanks!')
end

function TestGithubIssueTool:testOnSuccessLabels()
  local captured, restore, cbs = mock_with_callbacks()
  local ctx = make_ctx()
  issue_tool.github_issue({
    user = 'wsdjeg',
    repo = 'github.nvim',
    operation = 'list_labels',
    issue_number = 5,
  }, ctx)
  cbs.last.on_success(3, {
    { name = 'bug', color = 'd73a4a', description = 'Something is broken' },
  }, 200)
  restore()

  local content = ctx.results[1].content
  lu.assertStrContains(content, 'Labels for wsdjeg/github.nvim#5 (1)')
  lu.assertStrContains(content, 'bug')
  lu.assertStrContains(content, '[#d73a4a]')
  lu.assertStrContains(content, 'Something is broken')
end

function TestGithubIssueTool:testOnSuccessEvents()
  local captured, restore, cbs = mock_with_callbacks()
  local ctx = make_ctx()
  issue_tool.github_issue({
    user = 'wsdjeg',
    repo = 'github.nvim',
    operation = 'list_events',
    issue_number = 5,
  }, ctx)
  cbs.last.on_success(3, {
    { id = 1, event = 'labeled', actor = { login = 'carol' }, label = { name = 'bug' } },
  }, 200)
  restore()

  local content = ctx.results[1].content
  lu.assertStrContains(content, 'Events for wsdjeg/github.nvim#5 (1)')
  lu.assertStrContains(content, 'Event: labeled')
  lu.assertStrContains(content, 'Actor: carol')
  lu.assertStrContains(content, 'Label: bug')
end

function TestGithubIssueTool:testOnError()
  local captured, restore, cbs = mock_with_callbacks()
  local ctx = make_ctx()
  issue_tool.github_issue({ user = 'wsdjeg', repo = 'github.nvim', operation = 'list' }, ctx)
  cbs.last.on_error(4, 'Not Found', 404)
  restore()

  lu.assertEquals(#ctx.results, 1)
  lu.assertEquals(ctx.results[1].jobid, 4)
  lu.assertStrContains(ctx.results[1].error, 'GitHub API error: Not Found')
  lu.assertStrContains(ctx.results[1].error, 'HTTP 404')
end

function TestGithubIssueTool:testOnErrorWithoutHttpCode()
  local captured, restore, cbs = mock_with_callbacks()
  local ctx = make_ctx()
  issue_tool.github_issue({ user = 'wsdjeg', repo = 'github.nvim', operation = 'list' }, ctx)
  cbs.last.on_error(4, 'network unreachable')
  restore()

  lu.assertStrContains(ctx.results[1].error, 'GitHub API error: network unreachable')
  lu.assertIsNil(ctx.results[1].error:match('HTTP'))
end

-- ============================================================
-- scheme / info
-- ============================================================

function TestGithubIssueTool:testScheme()
  local s = issue_tool.scheme()
  lu.assertEquals(s.type, 'function')
  lu.assertEquals(s['function'].name, 'github_issue')
  lu.assertEquals(#s['function'].parameters.required, 3)
  lu.assertEquals(s['function'].parameters.required[1], 'user')
  lu.assertEquals(s['function'].parameters.required[2], 'repo')
  lu.assertEquals(s['function'].parameters.required[3], 'operation')
  -- all enum values must be in the valid ops list
  local ops = s['function'].parameters.properties.operation.enum
  lu.assertEquals(#ops, 8)
end

function TestGithubIssueTool:testInfo()
  lu.assertEquals(issue_tool.info('not json'), 'github_issue')
  lu.assertEquals(issue_tool.info(nil), 'github_issue')

  local str = issue_tool.info(vim.json.encode({
    user = 'wsdjeg',
    repo = 'github.nvim',
    operation = 'get',
    issue_number = 42,
  }))
  lu.assertEquals(str, 'github_issue wsdjeg/github.nvim op=get issue=42')

  local str2 = issue_tool.info({
    user = 'wsdjeg',
    repo = 'github.nvim',
    operation = 'update_issue',
    issue_number = 3,
    state = 'closed',
  })
  lu.assertEquals(str2, 'github_issue wsdjeg/github.nvim op=update_issue issue=3 state=closed')
end

return TestGithubIssueTool

