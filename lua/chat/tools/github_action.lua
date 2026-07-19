local M = {}

local github = require('github')

-- ============================================================
-- Result formatting helpers
-- ============================================================

local function format_workflow(wf)
  local lines = {}
  table.insert(lines, string.format('  Name: %s', wf.name or 'N/A'))
  table.insert(lines, string.format('  Path: %s', wf.path or 'N/A'))
  table.insert(lines, string.format('  State: %s', wf.state or 'N/A'))
  table.insert(lines, string.format('  ID: %d', wf.id or 0))
  if wf.html_url then
    table.insert(lines, string.format('  URL: %s', wf.html_url))
  end
  return table.concat(lines, '\n')
end

local function format_run(run)
  local lines = {}
  table.insert(lines, string.format('  Name: %s', run.name or 'N/A'))
  table.insert(lines, string.format('  Status: %s', run.status or 'N/A'))
  table.insert(lines, string.format('  Conclusion: %s', run.conclusion or 'N/A'))
  table.insert(lines, string.format('  Event: %s', run.event or 'N/A'))
  table.insert(lines, string.format('  Branch: %s', run.head_branch or 'N/A'))
  table.insert(lines, string.format('  Run ID: %d', run.id or 0))
  if run.created_at then
    table.insert(lines, string.format('  Created: %s', run.created_at))
  end
  if run.updated_at then
    table.insert(lines, string.format('  Updated: %s', run.updated_at))
  end
  if run.html_url then
    table.insert(lines, string.format('  URL: %s', run.html_url))
  end
  return table.concat(lines, '\n')
end

local function format_job(job)
  local lines = {}
  table.insert(lines, string.format('  Name: %s', job.name or 'N/A'))
  table.insert(lines, string.format('  Status: %s', job.status or 'N/A'))
  table.insert(lines, string.format('  Conclusion: %s', job.conclusion or 'N/A'))
  table.insert(lines, string.format('  Job ID: %d', job.id or 0))
  if job.started_at then
    table.insert(lines, string.format('  Started: %s', job.started_at))
  end
  if job.completed_at then
    table.insert(lines, string.format('  Completed: %s', job.completed_at))
  end
  if job.html_url then
    table.insert(lines, string.format('  URL: %s', job.html_url))
  end
  return table.concat(lines, '\n')
end

local function format_artifact(art)
  local lines = {}
  table.insert(lines, string.format('  Name: %s', art.name or 'N/A'))
  table.insert(lines, string.format('  Artifact ID: %d', art.id or 0))
  table.insert(lines, string.format('  Size: %d bytes', art.size_in_bytes or 0))
  if art.created_at then
    table.insert(lines, string.format('  Created: %s', art.created_at))
  end
  if art.expires_at then
    table.insert(lines, string.format('  Expires: %s', art.expires_at))
  end
  if art.expired then
    table.insert(lines, string.format('  Expired: %s', art.expired and 'yes' or 'no'))
  end
  if art.archive_download_url then
    table.insert(lines, string.format('  Download URL: %s', art.archive_download_url))
  end
  return table.concat(lines, '\n')
end

-- ============================================================
-- Operation dispatch
-- ============================================================

