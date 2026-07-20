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

function TestActions:testDownloadJobLogs()
  local captured, restore = helpers.mock_util()
  actions.download_job_logs('wsdjeg', 'github.nvim', 789, '/tmp/logs.zip')
  restore()

  lu.assertEquals(captured.sync[1].path, 'repos/wsdjeg/github.nvim/actions/jobs/789/logs')
  lu.assertEquals(captured.sync[1].output, '/tmp/logs.zip')
end

function TestActions:testGetJobLogs()
  local captured, restore = helpers.mock_util()

  -- Override unzip mock to create test step files
  local util = require('github.util')
  util.unzip = function(zip_path, dest_dir)
    vim.fn.mkdir(dest_dir, 'p')
    vim.fn.writefile({ 'building project...', 'build complete' }, dest_dir .. '/0_Build.txt')
    vim.fn.writefile({ 'running tests...', 'all tests passed' }, dest_dir .. '/1_Test.txt')
    return true
  end

  local steps = actions.get_job_logs('wsdjeg', 'github.nvim', 789)
  restore()

  -- Verify download path
  lu.assertEquals(captured.sync[1].path, 'repos/wsdjeg/github.nvim/actions/jobs/789/logs')

  -- Verify parsed steps
  lu.assertEquals(#steps, 2)
  lu.assertEquals(steps[1].number, 0)
  lu.assertEquals(steps[1].name, 'Build')
  lu.assertEquals(steps[1].content, 'building project...\nbuild complete')
  lu.assertEquals(steps[2].number, 1)
  lu.assertEquals(steps[2].name, 'Test')
  lu.assertEquals(steps[2].content, 'running tests...\nall tests passed')
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

function TestActions:testDownloadJobLogsAsync()
  local captured, restore = helpers.mock_util()
  actions.download_job_logs_async('wsdjeg', 'github.nvim', 789, '/tmp/logs.zip', {}, {})
  restore()

  lu.assertEquals(captured.async[1].method, 'DOWNLOAD')
  lu.assertEquals(captured.async[1].path, 'repos/wsdjeg/github.nvim/actions/jobs/789/logs')
  lu.assertEquals(captured.async[1].output, '/tmp/logs.zip')
end

function TestActions:testGetJobLogsAsync()
  local captured, restore = helpers.mock_util()
  actions.get_job_logs_async('wsdjeg', 'github.nvim', 789, {}, {})
  restore()

  lu.assertEquals(captured.async[1].method, 'DOWNLOAD')
  lu.assertEquals(captured.async[1].path, 'repos/wsdjeg/github.nvim/actions/jobs/789/logs')
end

return TestActions


