-- test/rulesets_spec.lua
local lu = require('luaunit')
local helpers = require('helpers')
local rulesets = require('github.rulesets')

TestRulesets = {}

-- ============================================================
-- Sync API
-- ============================================================

function TestRulesets:testGetRepositoryRules()
  local captured, restore = helpers.mock_util()
  rulesets.get_repository_rules('wsdjeg', 'github.nvim')
  restore()

  lu.assertEquals(captured.sync[1].path, 'repos/wsdjeg/github.nvim/rulesets')
end

function TestRulesets:testGetBranchRules()
  local captured, restore = helpers.mock_util()
  rulesets.get_branch_rules('wsdjeg', 'github.nvim', 'main')
  restore()

  lu.assertEquals(captured.sync[1].path, 'repos/wsdjeg/github.nvim/rules/branches/main')
end

function TestRulesets:testCreateRuleset()
  local captured, restore = helpers.mock_util()
  rulesets.create_ruleset('wsdjeg', 'github.nvim', { name = 'rule1' })
  restore()

  lu.assertEquals(captured.sync[1].path, 'repos/wsdjeg/github.nvim/rulesets')
  lu.assertEquals(captured.sync[1].args[2], 'POST')
  local body = vim.json.decode(captured.sync[1].args[4])
  lu.assertEquals(body.name, 'rule1')
end

function TestRulesets:testGetRepositoryRuleset()
  local captured, restore = helpers.mock_util()
  rulesets.get_repository_ruleset('wsdjeg', 'github.nvim', 42)
  restore()

  lu.assertEquals(captured.sync[1].path, 'repos/wsdjeg/github.nvim/rulesets/42')
end

function TestRulesets:testUpdateRuleset()
  local captured, restore = helpers.mock_util()
  rulesets.update_ruleset('wsdjeg', 'github.nvim', 42, { name = 'updated' })
  restore()

  lu.assertEquals(captured.sync[1].path, 'repos/wsdjeg/github.nvim/rulesets/42')
  lu.assertEquals(captured.sync[1].args[2], 'PUT')
end

function TestRulesets:testDeleteRuleset()
  local captured, restore = helpers.mock_util()
  rulesets.delete_ruleset('wsdjeg', 'github.nvim', 42)
  restore()

  lu.assertEquals(captured.sync[1].path, 'repos/wsdjeg/github.nvim/rulesets/42')
  lu.assertEquals(captured.sync[1].args[2], 'DELETE')
end

function TestRulesets:testGetRulesetHistory()
  local captured, restore = helpers.mock_util()
  rulesets.get_ruleset_history('wsdjeg', 'github.nvim', 42)
  restore()

  lu.assertEquals(captured.sync[1].path, 'repos/wsdjeg/github.nvim/rulesets/42/history')
end

function TestRulesets:testGetRulesetVersion()
  local captured, restore = helpers.mock_util()
  rulesets.get_ruleset_version('wsdjeg', 'github.nvim', 42, 3)
  restore()

  lu.assertEquals(captured.sync[1].path, 'repos/wsdjeg/github.nvim/rulesets/42/history/3')
end

-- ============================================================
-- Async API
-- ============================================================

function TestRulesets:testGetRepositoryRulesAsync()
  local captured, restore = helpers.mock_util()
  rulesets.get_repository_rules_async('wsdjeg', 'github.nvim', {})
  restore()

  lu.assertEquals(captured.async[1].method, 'GET')
  lu.assertEquals(captured.async[1].path, 'repos/wsdjeg/github.nvim/rulesets')
end

function TestRulesets:testGetBranchRulesAsync()
  local captured, restore = helpers.mock_util()
  rulesets.get_branch_rules_async('wsdjeg', 'github.nvim', 'main', {})
  restore()

  lu.assertEquals(captured.async[1].path, 'repos/wsdjeg/github.nvim/rules/branches/main')
end

function TestRulesets:testCreateRulesetAsync()
  local captured, restore = helpers.mock_util()
  rulesets.create_ruleset_async('wsdjeg', 'github.nvim', { name = 'r1' }, {})
  restore()

  lu.assertEquals(captured.async[1].method, 'POST')
  lu.assertEquals(captured.async[1].path, 'repos/wsdjeg/github.nvim/rulesets')
end

function TestRulesets:testUpdateRulesetAsync()
  local captured, restore = helpers.mock_util()
  rulesets.update_ruleset_async('wsdjeg', 'github.nvim', 42, { name = 'r1' }, {})
  restore()

  lu.assertEquals(captured.async[1].method, 'PUT')
  lu.assertEquals(captured.async[1].path, 'repos/wsdjeg/github.nvim/rulesets/42')
end

function TestRulesets:testDeleteRulesetAsync()
  local captured, restore = helpers.mock_util()
  rulesets.delete_ruleset_async('wsdjeg', 'github.nvim', 42, {})
  restore()

  lu.assertEquals(captured.async[1].method, 'DELETE')
  lu.assertEquals(captured.async[1].path, 'repos/wsdjeg/github.nvim/rulesets/42')
end

function TestRulesets:testGetRulesetHistoryAsync()
  local captured, restore = helpers.mock_util()
  rulesets.get_ruleset_history_async('wsdjeg', 'github.nvim', 42, {})
  restore()

  lu.assertEquals(captured.async[1].path, 'repos/wsdjeg/github.nvim/rulesets/42/history')
end

function TestRulesets:testGetRulesetVersionAsync()
  local captured, restore = helpers.mock_util()
  rulesets.get_ruleset_version_async('wsdjeg', 'github.nvim', 42, 3, {})
  restore()

  lu.assertEquals(captured.async[1].path, 'repos/wsdjeg/github.nvim/rulesets/42/history/3')
end

return TestRulesets

