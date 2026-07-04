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

return TestRepository

