local M = {}

local util = require('github.util')

--- Build query string from params table
---@param params table?
---@return string
local function build_query(params)
  if not params then
    return ''
  end
  local parts = {}
  for k, v in pairs(params) do
    parts[#parts + 1] = k .. '=' .. vim.uri_encode(tostring(v))
  end
  if #parts == 0 then
    return ''
  end
  return '?' .. table.concat(parts, '&')
end

--- Construct actions API path
---@param user string
---@param repo string
---@param ... string|number
---@return string
local function build_path(user, repo, ...)
  local segments = { 'repos', user, repo, 'actions' }
  for _, seg in ipairs({ ... }) do
    segments[#segments + 1] = tostring(seg)
  end
  return table.concat(segments, '/')
end

--- Parse step log files from an unzipped directory
--- GitHub Actions job logs zip contains files like: 0_Build.txt, 1_Test.txt
---@param dir string directory containing step .txt files
---@return table steps array of {number, name, content}
local function parse_step_logs(dir)
  local steps = {}
  local files = vim.fn.readdir(dir)
  if not files then
    return steps
  end

  table.sort(files)

  for _, file in ipairs(files) do
    if file:match('%.txt$') then
      local base = file:gsub('%.txt$', '')
      local number, name = base:match('^(%d+)_(.+)$')
      if number then
        local lines = vim.fn.readfile(dir .. '/' .. file)
        steps[#steps + 1] = {
          number = tonumber(number),
          name = name,
          content = table.concat(lines, '\n'),
        }
      end
    end
  end

  return steps
end


-- ============================================================
-- Sync API (backward compatible)
-- ============================================================

--- List workflows in a repository
---@param user string
---@param repo string
---@return table
function M.list_workflows(user, repo)
  return util.request(build_path(user, repo, 'workflows'))
end

--- Get a specific workflow
---@param user string
---@param repo string
---@param workflow_id string|number workflow ID or file name (e.g. "main.yml")
---@return table
function M.get_workflow(user, repo, workflow_id)
  return util.request(build_path(user, repo, 'workflows', workflow_id))
end

--- List workflow runs
---@param user string
---@param repo string
---@param params table? {actor?, branch?, event?, status?}
---@return table
function M.list_workflow_runs(user, repo, params)
  return util.request(build_path(user, repo, 'runs') .. build_query(params))
end

--- Get a specific workflow run
---@param user string
---@param repo string
---@param run_id number
---@return table
function M.get_workflow_run(user, repo, run_id)
  return util.request(build_path(user, repo, 'runs', run_id))
end

--- Re-run a workflow run
---@param user string
---@param repo string
---@param run_id number
---@return table
function M.re_run_workflow(user, repo, run_id)
  return util.request(build_path(user, repo, 'runs', run_id, 'rerun'), {
    '-X', 'POST',
  })
end

--- Cancel a workflow run
---@param user string
---@param repo string
---@param run_id number
---@return table
function M.cancel_workflow_run(user, repo, run_id)
  return util.request(build_path(user, repo, 'runs', run_id, 'cancel'), {
    '-X', 'POST',
  })
end

--- List jobs for a workflow run
---@param user string
---@param repo string
---@param run_id number
---@return table
function M.list_jobs_for_run(user, repo, run_id)
  return util.request(build_path(user, repo, 'runs', run_id, 'jobs'))
end

--- Download logs for a specific job (zip file)
---@param user string
---@param repo string
---@param job_id number
---@param output string output file path
---@return boolean success
---@return integer? http_code
function M.download_job_logs(user, repo, job_id, output)
  return util.download(build_path(user, repo, 'jobs', job_id, 'logs'), output)
end

--- Get parsed job logs (download, unzip, parse step-by-step)
---@param user string
---@param repo string
---@param job_id number
---@return table steps array of {number, name, content}
---@return integer? http_code
function M.get_job_logs(user, repo, job_id)
  local tmp_dir = vim.fn.tempname()
  vim.fn.mkdir(tmp_dir, 'p')
  local zip_path = tmp_dir .. '/logs.zip'
  local extract_dir = tmp_dir .. '/extracted'

  local success, http_code = util.download(
    build_path(user, repo, 'jobs', job_id, 'logs'), zip_path
  )

  if not success then
    vim.fn.delete(tmp_dir, 'rf')
    return {}, http_code
  end

  vim.fn.mkdir(extract_dir, 'p')
  util.unzip(zip_path, extract_dir)
  local steps = parse_step_logs(extract_dir)

  vim.fn.delete(tmp_dir, 'rf')
  return steps, http_code
end

--- List artifacts for a repository
---@param user string
---@param repo string
---@return table
function M.list_artifacts(user, repo)
  return util.request(build_path(user, repo, 'artifacts'))
end

--- Get an artifact
---@param user string
---@param repo string
---@param artifact_id number
---@return table
function M.get_artifact(user, repo, artifact_id)
  return util.request(build_path(user, repo, 'artifacts', artifact_id))
end

--- Delete an artifact
---@param user string
---@param repo string
---@param artifact_id number
---@return table
function M.delete_artifact(user, repo, artifact_id)
  return util.request(build_path(user, repo, 'artifacts', artifact_id), {
    '-X', 'DELETE',
  })
end


-- ============================================================
-- Async API
-- ============================================================

--- Async list workflows
---@return integer job_id
function M.list_workflows_async(user, repo, callbacks, opts)
  return util.get_async(build_path(user, repo, 'workflows'), callbacks, opts)
end

--- Async get a specific workflow
---@return integer job_id
function M.get_workflow_async(user, repo, workflow_id, callbacks, opts)
  return util.get_async(build_path(user, repo, 'workflows', workflow_id), callbacks, opts)
end

--- Async list workflow runs
---@return integer job_id
function M.list_workflow_runs_async(user, repo, params, callbacks, opts)
  return util.get_async(build_path(user, repo, 'runs') .. build_query(params), callbacks, opts)
end

--- Async get a specific workflow run
---@return integer job_id
function M.get_workflow_run_async(user, repo, run_id, callbacks, opts)
  return util.get_async(build_path(user, repo, 'runs', run_id), callbacks, opts)
end

--- Async re-run a workflow run
---@return integer job_id
function M.re_run_workflow_async(user, repo, run_id, callbacks, opts)
  return util.post_async(build_path(user, repo, 'runs', run_id, 'rerun'), '{}', callbacks, opts)
end

--- Async cancel a workflow run
---@return integer job_id
function M.cancel_workflow_run_async(user, repo, run_id, callbacks, opts)
  return util.post_async(build_path(user, repo, 'runs', run_id, 'cancel'), '{}', callbacks, opts)
end

--- Async list jobs for a workflow run
---@return integer job_id
function M.list_jobs_for_run_async(user, repo, run_id, callbacks, opts)
  return util.get_async(build_path(user, repo, 'runs', run_id, 'jobs'), callbacks, opts)
end

--- Async download logs for a specific job (zip file)
---@param user string
---@param repo string
---@param job_id number
---@param output string output file path
---@param callbacks table? {on_success, on_error, on_exit}
---@param opts table? {timeout}
---@return integer job_id
function M.download_job_logs_async(user, repo, job_id, output, callbacks, opts)
  return util.download_async(build_path(user, repo, 'jobs', job_id, 'logs'), output, callbacks, opts)
end

--- Async get parsed job logs (download, unzip, parse step-by-step)
---@param user string
---@param repo string
---@param job_id number
---@param callbacks table? {on_success(id, steps, http_code), on_error, on_exit}
---@param opts table? {timeout}
---@return integer job_id
function M.get_job_logs_async(user, repo, job_id, callbacks, opts)
  callbacks = callbacks or {}
  opts = opts or {}

  local tmp_dir = vim.fn.tempname()
  vim.fn.mkdir(tmp_dir, 'p')
  local zip_path = tmp_dir .. '/logs.zip'
  local extract_dir = tmp_dir .. '/extracted'

  return util.download_async(
    build_path(user, repo, 'jobs', job_id, 'logs'),
    zip_path,
    {
      on_success = function(id, _, http_code)
        vim.fn.mkdir(extract_dir, 'p')
        util.unzip(zip_path, extract_dir)
        local steps = parse_step_logs(extract_dir)
        if callbacks.on_success then
          callbacks.on_success(id, steps, http_code)
        end
      end,
      on_error = function(id, err, http_code)
        if callbacks.on_error then
          callbacks.on_error(id, err, http_code)
        end
      end,
      on_exit = function(id, code, signal)
        vim.fn.delete(tmp_dir, 'rf')
        if callbacks.on_exit then
          callbacks.on_exit(id, code, signal)
        end
      end,
    },
    opts
  )
end

--- Async list artifacts for a repository
---@return integer job_id
function M.list_artifacts_async(user, repo, callbacks, opts)
  return util.get_async(build_path(user, repo, 'artifacts'), callbacks, opts)
end

--- Async get an artifact
---@return integer job_id
function M.get_artifact_async(user, repo, artifact_id, callbacks, opts)
  return util.get_async(build_path(user, repo, 'artifacts', artifact_id), callbacks, opts)
end

--- Async delete an artifact
---@return integer job_id
function M.delete_artifact_async(user, repo, artifact_id, callbacks, opts)
  return util.delete_async(build_path(user, repo, 'artifacts', artifact_id), callbacks, opts)
end

return M

