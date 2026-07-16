-- test/example_spec.lua
-- Example test file demonstrating github.nvim test structure

local lu = require('luaunit')
local github = require('github')

TestExample = {}

function TestExample:setUp()
  -- Set up test environment
  self.github = github
end

function TestExample:tearDown()
  -- Clean up after each test
end

function TestExample:test_module_loaded()
  lu.assertNotNil(self.github)
end

function TestExample:test_setup_config_defaults()
  -- Verify default config values
  lu.assertEquals(self.github.config.base_url, 'https://api.github.com/')
end

function TestExample:test_modules_exist()
  lu.assertNotNil(self.github.issues)
  lu.assertNotNil(self.github.pulls)
  lu.assertNotNil(self.github.releases)
  lu.assertNotNil(self.github.repository)
  lu.assertNotNil(self.github.rulesets)
  lu.assertNotNil(self.github.search)
  lu.assertNotNil(self.github.secrets)
  lu.assertNotNil(self.github.actions)
  lu.assertNotNil(self.github.users)
  lu.assertNotNil(self.github.util)
end

return TestExample

