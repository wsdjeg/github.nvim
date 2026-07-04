-- test/search_spec.lua
local lu = require('luaunit')
local helpers = require('helpers')
local search = require('github.search')

TestSearch = {}

-- ============================================================
-- Sync API
-- ============================================================

function TestSearch:testRepositories()
  local captured, restore = helpers.mock_util()
  search.repositories('neovim in:name')
  restore()

  lu.assertStrContains(captured.sync[1].path, 'search/repositories')
  lu.assertStrContains(captured.sync[1].path, 'q=')
  lu.assertStrContains(captured.sync[1].path, 'neovim')
end

function TestSearch:testRepositoriesWithParams()
  local captured, restore = helpers.mock_util()
  search.repositories('neovim in:name', { sort = 'stars', order = 'desc' })
  restore()

  local path = captured.sync[1].path
  lu.assertStrContains(path, 'sort=stars')
  lu.assertStrContains(path, 'order=desc')
end

function TestSearch:testCode()
  local captured, restore = helpers.mock_util()
  search.code('vim.api in:file language:lua')
  restore()

  lu.assertStrContains(captured.sync[1].path, 'search/code')
end

function TestSearch:testIssues()
  local captured, restore = helpers.mock_util()
  search.issues('bug state:open')
  restore()

  lu.assertStrContains(captured.sync[1].path, 'search/issues')
end

function TestSearch:testUsers()
  local captured, restore = helpers.mock_util()
  search.users('tom location:gb')
  restore()

  lu.assertStrContains(captured.sync[1].path, 'search/users')
end

function TestSearch:testCommits()
  local captured, restore = helpers.mock_util()
  search.commits('fix hash:abc123')
  restore()

  lu.assertStrContains(captured.sync[1].path, 'search/commits')
end

function TestSearch:testQueryEncoding()
  local captured, restore = helpers.mock_util()
  search.repositories('hello world')
  restore()

  -- Spaces should be URL-encoded
  lu.assertStrContains(captured.sync[1].path, 'hello%20world')
end

-- ============================================================
-- Async API
-- ============================================================

function TestSearch:testRepositoriesAsync()
  local captured, restore = helpers.mock_util()
  search.repositories_async('neovim in:name', nil, {})
  restore()

  lu.assertEquals(captured.async[1].method, 'GET')
  lu.assertStrContains(captured.async[1].path, 'search/repositories')
end

function TestSearch:testCodeAsync()
  local captured, restore = helpers.mock_util()
  search.code_async('test', nil, {})
  restore()

  lu.assertEquals(captured.async[1].method, 'GET')
  lu.assertStrContains(captured.async[1].path, 'search/code')
end

function TestSearch:testIssuesAsync()
  local captured, restore = helpers.mock_util()
  search.issues_async('bug', nil, {})
  restore()

  lu.assertEquals(captured.async[1].method, 'GET')
  lu.assertStrContains(captured.async[1].path, 'search/issues')
end

function TestSearch:testUsersAsync()
  local captured, restore = helpers.mock_util()
  search.users_async('tom', nil, {})
  restore()

  lu.assertEquals(captured.async[1].method, 'GET')
  lu.assertStrContains(captured.async[1].path, 'search/users')
end

function TestSearch:testCommitsAsync()
  local captured, restore = helpers.mock_util()
  search.commits_async('fix', nil, {})
  restore()

  lu.assertEquals(captured.async[1].method, 'GET')
  lu.assertStrContains(captured.async[1].path, 'search/commits')
end

return TestSearch

