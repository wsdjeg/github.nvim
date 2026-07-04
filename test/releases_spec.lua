-- test/releases_spec.lua
local lu = require('luaunit')
local helpers = require('helpers')
local releases = require('github.releases')

TestReleases = {}

-- ============================================================
-- Sync API
-- ============================================================

function TestReleases:testList()
  local captured, restore = helpers.mock_util()
  releases.list('wsdjeg', 'github.nvim')
  restore()

  lu.assertEquals(captured.sync[1].path, 'repos/wsdjeg/github.nvim/releases')
end

function TestReleases:testGetById()
  local captured, restore = helpers.mock_util()
  releases.get_by_id('wsdjeg', 'github.nvim', 123)
  restore()

  lu.assertEquals(captured.sync[1].path, 'repos/wsdjeg/github.nvim/releases/123')
end

function TestReleases:testGetLatest()
  local captured, restore = helpers.mock_util()
  releases.get_latest('wsdjeg', 'github.nvim')
  restore()

  lu.assertEquals(captured.sync[1].path, 'repos/wsdjeg/github.nvim/releases/latest')
end

function TestReleases:testGetByTag()
  local captured, restore = helpers.mock_util()
  releases.get_by_tag('wsdjeg', 'github.nvim', 'v1.0.0')
  restore()

  lu.assertEquals(captured.sync[1].path, 'repos/wsdjeg/github.nvim/releases/tags/v1.0.0')
end

function TestReleases:testCreate()
  local captured, restore = helpers.mock_util()
  releases.create('wsdjeg', 'github.nvim', { tag_name = 'v2.0.0', name = 'Release 2.0' })
  restore()

  lu.assertEquals(captured.sync[1].path, 'repos/wsdjeg/github.nvim/releases')
  lu.assertEquals(captured.sync[1].args[2], 'POST')
  local body = vim.json.decode(captured.sync[1].args[4])
  lu.assertEquals(body.tag_name, 'v2.0.0')
  lu.assertEquals(body.name, 'Release 2.0')
end

function TestReleases:testUpdate()
  local captured, restore = helpers.mock_util()
  releases.update('wsdjeg', 'github.nvim', 123, { body = 'Updated body' })
  restore()

  lu.assertEquals(captured.sync[1].path, 'repos/wsdjeg/github.nvim/releases/123')
  lu.assertEquals(captured.sync[1].args[2], 'PATCH')
end

function TestReleases:testDelete()
  local captured, restore = helpers.mock_util()
  releases.delete('wsdjeg', 'github.nvim', 123)
  restore()

  lu.assertEquals(captured.sync[1].path, 'repos/wsdjeg/github.nvim/releases/123')
  lu.assertEquals(captured.sync[1].args[2], 'DELETE')
end

function TestReleases:testListAssets()
  local captured, restore = helpers.mock_util()
  releases.list_assets('wsdjeg', 'github.nvim', 123)
  restore()

  lu.assertEquals(captured.sync[1].path, 'repos/wsdjeg/github.nvim/releases/123/assets')
end

function TestReleases:testDeleteAsset()
  local captured, restore = helpers.mock_util()
  releases.delete_asset('wsdjeg', 'github.nvim', 456)
  restore()

  lu.assertEquals(captured.sync[1].path, 'repos/wsdjeg/github.nvim/releases/assets/456')
  lu.assertEquals(captured.sync[1].args[2], 'DELETE')
end

-- ============================================================
-- Async API
-- ============================================================

function TestReleases:testListAsync()
  local captured, restore = helpers.mock_util()
  releases.list_async('wsdjeg', 'github.nvim', {})
  restore()

  lu.assertEquals(captured.async[1].method, 'GET')
  lu.assertEquals(captured.async[1].path, 'repos/wsdjeg/github.nvim/releases')
end

function TestReleases:testGetByIdAsync()
  local captured, restore = helpers.mock_util()
  releases.get_by_id_async('wsdjeg', 'github.nvim', 123, {})
  restore()

  lu.assertEquals(captured.async[1].path, 'repos/wsdjeg/github.nvim/releases/123')
end

function TestReleases:testGetLatestAsync()
  local captured, restore = helpers.mock_util()
  releases.get_latest_async('wsdjeg', 'github.nvim', {})
  restore()

  lu.assertEquals(captured.async[1].path, 'repos/wsdjeg/github.nvim/releases/latest')
end

function TestReleases:testGetByTagAsync()
  local captured, restore = helpers.mock_util()
  releases.get_by_tag_async('wsdjeg', 'github.nvim', 'v1.0.0', {})
  restore()

  lu.assertEquals(captured.async[1].path, 'repos/wsdjeg/github.nvim/releases/tags/v1.0.0')
end

function TestReleases:testCreateAsync()
  local captured, restore = helpers.mock_util()
  releases.create_async('wsdjeg', 'github.nvim', { tag_name = 'v1.0' }, {})
  restore()

  lu.assertEquals(captured.async[1].method, 'POST')
  lu.assertEquals(captured.async[1].path, 'repos/wsdjeg/github.nvim/releases')
end

function TestReleases:testDeleteAsync()
  local captured, restore = helpers.mock_util()
  releases.delete_async('wsdjeg', 'github.nvim', 123, {})
  restore()

  lu.assertEquals(captured.async[1].method, 'DELETE')
  lu.assertEquals(captured.async[1].path, 'repos/wsdjeg/github.nvim/releases/123')
end

function TestReleases:testListAssetsAsync()
  local captured, restore = helpers.mock_util()
  releases.list_assets_async('wsdjeg', 'github.nvim', 123, {})
  restore()

  lu.assertEquals(captured.async[1].path, 'repos/wsdjeg/github.nvim/releases/123/assets')
end

return TestReleases

