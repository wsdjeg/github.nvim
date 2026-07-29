local M = {}

local github = require('github')

-- ============================================================
-- Base64 decode helper
-- ============================================================

--- Decode base64 encoded content
---@param content string base64 encoded string
---@return string|nil decoded text
local function decode_base64(content)
  if not content then
    return nil
  end
  -- Remove newlines from base64 content
  content = content:gsub('[\r\n]', '')
  -- Try vim.base64 (Neovim 0.10+)
  if vim.base64 and vim.base64.decode then
    local ok, decoded = pcall(vim.base64.decode, content)
    if ok and decoded then
      return decoded
    end
  end
  -- Fallback: return nil, caller shows raw
  return nil
end

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

--- Format repository info
---@param data table repo info from API
---@return string
local function format_repo(data)
  local lines = {}
  table.insert(lines, string.format('  Name: %s', data.name or 'N/A'))
  table.insert(lines, string.format('  Full name: %s', data.full_name or 'N/A'))
  if data.description then
    table.insert(lines, string.format('  Description: %s', data.description))
  end
  table.insert(lines, string.format('  Private: %s', data.private and 'yes' or 'no'))
  table.insert(lines, string.format('  Stars: %d', data.stargazers_count or 0))
  table.insert(lines, string.format('  Forks: %d', data.forks_count or 0))
  table.insert(lines, string.format('  Open issues: %d', data.open_issues_count or 0))
  if data.language then
    table.insert(lines, string.format('  Language: %s', data.language))
  end
  table.insert(lines, string.format('  Default branch: %s', data.default_branch or 'N/A'))
  if data.license and data.license.name then
    table.insert(lines, string.format('  License: %s', data.license.name))
  end
  if data.created_at then
    table.insert(lines, string.format('  Created: %s', data.created_at))
  end
  if data.updated_at then
    table.insert(lines, string.format('  Updated: %s', data.updated_at))
  end
  if data.pushed_at then
    table.insert(lines, string.format('  Last push: %s', data.pushed_at))
  end
  if data.html_url then
    table.insert(lines, string.format('  URL: %s', data.html_url))
  end
  if data.clone_url then
    table.insert(lines, string.format('  Clone URL: %s', data.clone_url))
  end
  return table.concat(lines, '\n')
end