---@param action table
---@param _ table?
---@return table
function M.github_action(action, _)
  -- Parameter validation
  if not action.user or type(action.user) ~= 'string' or action.user == '' then
    return { error = 'user is required and must be a non-empty string.' }
  end
  if not action.repo or type(action.repo) ~= 'string' or action.repo == '' then
    return { error = 'repo is required and must be a non-empty string.' }
  end
  if not action.operation or type(action.operation) ~= 'string' then
    return { error = 'operation is required and must be a string.' }
  end

  local ops = github.actions
  local op = action.operation
  local user, repo = action.user, action.repo

  ---@type table
  local result
  local lines = {}

  -- Read operations
  if op == 'list_workflows' then
    result = ops.list_workflows(user, repo)
    local wfs = result.workflows or {}
    table.insert(lines, string.format('Workflows for %s/%s (%d):', user, repo, #wfs))
    table.insert(lines, '')
    for i, wf in ipairs(wfs) do
      table.insert(lines, string.format('%d. %s', i, wf.name or 'N/A'))
      table.insert(lines, format_workflow(wf))
      table.insert(lines, '')
    end

  elseif op == 'get_workflow' then
    if not action.workflow_id then
      return { error = 'workflow_id is required for get_workflow operation.' }
    end
    result = ops.get_workflow(user, repo, action.workflow_id)
    if result.message then
      return { error = 'GitHub API error: ' .. result.message }
    end
    table.insert(lines, string.format('Workflow: %s', result.name or 'N/A'))
    table.insert(lines, format_workflow(result))

  elseif op == 'list_workflow_runs' then
    local params = nil
    if action.actor or action.branch or action.event or action.status then
      params = {}
      if action.actor then params.actor = action.actor end
      if action.branch then params.branch = action.branch end
      if action.event then params.event = action.event end
      if action.status then params.status = action.status end
    end
    result = ops.list_workflow_runs(user, repo, params)
    local runs = result.workflow_runs or {}
    table.insert(lines, string.format('Workflow runs for %s/%s (%d):', user, repo, #runs))
    table.insert(lines, '')
    for i, run in ipairs(runs) do
      table.insert(lines, string.format('%d. %s', i, run.name or 'N/A'))
      table.insert(lines, format_run(run))
      table.insert(lines, '')
    end

  elseif op == 'get_workflow_run' then
    if not action.run_id then
      return { error = 'run_id is required for get_workflow_run operation.' }
    end
    result = ops.get_workflow_run(user, repo, action.run_id)
    if result.message then
      return { error = 'GitHub API error: ' .. result.message }
    end
    table.insert(lines, string.format('Workflow Run: %s', result.name or 'N/A'))
    table.insert(lines, format_run(result))

  elseif op == 'list_jobs_for_run' then
    if not action.run_id then
      return { error = 'run_id is required for list_jobs_for_run operation.' }
    end
    result = ops.list_jobs_for_run(user, repo, action.run_id)
    local jobs = result.jobs or {}
    table.insert(lines, string.format('Jobs for run %d (%d):', action.run_id, #jobs))
    table.insert(lines, '')
    for i, job in ipairs(jobs) do
      table.insert(lines, string.format('%d. %s', i, job.name or 'N/A'))
      table.insert(lines, format_job(job))
      table.insert(lines, '')
    end

  elseif op == 'list_artifacts' then
    result = ops.list_artifacts(user, repo)
    local arts = result.artifacts or {}
    table.insert(lines, string.format('Artifacts for %s/%s (%d):', user, repo, #arts))
    table.insert(lines, '')
    for i, art in ipairs(arts) do
      table.insert(lines, string.format('%d. %s', i, art.name or 'N/A'))
      table.insert(lines, format_artifact(art))
      table.insert(lines, '')
    end

  elseif op == 'get_artifact' then
    if not action.artifact_id then
      return { error = 'artifact_id is required for get_artifact operation.' }
    end
    result = ops.get_artifact(user, repo, action.artifact_id)
    if result.message then
      return { error = 'GitHub API error: ' .. result.message }
    end
    table.insert(lines, string.format('Artifact: %s', result.name or 'N/A'))
    table.insert(lines, format_artifact(result))

  -- Write operations
  elseif op == 're_run_workflow' then
    if not action.run_id then
      return { error = 'run_id is required for re_run_workflow operation.' }
    end
    ops.re_run_workflow(user, repo, action.run_id)
    table.insert(lines, string.format('Workflow run %d re-run requested.', action.run_id))

  elseif op == 'cancel_workflow_run' then
    if not action.run_id then
      return { error = 'run_id is required for cancel_workflow_run operation.' }
    end
    ops.cancel_workflow_run(user, repo, action.run_id)
    table.insert(lines, string.format('Workflow run %d cancel requested.', action.run_id))

  elseif op == 'delete_artifact' then
    if not action.artifact_id then
      return { error = 'artifact_id is required for delete_artifact operation.' }
    end
    ops.delete_artifact(user, repo, action.artifact_id)
    table.insert(lines, string.format('Artifact %d deleted.', action.artifact_id))

  else
    return {
      error = string.format(
        'Unknown operation: "%s". Valid operations: list_workflows, get_workflow, '
          .. 'list_workflow_runs, get_workflow_run, list_jobs_for_run, list_artifacts, '
          .. 'get_artifact, re_run_workflow, cancel_workflow_run, delete_artifact',
        op
      ),
    }
  end

  local content = table.concat(lines, '\n')
  return { content = content }
end

function M.scheme()
  return {
    type = 'function',
    ['function'] = {
      name = 'github_action',
      description = [[
        Manage GitHub Actions workflows, runs, jobs, and artifacts via github.nvim.

        Requires github.nvim to be installed and configured with a valid GITHUB_TOKEN.

        OPERATIONS:

        Read:
        - list_workflows: List all workflows in a repository
        - get_workflow: Get a specific workflow (requires workflow_id)
        - list_workflow_runs: List workflow runs (optional filters: actor, branch, event, status)
        - get_workflow_run: Get a specific workflow run (requires run_id)
        - list_jobs_for_run: List jobs for a workflow run (requires run_id)
        - list_artifacts: List artifacts for a repository
        - get_artifact: Get a specific artifact (requires artifact_id)

        Write:
        - re_run_workflow: Re-run a workflow (requires run_id)
        - cancel_workflow_run: Cancel a workflow run (requires run_id)
        - delete_artifact: Delete an artifact (requires artifact_id)

        EXAMPLES:

        1. List workflows:
           @github_action user="wsdjeg" repo="github.nvim" operation="list_workflows"

        2. Get a specific workflow:
           @github_action user="wsdjeg" repo="github.nvim" operation="get_workflow" workflow_id="main.yml"

        3. List workflow runs with filters:
           @github_action user="wsdjeg" repo="github.nvim" operation="list_workflow_runs" branch="master" status="failure"

        4. Get a specific workflow run:
           @github_action user="wsdjeg" repo="github.nvim" operation="get_workflow_run" run_id=12345678

        5. List jobs for a run:
           @github_action user="wsdjeg" repo="github.nvim" operation="list_jobs_for_run" run_id=12345678

        6. List artifacts:
           @github_action user="wsdjeg" repo="github.nvim" operation="list_artifacts"

        7. Re-run a workflow:
           @github_action user="wsdjeg" repo="github.nvim" operation="re_run_workflow" run_id=12345678

        8. Cancel a workflow run:
           @github_action user="wsdjeg" repo="github.nvim" operation="cancel_workflow_run" run_id=12345678

        9. Delete an artifact:
           @github_action user="wsdjeg" repo="github.nvim" operation="delete_artifact" artifact_id=98765432
      ]],
      parameters = {
        type = 'object',
        properties = {
          user = {
            type = 'string',
            description = 'GitHub repository owner (username or organization)',
          },
          repo = {
            type = 'string',
            description = 'Repository name',
          },
          operation = {
            type = 'string',
            description = 'Action to perform',
            enum = {
              'list_workflows',
              'get_workflow',
              'list_workflow_runs',
              'get_workflow_run',
              'list_jobs_for_run',
              'list_artifacts',
              'get_artifact',
              're_run_workflow',
              'cancel_workflow_run',
              'delete_artifact',
            },
          },
          workflow_id = {
            type = 'string',
            description = 'Workflow ID or file name (e.g. "main.yml"), required for get_workflow',
          },
          run_id = {
            type = 'integer',
            description = 'Workflow run ID, required for get_workflow_run, list_jobs_for_run, re_run_workflow, cancel_workflow_run',
          },
          artifact_id = {
            type = 'integer',
            description = 'Artifact ID, required for get_artifact, delete_artifact',
          },
          actor = {
            type = 'string',
            description = 'Filter runs by actor (optional, for list_workflow_runs)',
          },
          branch = {
            type = 'string',
            description = 'Filter runs by branch (optional, for list_workflow_runs)',
          },
          event = {
            type = 'string',
            description = 'Filter runs by event type (optional, for list_workflow_runs)',
          },
          status = {
            type = 'string',
            description = 'Filter runs by status (optional, for list_workflow_runs): queued, in_progress, completed',
          },
        },
        required = { 'user', 'repo', 'operation' },
      },
    },
  }
end

function M.info(action, _)
  if type(action) == 'string' then
    local ok, args = pcall(vim.json.decode, action)
    if ok then
      action = args
    end
  end
  if type(action) == 'table' then
    local parts = {
      string.format('github_action %s/%s', action.user or '?', action.repo or '?'),
    }
    if action.operation then
      table.insert(parts, string.format('op=%s', action.operation))
    end
    if action.workflow_id then
      table.insert(parts, string.format('workflow=%s', action.workflow_id))
    end
    if action.run_id then
      table.insert(parts, string.format('run=%d', action.run_id))
    end
    if action.artifact_id then
      table.insert(parts, string.format('artifact=%d', action.artifact_id))
    end
    if action.branch then
      table.insert(parts, string.format('branch=%s', action.branch))
    end
    if action.status then
      table.insert(parts, string.format('status=%s', action.status))
    end
    return table.concat(parts, ' ')
  end
  return 'github_action'
end

return M

