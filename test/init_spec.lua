-- test/init_spec.lua
local lu = require('luaunit')
local github = require('github')
local util = require('github.util')

TestInit = {}

function TestInit:testSetupDefaultConfig()
  github.setup()
  lu.assertEquals(github.config.base_url, 'https://api.github.com/')
end

function TestInit:testSetupCustomBaseUrl()
  github.setup({ base_url = 'https://github.enterprise.com/api/v3/' })
  lu.assertEquals(github.config.base_url, 'https://github.enterprise.com/api/v3/')

  -- Restore default
  github.setup({ base_url = 'https://api.github.com/' })
end

function TestInit:testSetupToken()
  -- Token is write-only: setup passes it to util.set_token internally
  -- Verify it works by checking that requests include the token
  local util = require('github.util')
  local orig = vim.fn.systemlist
  local captured = nil
  vim.fn.systemlist = function(cmd)
    captured = cmd
    return { '{}' }
  end

  github.setup({ token = 'custom-token-123' })
  util.request('repos/test/repo')

  vim.fn.systemlist = orig

  local cmd_str = table.concat(captured, ' ')
  lu.assertStrContains(cmd_str, 'Authorization: token custom-token-123')

  -- Token should NOT be in public config
  lu.assertIsNil(github.config.token)

  -- Cleanup
  util.set_token(nil)
  github.setup()
end

function TestInit:testModulesLoaded()
  lu.assertNotNil(github.issues)
  lu.assertNotNil(github.pulls)
  lu.assertNotNil(github.repository)
  lu.assertNotNil(github.secrets)
  lu.assertNotNil(github.rulesets)
  lu.assertNotNil(github.actions)
  lu.assertNotNil(github.releases)
  lu.assertNotNil(github.search)
  lu.assertNotNil(github.users)
  lu.assertNotNil(github.util)
end

function TestInit:testSetupNilOpts()
  github.setup(nil)
  lu.assertNotNil(github.config)
end

return TestInit

