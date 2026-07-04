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
  local orig_token = vim.env.GITHUB_TOKEN
  github.setup({ token = 'custom-token-123' })
  lu.assertEquals(vim.env.GITHUB_TOKEN, 'custom-token-123')
  vim.env.GITHUB_TOKEN = orig_token
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

