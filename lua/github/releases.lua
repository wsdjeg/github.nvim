local M = {}

local util = require('github.util')
local job = require('job')

--- Construct releases API path
---@param user string
---@param repo string
---@param ... string|number
---@return string
local function build_path(user, repo, ...)
  local segments = { 'repos', user, repo, 'releases' }
  for _, seg in ipairs({ ... }) do
    segments[#segments + 1] = tostring(seg)
  end
  return table.concat(segments, '/')
end


-- ============================================================
-- Sync API (backward compatible)
-- ============================================================

--- List releases
---@param user string
---@param repo string
---@return table
function M.list(user, repo)
  return util.request(build_path(user, repo))
end

--- Get a specific release by ID
---@param user string
---@param repo string
---@param release_id number
---@return table
function M.get_by_id(user, repo, release_id)
  return util.request(build_path(user, repo, release_id))
end

--- Get the latest release
---@param user string
---@param repo string
---@return table
function M.get_latest(user, repo)
  return util.request(build_path(user, repo, 'latest'))
end

--- Get a release by tag name
---@param user string
---@param repo string
---@param tag string
---@return table
function M.get_by_tag(user, repo, tag)
  return util.request(build_path(user, repo, 'tags', tag))
end

--- Create a release
---@param user string
---@param repo string
---@param params table {tag_name, target_commitish?, name?, body?, draft?, prerelease?, generate_release_notes?}
---@return table
function M.create(user, repo, params)
  return util.request(build_path(user, repo), {
    '-X', 'POST',
    '-d', vim.json.encode(params),
  })
end

--- Update a release
---@param user string
---@param repo string
---@param release_id number
---@param params table
---@return table
function M.update(user, repo, release_id, params)
  return util.request(build_path(user, repo, release_id), {
    '-X', 'PATCH',
    '-d', vim.json.encode(params),
  })
end

--- Delete a release
---@param user string
---@param repo string
---@param release_id number
---@return table
function M.delete(user, repo, release_id)
  return util.request(build_path(user, repo, release_id), {
    '-X', 'DELETE',
  })
end

--- List release assets
---@param user string
---@param repo string
---@param release_id number
---@return table
function M.list_assets(user, repo, release_id)
  return util.request(build_path(user, repo, release_id, 'assets'))
end

--- Delete a release asset
---@param user string
---@param repo string
---@param asset_id number
---@return table
function M.delete_asset(user, repo, asset_id)
  return util.request(table.concat({ 'repos', user, repo, 'releases/assets', asset_id }, '/'), {
    '-X', 'DELETE',
  })
end


--- Upload a release asset (sync)
--- Uses uploads.github.com host, so bypasses util.request
---@param user string
---@param repo string
---@param release_id number
---@param file_path string path to the file to upload
---@param name string name of the asset
---@param label string? label for the asset
---@return table
function M.upload_asset(user, repo, release_id, file_path, name, label)
  local upload_url = 'https://uploads.github.com/repos/' .. user .. '/' .. repo
    .. '/releases/' .. release_id .. '/assets?name=' .. vim.uri_encode(name)
  if label then
    upload_url = upload_url .. '&label=' .. vim.uri_encode(label)
  end

  local cmd = {
    'curl', '-s', '-L', '-X', 'POST',
    '-H', 'Accept: application/vnd.github+json',
    '-H', 'Authorization: token ' .. (vim.env.GITHUB_TOKEN or ''),
    '-H', 'X-GitHub-Api-Version: 2022-11-28',
    '-H', 'Content-Type: application/octet-stream',
    '--data-binary', '@' .. file_path,
    '-w', '\n%{http_code}',
    upload_url,
  }

  local result = table.concat(vim.fn.systemlist(cmd), '\n')
  local ok, obj = pcall(vim.json.decode, result)
  if not ok then
    return {}
  end
  return obj
end


-- ============================================================
-- Async API
-- ============================================================

--- Async list releases
---@return integer job_id
function M.list_async(user, repo, callbacks, opts)
  return util.get_async(build_path(user, repo), callbacks, opts)
end

--- Async get release by ID
---@return integer job_id
function M.get_by_id_async(user, repo, release_id, callbacks, opts)
  return util.get_async(build_path(user, repo, release_id), callbacks, opts)
end

--- Async get latest release
---@return integer job_id
function M.get_latest_async(user, repo, callbacks, opts)
  return util.get_async(build_path(user, repo, 'latest'), callbacks, opts)
end

--- Async get release by tag
---@return integer job_id
function M.get_by_tag_async(user, repo, tag, callbacks, opts)
  return util.get_async(build_path(user, repo, 'tags', tag), callbacks, opts)
end

--- Async create release
---@return integer job_id
function M.create_async(user, repo, params, callbacks, opts)
  return util.post_async(build_path(user, repo), vim.json.encode(params), callbacks, opts)
end

--- Async update release
---@return integer job_id
function M.update_async(user, repo, release_id, params, callbacks, opts)
  return util.patch_async(build_path(user, repo, release_id), vim.json.encode(params), callbacks, opts)
end

--- Async delete release
---@return integer job_id
function M.delete_async(user, repo, release_id, callbacks, opts)
  return util.delete_async(build_path(user, repo, release_id), callbacks, opts)
end

--- Async list release assets
---@return integer job_id
function M.list_assets_async(user, repo, release_id, callbacks, opts)
  return util.get_async(build_path(user, repo, release_id, 'assets'), callbacks, opts)
end

--- Async delete release asset
---@return integer job_id
function M.delete_asset_async(user, repo, asset_id, callbacks, opts)
  return util.delete_async(
    table.concat({ 'repos', user, repo, 'releases/assets', asset_id }, '/'),
    callbacks, opts
  )
end


--- Async upload a release asset
--- Uses uploads.github.com host, so uses job.start directly
---@param user string
---@param repo string
---@param release_id number
---@param file_path string path to the file to upload
---@param name string name of the asset
---@param label string? label for the asset
---@param callbacks table? {on_success, on_error, on_exit}
---@param opts table? {timeout?}
---@return integer job_id
function M.upload_asset_async(user, repo, release_id, file_path, name, label, callbacks, opts)
  callbacks = callbacks or {}
  opts = opts or {}

  local upload_url = 'https://uploads.github.com/repos/' .. user .. '/' .. repo
    .. '/releases/' .. release_id .. '/assets?name=' .. vim.uri_encode(name)
  if label then
    upload_url = upload_url .. '&label=' .. vim.uri_encode(label)
  end

  local cmd = {
    'curl', '-s', '-L', '-X', 'POST',
    '-H', 'Accept: application/vnd.github+json',
    '-H', 'Authorization: token ' .. (vim.env.GITHUB_TOKEN or ''),
    '-H', 'X-GitHub-Api-Version: 2022-11-28',
    '-H', 'Content-Type: application/octet-stream',
    '--data-binary', '@' .. file_path,
    '-w', '\n%{http_code}',
    upload_url,
  }

  local stdout_lines = {}
  local stderr_lines = {}

  local jobid = job.start(cmd, {
    timeout = opts.timeout or 30000,
    on_stdout = function(id, data)
      for _, line in ipairs(data) do
        if line ~= '' then
          stdout_lines[#stdout_lines + 1] = line
        end
      end
    end,
    on_stderr = function(id, data)
      for _, line in ipairs(data) do
        if line ~= '' then
          stderr_lines[#stderr_lines + 1] = line
        end
      end
    end,
    on_exit = function(id, code, signal)
      if code == 0 and signal == 0 then
        local http_code = 200
        if #stdout_lines > 0 then
          local last = stdout_lines[#stdout_lines]
          if tonumber(last) then
            http_code = tonumber(last)
            table.remove(stdout_lines)
          end
        end
        local raw = table.concat(stdout_lines, '\n')
        local ok, data = pcall(vim.json.decode, raw)
        if http_code >= 200 and http_code < 300 then
          if callbacks.on_success then
            callbacks.on_success(id, ok and data or {}, http_code)
          end
        else
          local err_msg = ok and (data.message or raw) or raw
          if callbacks.on_error then
            callbacks.on_error(id, err_msg, http_code)
          end
        end
      else
        local err_msg = table.concat(stderr_lines, '\n')
        if err_msg == '' then
          if signal == 15 then
            err_msg = 'request timeout (killed by SIGTERM)'
          else
            err_msg = string.format('curl exited with code %d, signal %d', code, signal)
          end
        end
        if callbacks.on_error then
          callbacks.on_error(id, err_msg)
        end
      end
      if callbacks.on_exit then
        callbacks.on_exit(id, code, signal)
      end
    end,
  })

  return jobid
end

return M

