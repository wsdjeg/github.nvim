-- test/pulls_spec.lua
local lu = require('luaunit')
local helpers = require('helpers')
local pulls = require('github.pulls')

TestPulls = {}

-- ============================================================
-- Sync API
-- ============================================================

function TestPulls:testList()
  local captured, restore = helpers.mock_util()
  pulls.list('wsdjeg', 'github.nvim')
  restore()

  lu.assertEquals(captured.sync[1].path, 'repos/wsdjeg/github.nvim/pulls?state=open')
end

function TestPulls:testListWithState()
  local captured, restore = helpers.mock_util()
  pulls.list('wsdjeg', 'github.nvim', 'closed')
  restore()

  lu.assertEquals(captured.sync[1].path, 'repos/wsdjeg/github.nvim/pulls?state=closed')
end

function TestPulls:testGet()
  local captured, restore = helpers.mock_util()
  pulls.get('wsdjeg', 'github.nvim', 99)
  restore()

  lu.assertEquals(captured.sync[1].path, 'repos/wsdjeg/github.nvim/pulls/99')
end

function TestPulls:testCreate()
  local captured, restore = helpers.mock_util()
  pulls.create('wsdjeg', 'github.nvim', { title = 'PR', head = 'feat', base = 'main' })
  restore()

  lu.assertEquals(captured.sync[1].path, 'repos/wsdjeg/github.nvim/pulls')
  lu.assertEquals(captured.sync[1].args[2], 'POST')
  local body = vim.json.decode(captured.sync[1].args[4])
  lu.assertEquals(body.title, 'PR')
  lu.assertEquals(body.head, 'feat')
  lu.assertEquals(body.base, 'main')
end

function TestPulls:testUpdate()
  local captured, restore = helpers.mock_util()
  pulls.update('wsdjeg', 'github.nvim', 99, { title = 'Updated' })
  restore()

  lu.assertEquals(captured.sync[1].path, 'repos/wsdjeg/github.nvim/pulls/99')
  lu.assertEquals(captured.sync[1].args[2], 'PATCH')
end

function TestPulls:testListCommits()
  local captured, restore = helpers.mock_util()
  pulls.list_commits('wsdjeg', 'github.nvim', 99)
  restore()

  lu.assertEquals(captured.sync[1].path, 'repos/wsdjeg/github.nvim/pulls/99/commits')
end

function TestPulls:testListFiles()
  local captured, restore = helpers.mock_util()
  pulls.list_files('wsdjeg', 'github.nvim', 99)
  restore()

  lu.assertEquals(captured.sync[1].path, 'repos/wsdjeg/github.nvim/pulls/99/files')
end

function TestPulls:testMerge()
  local captured, restore = helpers.mock_util()
  pulls.merge('wsdjeg', 'github.nvim', 99, { merge_method = 'squash' })
  restore()

  lu.assertEquals(captured.sync[1].path, 'repos/wsdjeg/github.nvim/pulls/99/merge')
  lu.assertEquals(captured.sync[1].args[2], 'PUT')
  local body = vim.json.decode(captured.sync[1].args[4])
  lu.assertEquals(body.merge_method, 'squash')
end

function TestPulls:testMergeDefaultParams()
  local captured, restore = helpers.mock_util()
  pulls.merge('wsdjeg', 'github.nvim', 99)
  restore()

  lu.assertEquals(captured.sync[1].args[2], 'PUT')
  local body = vim.json.decode(captured.sync[1].args[4])
  lu.assertEquals(body, {})
end

function TestPulls:testCreateReview()
  local captured, restore = helpers.mock_util()
  pulls.create_review('wsdjeg', 'github.nvim', 99, { event = 'APPROVE' })
  restore()

  lu.assertEquals(captured.sync[1].path, 'repos/wsdjeg/github.nvim/pulls/99/reviews')
  lu.assertEquals(captured.sync[1].args[2], 'POST')
end

function TestPulls:testListReviews()
  local captured, restore = helpers.mock_util()
  pulls.list_reviews('wsdjeg', 'github.nvim', 99)
  restore()

  lu.assertEquals(captured.sync[1].path, 'repos/wsdjeg/github.nvim/pulls/99/reviews')
end

function TestPulls:testCheckMergeStatus()
  local captured, restore = helpers.mock_util()
  pulls.check_merge_status('wsdjeg', 'github.nvim', 99)
  restore()

  lu.assertEquals(captured.sync[1].path, 'repos/wsdjeg/github.nvim/pulls/99/merge')
end

-- ============================================================
-- Async API
-- ============================================================

function TestPulls:testListAsync()
  local captured, restore = helpers.mock_util()
  pulls.list_async('wsdjeg', 'github.nvim', 'all', {})
  restore()

  lu.assertEquals(captured.async[1].method, 'GET')
  lu.assertEquals(captured.async[1].path, 'repos/wsdjeg/github.nvim/pulls?state=all')
end

function TestPulls:testListAsyncDefaultState()
  local captured, restore = helpers.mock_util()
  pulls.list_async('wsdjeg', 'github.nvim', nil, {})
  restore()

  lu.assertEquals(captured.async[1].path, 'repos/wsdjeg/github.nvim/pulls?state=open')
end

function TestPulls:testGetAsync()
  local captured, restore = helpers.mock_util()
  pulls.get_async('wsdjeg', 'github.nvim', 99, {})
  restore()

  lu.assertEquals(captured.async[1].path, 'repos/wsdjeg/github.nvim/pulls/99')
end

function TestPulls:testCreateAsync()
  local captured, restore = helpers.mock_util()
  pulls.create_async('wsdjeg', 'github.nvim', { title = 'PR' }, {})
  restore()

  lu.assertEquals(captured.async[1].method, 'POST')
  lu.assertEquals(captured.async[1].path, 'repos/wsdjeg/github.nvim/pulls')
end

function TestPulls:testMergeAsync()
  local captured, restore = helpers.mock_util()
  pulls.merge_async('wsdjeg', 'github.nvim', 99, {}, {})
  restore()

  lu.assertEquals(captured.async[1].method, 'PUT')
  lu.assertEquals(captured.async[1].path, 'repos/wsdjeg/github.nvim/pulls/99/merge')
end

function TestPulls:testCreateReviewAsync()
  local captured, restore = helpers.mock_util()
  pulls.create_review_async('wsdjeg', 'github.nvim', 99, { event = 'COMMENT' }, {})
  restore()

  lu.assertEquals(captured.async[1].method, 'POST')
  lu.assertEquals(captured.async[1].path, 'repos/wsdjeg/github.nvim/pulls/99/reviews')
end

return TestPulls

