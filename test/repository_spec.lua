-- test/repository_spec.lua
local lu = require('luaunit')
local helpers = require('helpers')
local repository = require('github.repository')

TestRepository = {}

-- ============================================================
-- Sync API
-- ============================================================

function TestRepository:testUpdate()
  local captured, restore = helpers.mock_util()
  repository.update('wsdjeg', 'github.nvim', { description = 'Updated desc' })
  restore()

  lu.assertEquals(captured.sync[1].path, 'repos/wsdjeg/github.nvim')
  lu.assertEquals(captured.sync[1].args[2], 'PATCH')
  local body = vim.json.decode(captured.sync[1].args[4])
  lu.assertEquals(body.description, 'Updated desc')
end

function TestRepository:testUpdateWithMultipleFields()
  local captured, restore = helpers.mock_util()
  repository.update('wsdjeg', 'github.nvim', {
    private = true,
    has_issues = false,
    default_branch = 'develop',
  })
  restore()

  local body = vim.json.decode(captured.sync[1].args[4])
  lu.assertEquals(body.private, true)
  lu.assertEquals(body.has_issues, false)
  lu.assertEquals(body.default_branch, 'develop')
end

function TestRepository:testGet()
  local captured, restore = helpers.mock_util()
  repository.get('wsdjeg', 'github.nvim')
  restore()

  lu.assertEquals(captured.sync[1].path, 'repos/wsdjeg/github.nvim')
  -- GET request should have no extra args
  lu.assertIsNil(captured.sync[1].args)
end

function TestRepository:testGetReadme()
  local captured, restore = helpers.mock_util()
  repository.get_readme('wsdjeg', 'github.nvim')
  restore()

  lu.assertEquals(captured.sync[1].path, 'repos/wsdjeg/github.nvim/readme')
end

function TestRepository:testGetReadmeWithRef()
  local captured, restore = helpers.mock_util()
  repository.get_readme('wsdjeg', 'github.nvim', 'develop')
  restore()

  lu.assertEquals(captured.sync[1].path, 'repos/wsdjeg/github.nvim/readme?ref=develop')
end

function TestRepository:testGetContents()
  local captured, restore = helpers.mock_util()
  repository.get_contents('wsdjeg', 'github.nvim', 'lua/github/init.lua')
  restore()

  lu.assertEquals(captured.sync[1].path, 'repos/wsdjeg/github.nvim/contents/lua/github/init.lua')
end

function TestRepository:testGetContentsWithRef()
  local captured, restore = helpers.mock_util()
  repository.get_contents('wsdjeg', 'github.nvim', 'lua/github', 'develop')
  restore()

  lu.assertEquals(captured.sync[1].path, 'repos/wsdjeg/github.nvim/contents/lua/github?ref=develop')
end

function TestRepository:testGetTree()
  local captured, restore = helpers.mock_util()
  repository.get_tree('wsdjeg', 'github.nvim', 'master')
  restore()

  lu.assertEquals(captured.sync[1].path, 'repos/wsdjeg/github.nvim/git/trees/master')
  lu.assertIsNil(captured.sync[1].args)
end

function TestRepository:testGetTreeRecursive()
  local captured, restore = helpers.mock_util()
  repository.get_tree('wsdjeg', 'github.nvim', 'master', true)
  restore()

  lu.assertEquals(captured.sync[1].path, 'repos/wsdjeg/github.nvim/git/trees/master?recursive=1')
end

function TestRepository:testGetTreeWithCommitSha()
  local captured, restore = helpers.mock_util()
  repository.get_tree('wsdjeg', 'github.nvim', 'abc123def456')
  restore()

  lu.assertEquals(captured.sync[1].path, 'repos/wsdjeg/github.nvim/git/trees/abc123def456')
end

-- ============================================================
-- Async API
-- ============================================================

function TestRepository:testUpdateAsync()
  local captured, restore = helpers.mock_util()
  repository.update_async('wsdjeg', 'github.nvim', { description = 'New' }, {})
  restore()

  lu.assertEquals(captured.async[1].method, 'PATCH')
  lu.assertEquals(captured.async[1].path, 'repos/wsdjeg/github.nvim')
end

function TestRepository:testGetAsync()
  local captured, restore = helpers.mock_util()
  repository.get_async('wsdjeg', 'github.nvim', {})
  restore()

  lu.assertEquals(captured.async[1].method, 'GET')
  lu.assertEquals(captured.async[1].path, 'repos/wsdjeg/github.nvim')
end

function TestRepository:testGetReadmeAsync()
  local captured, restore = helpers.mock_util()
  repository.get_readme_async('wsdjeg', 'github.nvim', nil, {})
  restore()

  lu.assertEquals(captured.async[1].method, 'GET')
  lu.assertEquals(captured.async[1].path, 'repos/wsdjeg/github.nvim/readme')
end

function TestRepository:testGetReadmeAsyncWithRef()
  local captured, restore = helpers.mock_util()
  repository.get_readme_async('wsdjeg', 'github.nvim', 'develop', {})
  restore()

  lu.assertEquals(captured.async[1].path, 'repos/wsdjeg/github.nvim/readme?ref=develop')
end

function TestRepository:testGetContentsAsync()
  local captured, restore = helpers.mock_util()
  repository.get_contents_async('wsdjeg', 'github.nvim', 'lua/github/init.lua', nil, {})
  restore()

  lu.assertEquals(captured.async[1].method, 'GET')
  lu.assertEquals(captured.async[1].path, 'repos/wsdjeg/github.nvim/contents/lua/github/init.lua')
end

function TestRepository:testGetContentsAsyncWithRef()
  local captured, restore = helpers.mock_util()
  repository.get_contents_async('wsdjeg', 'github.nvim', 'lua/github', 'develop', {})
  restore()

  lu.assertEquals(captured.async[1].path, 'repos/wsdjeg/github.nvim/contents/lua/github?ref=develop')
end

function TestRepository:testGetTreeAsync()
  local captured, restore = helpers.mock_util()
  repository.get_tree_async('wsdjeg', 'github.nvim', 'master', nil, {})
  restore()

  lu.assertEquals(captured.async[1].method, 'GET')
  lu.assertEquals(captured.async[1].path, 'repos/wsdjeg/github.nvim/git/trees/master')
end

function TestRepository:testGetTreeAsyncRecursive()
  local captured, restore = helpers.mock_util()
  repository.get_tree_async('wsdjeg', 'github.nvim', 'master', true, {})
  restore()

  lu.assertEquals(captured.async[1].method, 'GET')
  lu.assertEquals(captured.async[1].path, 'repos/wsdjeg/github.nvim/git/trees/master?recursive=1')
end

return TestRepository