--- Format API response data into readable text lines
---@param op string operation name
---@param data table parsed JSON response or parsed steps
---@param user string repo owner
---@param repo string repo name
---@param action table original action parameters
---@return string[]
local function format_result(op, data, user, repo, action)
  local lines = {}

  -- ===== Repository operations =====

  if op == 'get_repo' then
    table.insert(lines, string.format('Repository: %s/%s', user, repo))
    table.insert(lines, format_repo(data))

  elseif op == 'get_readme' then
    local name = data.name or 'README'
    local size = data.size or 0
    table.insert(lines, string.format('README for %s/%s (%s, %d bytes):', user, repo, name, size))
    table.insert(lines, '---')
    local decoded = decode_base64(data.content)
    if decoded then
      table.insert(lines, decoded)
    else
      table.insert(lines, data.content or '(empty)')
    end

  elseif op == 'get_contents' then
    local path = action.path or ''
    if type(data) == 'table' and data[1] then
      -- Directory listing
      table.insert(lines, string.format('Contents of %s/%s/%s (%d items):', user, repo, path, #data))
      table.insert(lines, '')
      for i, item in ipairs(data) do
        local item_type = item.type or 'unknown'
        local marker = item_type == 'dir' and '/' or ''
        local size_str = item_type == 'file' and string.format(' (%d bytes)', item.size or 0) or ''
        table.insert(lines, string.format('%d. %s%s%s', i, item.name or 'N/A', marker, size_str))
      end
    else
      -- Single file
      local name = data.name or path
      local size = data.size or 0
      table.insert(lines, string.format('Contents of %s/%s/%s (file, %d bytes):', user, repo, path, size))
      table.insert(lines, '---')
      local decoded = decode_base64(data.content)
      if decoded then
        table.insert(lines, decoded)
      else
        table.insert(lines, data.content or '(empty)')
      end
    end

  -- ===== Actions operations =====

  elseif op == 'list_workflows' then
    local wfs = data.workflows or {}
    table.insert(lines, string.format('Workflows for %s/%s (%d):', user, repo, #wfs))
    table.insert(lines, '')
    for i, wf in ipairs(wfs) do
      table.insert(lines, string.format('%d. %s', i, wf.name or 'N/A'))
      table.insert(lines, format_workflow(wf))
      table.insert(lines, '')
    end

  elseif op == 'get_workflow' then
    table.insert(lines, string.format('Workflow: %s', data.name or 'N/A'))
    table.insert(lines, format_workflow(data))

  elseif op == 'list_workflow_runs' then
    local runs = data.workflow_runs or {}
    table.insert(lines, string.format('Workflow runs for %s/%s (%d):', user, repo, #runs))
    table.insert(lines, '')
    for i, run in ipairs(runs) do
      table.insert(lines, string.format('%d. %s', i, run.name or 'N/A'))
      table.insert(lines, format_run(run))
      table.insert(lines, '')
    end

  elseif op == 'get_workflow_run' then
    table.insert(lines, string.format('Workflow Run: %s', data.name or 'N/A'))
    table.insert(lines, format_run(data))

  elseif op == 'list_jobs_for_run' then
    local jobs = data.jobs or {}
    table.insert(lines, string.format('Jobs for run %d (%d):', action.run_id, #jobs))
    table.insert(lines, '')
    for i, job in ipairs(jobs) do
      table.insert(lines, string.format('%d. %s', i, job.name or 'N/A'))
      table.insert(lines, format_job(job))
      table.insert(lines, '')
    end

  elseif op == 'get_job_logs' then
    -- data is an array of {number, name, content}
    table.insert(lines, string.format('Job logs for %s/%s job %d (%d steps):', user, repo, action.job_id, #data))
    table.insert(lines, '')
    for _, step in ipairs(data) do
      table.insert(lines, string.format('--- Step %d: %s ---', step.number, step.name))
      table.insert(lines, step.content or '')
      table.insert(lines, '')
    end

  elseif op == 'list_artifacts' then
    local arts = data.artifacts or {}
    table.insert(lines, string.format('Artifacts for %s/%s (%d):', user, repo, #arts))
    table.insert(lines, '')
    for i, art in ipairs(arts) do
      table.insert(lines, string.format('%d. %s', i, art.name or 'N/A'))
      table.insert(lines, format_artifact(art))
      table.insert(lines, '')
    end

  elseif op == 'get_artifact' then
    table.insert(lines, string.format('Artifact: %s', data.name or 'N/A'))
    table.insert(lines, format_artifact(data))

  elseif op == 're_run_workflow' then
    table.insert(lines, string.format('Workflow run %d re-run requested.', action.run_id))

  elseif op == 'cancel_workflow_run' then
    table.insert(lines, string.format('Workflow run %d cancel requested.', action.run_id))

  elseif op == 'delete_artifact' then
    table.insert(lines, string.format('Artifact %d deleted.', action.artifact_id))
  end

  return lines
end

-- ============================================================
-- Async tool entry point
-- ============================================================

---@param action table
---@param ctx table { callback = fun(result: table), cwd = string }
---@return table
function M.github_action(action, ctx)
  -- Parameter validation (synchronous, immediate error)
  if not action.user or type(action.user) ~= 'string' or action.user == '' then
    return { error = 'user is required and must be a non-empty string.' }
  end
  if not action.repo or type(action.repo) ~= 'string' or action.repo == '' then
    return { error = 'repo is required and must be a non-empty string.' }
  end
  if not action.operation or type(action.operation) ~= 'string' then
    return { error = 'operation is required and must be a string.' }
  end

  local op = action.operation
  local user, repo = action.user, action.repo

  -- Valid operations
  local valid_ops = {
    -- Repository
    get_repo = true,
    get_readme = true,
    get_contents = true,
    -- Actions
    list_workflows = true,
    get_workflow = true,
    list_workflow_runs = true,
    get_workflow_run = true,
    list_jobs_for_run = true,
    get_job_logs = true,
    list_artifacts = true,
    get_artifact = true,
    re_run_workflow = true,
    cancel_workflow_run = true,
    delete_artifact = true,
  }
  if not valid_ops[op] then
    return {
      error = string.format(
        'Unknown operation: "%s". Valid operations: get_repo, get_readme, get_contents, '
          .. 'list_workflows, get_workflow, list_workflow_runs, get_workflow_run, '
          .. 'list_jobs_for_run, get_job_logs, list_artifacts, get_artifact, '
          .. 're_run_workflow, cancel_workflow_run, delete_artifact',
        op
      ),
    }
  end

  -- Operation-specific parameter validation
  if op == 'get_workflow' and not action.workflow_id then
    return { error = 'workflow_id is required for get_workflow operation.' }
  elseif
    (op == 'get_workflow_run' or op == 'list_jobs_for_run' or op == 're_run_workflow' or op == 'cancel_workflow_run')
    and not action.run_id
  then
    return { error = 'run_id is required for ' .. op .. ' operation.' }
  elseif (op == 'get_artifact' or op == 'delete_artifact') and not action.artifact_id then
    return { error = 'artifact_id is required for ' .. op .. ' operation.' }
  elseif op == 'get_job_logs' and not action.job_id then
    return { error = 'job_id is required for get_job_logs operation.' }
  elseif op == 'get_contents' and (not action.path or action.path == '') then
    return { error = 'path is required for get_contents operation.' }
  end

  -- Build async callbacks
  local callbacks = {
    on_success = function(id, data, http_code)
      local lines = format_result(op, data, user, repo, action)
      ctx.callback({
        content = table.concat(lines, '\n'),
        jobid = id,
      })
    end,
    on_error = function(id, err, http_code)
      local msg = err
      if http_code then
        msg = string.format('%s (HTTP %d)', err, http_code)
      end
      ctx.callback({
        error = string.format('GitHub API error: %s', msg),
        jobid = id,
      })
    end,
  }

  -- Dispatch to async API
  local jobid
  local repo_api = github.repository
  local actions_api = github.actions

  -- ===== Repository operations =====

  if op == 'get_repo' then
    jobid = repo_api.get_async(user, repo, callbacks)

  elseif op == 'get_readme' then
    jobid = repo_api.get_readme_async(user, repo, action.ref, callbacks)

  elseif op == 'get_contents' then
    jobid = repo_api.get_contents_async(user, repo, action.path, action.ref, callbacks)

  -- ===== Actions operations =====

  elseif op == 'list_workflows' then
    jobid = actions_api.list_workflows_async(user, repo, callbacks)

  elseif op == 'get_workflow' then
    jobid = actions_api.get_workflow_async(user, repo, action.workflow_id, callbacks)

  elseif op == 'list_workflow_runs' then
    local params = nil
    if action.actor or action.branch or action.event or action.status then
      params = {}
      if action.actor then params.actor = action.actor end
      if action.branch then params.branch = action.branch end
      if action.event then params.event = action.event end
      if action.status then params.status = action.status end
    end
    jobid = actions_api.list_workflow_runs_async(user, repo, params, callbacks)

  elseif op == 'get_workflow_run' then
    jobid = actions_api.get_workflow_run_async(user, repo, action.run_id, callbacks)

  elseif op == 'list_jobs_for_run' then
    jobid = actions_api.list_jobs_for_run_async(user, repo, action.run_id, callbacks)

  elseif op == 'get_job_logs' then
    jobid = actions_api.get_job_logs_async(user, repo, action.job_id, callbacks)

  elseif op == 'list_artifacts' then
    jobid = actions_api.list_artifacts_async(user, repo, callbacks)

  elseif op == 'get_artifact' then
    jobid = actions_api.get_artifact_async(user, repo, action.artifact_id, callbacks)

  elseif op == 're_run_workflow' then
    jobid = actions_api.re_run_workflow_async(user, repo, action.run_id, callbacks)

  elseif op == 'cancel_workflow_run' then
    jobid = actions_api.cancel_workflow_run_async(user, repo, action.run_id, callbacks)

  elseif op == 'delete_artifact' then
    jobid = actions_api.delete_artifact_async(user, repo, action.artifact_id, callbacks)
  end

  return { jobid = jobid }
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

        Repository:
        - get_repo: Get repository information (stars, forks, description, etc.)
        - get_readme: Get the README content of a repository (decoded from base64)
        - get_contents: Get file or directory contents (requires path; decoded from base64 for files)

        Actions:
        - list_workflows: List all workflows in a repository
        - get_workflow: Get a specific workflow (requires workflow_id)
        - list_workflow_runs: List workflow runs (optional filters: actor, branch, event, status)
        - get_workflow_run: Get a specific workflow run (requires run_id)
        - list_jobs_for_run: List jobs for a workflow run (requires run_id)
        - get_job_logs: Get parsed job logs as step-by-step text (requires job_id)
        - list_artifacts: List artifacts for a repository
        - get_artifact: Get a specific artifact (requires artifact_id)
        - re_run_workflow: Re-run a workflow (requires run_id)
        - cancel_workflow_run: Cancel a workflow run (requires run_id)
        - delete_artifact: Delete an artifact (requires artifact_id)

        EXAMPLES:

        1. Get repository info:
           @github_action user="wsdjeg" repo="github.nvim" operation="get_repo"

        2. Get README:
           @github_action user="wsdjeg" repo="github.nvim" operation="get_readme"

        3. Get file contents:
           @github_action user="wsdjeg" repo="github.nvim" operation="get_contents" path="lua/github/init.lua"

        4. List directory contents:
           @github_action user="wsdjeg" repo="github.nvim" operation="get_contents" path="lua/github"

        5. List workflows:
           @github_action user="wsdjeg" repo="github.nvim" operation="list_workflows"

        6. Get a specific workflow:
           @github_action user="wsdjeg" repo="github.nvim" operation="get_workflow" workflow_id="main.yml"

        7. List workflow runs with filters:
           @github_action user="wsdjeg" repo="github.nvim" operation="list_workflow_runs" branch="master" status="failure"

        8. Get a specific workflow run:
           @github_action user="wsdjeg" repo="github.nvim" operation="get_workflow_run" run_id=12345678

        9. List jobs for a run:
           @github_action user="wsdjeg" repo="github.nvim" operation="list_jobs_for_run" run_id=12345678

        10. Get parsed job logs:
           @github_action user="wsdjeg" repo="github.nvim" operation="get_job_logs" job_id=12345678

        11. List artifacts:
           @github_action user="wsdjeg" repo="github.nvim" operation="list_artifacts"

        12. Re-run a workflow:
           @github_action user="wsdjeg" repo="github.nvim" operation="re_run_workflow" run_id=12345678

        13. Cancel a workflow run:
           @github_action user="wsdjeg" repo="github.nvim" operation="cancel_workflow_run" run_id=12345678

        14. Delete an artifact:
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
              'get_repo',
              'get_readme',
              'get_contents',
              'list_workflows',
              'get_workflow',
              'list_workflow_runs',
              'get_workflow_run',
              'list_jobs_for_run',
              'get_job_logs',
              'list_artifacts',
              'get_artifact',
              're_run_workflow',
              'cancel_workflow_run',
              'delete_artifact',
            },
          },
          path = {
            type = 'string',
            description = 'File or directory path (e.g. "lua/github/init.lua"), required for get_contents',
          },
          ref = {
            type = 'string',
            description = 'Git ref (branch, tag, or commit) for get_readme and get_contents (optional)',
          },
          workflow_id = {
            type = 'string',
            description = 'Workflow ID or file name (e.g. "main.yml"), required for get_workflow',
          },
          run_id = {
            type = 'integer',
            description = 'Workflow run ID, required for get_workflow_run, list_jobs_for_run, re_run_workflow, cancel_workflow_run',
          },
          job_id = {
            type = 'integer',
            description = 'Job ID, required for get_job_logs',
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
    if action.path then
      table.insert(parts, string.format('path=%s', action.path))
    end
    if action.ref then
      table.insert(parts, string.format('ref=%s', action.ref))
    end
    if action.workflow_id then
      table.insert(parts, string.format('workflow=%s', action.workflow_id))
    end
    if action.run_id then
      table.insert(parts, string.format('run=%d', action.run_id))
    end
    if action.job_id then
      table.insert(parts, string.format('job=%d', action.job_id))
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

