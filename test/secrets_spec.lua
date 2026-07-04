-- test/secrets_spec.lua
local lu = require('luaunit')
local helpers = require('helpers')
local secrets = require('github.secrets')

TestSecrets = {}

-- ============================================================
-- Sync API
-- ============================================================

function TestSecrets:testListRepositorySecrets()
  local captured, restore = helpers.mock_util()
  secrets.list_repository_secrets('wsdjeg', 'github.nvim')
  restore()

  lu.assertEquals(captured.sync[1].path, 'repos/wsdjeg/github.nvim/actions/secrets')
end

function TestSecrets:testDeleteRepositorySecret()
  local captured, restore = helpers.mock_util()
  secrets.delete_repository_secret('wsdjeg', 'github.nvim', 'MY_SECRET')
  restore()

  lu.assertEquals(captured.sync[1].path, 'repos/wsdjeg/github.nvim/actions/secrets/MY_SECRET')
  lu.assertEquals(captured.sync[1].args[2], 'DELETE')
end

function TestSecrets:testGetRepositorySecretsPublicKey()
  local captured, restore = helpers.mock_util()
  secrets.get_repository_secrets_public_key('wsdjeg', 'github.nvim')
  restore()

  lu.assertEquals(captured.sync[1].path, 'repos/wsdjeg/github.nvim/actions/secrets/public-key')
end

-- ============================================================
-- Async API
-- ============================================================

function TestSecrets:testListRepositorySecretsAsync()
  local captured, restore = helpers.mock_util()
  secrets.list_repository_secrets_async('wsdjeg', 'github.nvim', {})
  restore()

  lu.assertEquals(captured.async[1].method, 'GET')
  lu.assertEquals(captured.async[1].path, 'repos/wsdjeg/github.nvim/actions/secrets')
end

function TestSecrets:testDeleteRepositorySecretAsync()
  local captured, restore = helpers.mock_util()
  secrets.delete_repository_secret_async('wsdjeg', 'github.nvim', 'MY_SECRET', {})
  restore()

  lu.assertEquals(captured.async[1].method, 'DELETE')
  lu.assertEquals(captured.async[1].path, 'repos/wsdjeg/github.nvim/actions/secrets/MY_SECRET')
end

function TestSecrets:testGetRepositorySecretsPublicKeyAsync()
  local captured, restore = helpers.mock_util()
  secrets.get_repository_secrets_public_key_async('wsdjeg', 'github.nvim', {})
  restore()

  lu.assertEquals(captured.async[1].method, 'GET')
  lu.assertEquals(captured.async[1].path, 'repos/wsdjeg/github.nvim/actions/secrets/public-key')
end

return TestSecrets

