-- test/actions_spec.lua
local lu = require('luaunit')
local helpers = require('helpers')
local actions = require('github.actions')

TestActions = {}

-- ============================================================
-- Sync API
-- ============================================================

function TestActions:testListWorkflows()
  local captured, restore = helpers.mock_util()
  actions.list_workflows('wsdjeg', 'github.nvim')
  restore()

  lu.assertEquals(captured.sync[1].path, 'repos/wsdjeg/github.nvim/actions/workflows')
end

function TestActions:testGetWorkflow()
  local captured, restore = helpers.mock_util()
  actions.get_workflow('wsdjeg', 'github.nvim', 'main.yml')
  restore()

  lu.assertEquals(captured.sync[1].path, 'repos/wsdjeg/github.nvim/actions/workflows/main.yml')
end

function TestActions:testGetWorkflowById()
  local captured, restore = helpers.mock_util()
  actions.get_workflow('wsdjeg', 'github.nvim', 123)
  restore()

  lu.assertEquals(captured.sync[1].path, 'repos/wsdjeg/github.nvim/actions/workflows/123')
end

function TestActions:testListWorkflowRuns()
  local captured, restore = helpers.mock_util()
  actions.list_workflow_runs('wsdjeg', 'github.nvim')
  restore()

  lu.assertEquals(captured.sync[1].path, 'repos/wsdjeg/github.nvim/actions/runs')
end

function TestActions:testListWorkflowRunsWithParams()
  local captured, restore = helpers.mock_util()
  actions.list_workflow_runs('wsdjeg', 'github.nvim', { status = 'success', branch = 'main' })
  restore()

  local path = captured.sync[1].path
  lu.assertStrContains(path, 'repos/wsdjeg/github.nvim/actions/runs')
  lu.assertStrContains(path, 'status=success')
  lu.assertStrContains(path, 'branch=main')
end

function TestActions:testGetWorkflowRun()
  local captured, restore = helpers.mock_util()
  actions.get_workflow_run('wsdjeg', 'github.nvim', 456)
  restore()

  lu.assertEquals(captured.sync[1].path, 'repos/wsdjeg/github.nvim/actions/runs/456')
end

function TestActions:testReRunWorkflow()
  local captured, restore = helpers.mock_util()
  actions.re_run_workflow('wsdjeg', 'github.nvim', 456)
  restore()

  lu.assertEquals(captured.sync[1].path, 'repos/wsdjeg/github.nvim/actions/runs/456/rerun')
  lu.assertEquals(captured.sync[1].args[2], 'POST')
end

function TestActions:testCancelWorkflowRun()
  local captured, restore = helpers.mock_util()
  actions.cancel_workflow_run('wsdjeg', 'github.nvim', 456)
  restore()

  lu.assertEquals(captured.sync[1].path, 'repos/wsdjeg/github.nvim/actions/runs/456/cancel')
  lu.assertEquals(captured.sync[1].args[2], 'POST')
end

function TestActions:testListJobsForRun()
  local captured, restore = helpers.mock_util()
  actions.list_jobs_for_run('wsdjeg', 'github.nvim', 456)
  restore()

  lu.assertEquals(captured.sync[1].path, 'repos/wsdjeg/github.nvim/actions/runs/456/jobs')
end

function TestActions:testListArtifacts()
  local captured, restore = helpers.mock_util()
  actions.list_artifacts('wsdjeg', 'github.nvim')
  restore()

  lu.assertEquals(captured.sync[1].path, 'repos/wsdjeg/github.nvim/actions/artifacts')
end

function TestActions:testGetArtifact()
  local captured, restore = helpers.mock_util()
  actions.get_artifact('wsdjeg', 'github.nvim', 789)
  restore()

  lu.assertEquals(captured.sync[1].path, 'repos/wsdjeg/github.nvim/actions/artifacts/789')
end

function TestActions:testDeleteArtifact()
  local captured, restore = helpers.mock_util()
  actions.delete_artifact('wsdjeg', 'github.nvim', 789)
  restore()

  lu.assertEquals(captured.sync[1].path, 'repos/wsdjeg/github.nvim/actions/artifacts/789')
  lu.assertEquals(captured.sync[1].args[2], 'DELETE')
end

-- ============================================================
-- Async API
-- ============================================================

function TestActions:testListWorkflowsAsync()
  local captured, restore = helpers.mock_util()
  actions.list_workflows_async('wsdjeg', 'github.nvim', {})
  restore()

  lu.assertEquals(captured.async[1].method, 'GET')
  lu.assertEquals(captured.async[1].path, 'repos/wsdjeg/github.nvim/actions/workflows')
end

function TestActions:testListWorkflowRunsAsync()
  local captured, restore = helpers.mock_util()
  actions.list_workflow_runs_async('wsdjeg', 'github.nvim', { status = 'failed' }, {})
  restore()

  lu.assertEquals(captured.async[1].method, 'GET')
  lu.assertStrContains(captured.async[1].path, 'status=failed')
end

function TestActions:testReRunWorkflowAsync()
  local captured, restore = helpers.mock_util()
  actions.re_run_workflow_async('wsdjeg', 'github.nvim', 456, {})
  restore()

  lu.assertEquals(captured.async[1].method, 'POST')
  lu.assertEquals(captured.async[1].path, 'repos/wsdjeg/github.nvim/actions/runs/456/rerun')
end

function TestActions:testCancelWorkflowRunAsync()
  local captured, restore = helpers.mock_util()
  actions.cancel_workflow_run_async('wsdjeg', 'github.nvim', 456, {})
  restore()

  lu.assertEquals(captured.async[1].method, 'POST')
  lu.assertEquals(captured.async[1].path, 'repos/wsdjeg/github.nvim/actions/runs/456/cancel')
end

function TestActions:testDeleteArtifactAsync()
  local captured, restore = helpers.mock_util()
  actions.delete_artifact_async('wsdjeg', 'github.nvim', 789, {})
  restore()

  lu.assertEquals(captured.async[1].method, 'DELETE')
  lu.assertEquals(captured.async[1].path, 'repos/wsdjeg/github.nvim/actions/artifacts/789')
end

return TestActions

