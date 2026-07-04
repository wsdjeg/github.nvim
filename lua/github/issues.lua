--[[
  Issues 模块

  同步 API: M.get / M.create_issue / M.update_issue  (向后兼容)
  异步 API: M.get_async / M.create_issue_async / M.update_issue_async
--]]
local M = {}

local util = require('github.util')

--- 构造 API 路径
---@param user string
---@param repo string
---@param id? number|string
---@return string
local function build_path(user, repo, id)
  if id then
    return table.concat({ 'repos', user, repo, 'issues', id }, '/')
  else
    return table.concat({ 'repos', user, repo, 'issues' }, '/')
  end
end

-- ============================================================
-- 同步 API (向后兼容)
-- ============================================================

--- 获取单个 issue
---@param user string
---@param repo string
---@param id number
---@return table
function M.get(user, repo, id)
  return util.request(build_path(user, repo, id))
end

--- 创建 issue
---@param user string
---@param repo string
---@param issue table {title, body?, labels?, assignees?, milestone?}
---@return table
function M.create_issue(user, repo, issue)
  return util.request(build_path(user, repo), {
    '-X', 'POST',
    '-d', vim.json.encode(issue),
  })
end

--- 更新 issue
---@param user string
---@param repo string
---@param id number
---@param issue table {title?, body?, state?, labels?, assignees?, milestone?}
---@return table
function M.update_issue(user, repo, id, issue)
  return util.request(build_path(user, repo, id), {
    '-X', 'PATCH',
    '-d', vim.json.encode(issue),
  })
end

-- ============================================================
-- 异步 API
-- ============================================================

--- 异步获取单个 issue
---@param user string
---@param repo string
---@param id number
---@param callbacks table {on_success, on_error, on_exit}
---@param opts table? {timeout?}
---@return integer job_id
function M.get_async(user, repo, id, callbacks, opts)
  return util.get_async(build_path(user, repo, id), callbacks, opts)
end

--- 异步创建 issue
---@param user string
---@param repo string
---@param issue table
---@param callbacks table
---@param opts table?
---@return integer job_id
function M.create_issue_async(user, repo, issue, callbacks, opts)
  return util.post_async(build_path(user, repo), vim.json.encode(issue), callbacks, opts)
end

--- 异步更新 issue
---@param user string
---@param repo string
---@param id number
---@param issue table
---@param callbacks table
---@param opts table?
---@return integer job_id
function M.update_issue_async(user, repo, id, issue, callbacks, opts)
  return util.patch_async(build_path(user, repo, id), vim.json.encode(issue), callbacks, opts)
end

return M

