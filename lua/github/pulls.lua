--[[
  Pull Requests 模块

  同步 API: M.list / M.get / M.create / M.update / M.list_commits / M.list_files
            M.merge / M.create_review / M.list_reviews / M.check_merge_status
  异步 API: 以上方法名加 _async 后缀
--]]
local M = {}

local util = require('github.util')

--- 构造 pulls API 路径
---@param user string
---@param repo string
---@param ... string|number 路径追加段
---@return string
local function build_path(user, repo, ...)
  local segments = { 'repos', user, repo, 'pulls' }
  for _, seg in ipairs({ ... }) do
    segments[#segments + 1] = tostring(seg)
  end
  return table.concat(segments, '/')
end

-- ============================================================
-- 同步 API (向后兼容)
-- ============================================================

--- 列出 Pull Requests
---@param user string
---@param repo string
---@param state string? "open"|"closed"|"all" (default: "open")
---@return table
function M.list(user, repo, state)
  state = state or 'open'
  return util.request(build_path(user, repo) .. '?state=' .. state)
end

--- 获取单个 Pull Request
---@param user string
---@param repo string
---@param pull_number number
---@return table
function M.get(user, repo, pull_number)
  return util.request(build_path(user, repo, pull_number))
end

--- 创建 Pull Request
---@param user string
---@param repo string
---@param params table {title, body?, head, base, draft?, maintainer_can_modify?}
---@return table
function M.create(user, repo, params)
  return util.request(build_path(user, repo), {
    '-X', 'POST',
    '-d', vim.json.encode(params),
  })
end

--- 更新 Pull Request
---@param user string
---@param repo string
---@param pull_number number
---@param params table {title?, body?, state?, base?, maintainer_can_modify?}
---@return table
function M.update(user, repo, pull_number, params)
  return util.request(build_path(user, repo, pull_number), {
    '-X', 'PATCH',
    '-d', vim.json.encode(params),
  })
end

--- 列出 PR 的 commits
---@param user string
---@param repo string
---@param pull_number number
---@return table
function M.list_commits(user, repo, pull_number)
  return util.request(build_path(user, repo, pull_number, 'commits'))
end

--- 列出 PR 变更文件
---@param user string
---@param repo string
---@param pull_number number
---@return table
function M.list_files(user, repo, pull_number)
  return util.request(build_path(user, repo, pull_number, 'files'))
end

--- 合并 Pull Request
---@param user string
---@param repo string
---@param pull_number number
---@param params table? {commit_title?, commit_message?, merge_method?: "merge"|"squash"|"rebase"}
---@return table
function M.merge(user, repo, pull_number, params)
  params = params or {}
  return util.request(build_path(user, repo, pull_number, 'merge'), {
    '-X', 'PUT',
    '-d', vim.json.encode(params),
  })
end

--- 创建 Review
---@param user string
---@param repo string
---@param pull_number number
---@param params table {body?, event?: "APPROVE"|"REQUEST_CHANGES"|"COMMENT", comments?}
---@return table
function M.create_review(user, repo, pull_number, params)
  return util.request(build_path(user, repo, pull_number, 'reviews'), {
    '-X', 'POST',
    '-d', vim.json.encode(params),
  })
end

--- 列出 Reviews
---@param user string
---@param repo string
---@param pull_number number
---@return table
function M.list_reviews(user, repo, pull_number)
  return util.request(build_path(user, repo, pull_number, 'reviews'))
end

--- 检查 PR 合并状态
---@param user string
---@param repo string
---@param pull_number number
---@return table
function M.check_merge_status(user, repo, pull_number)
  return util.request(build_path(user, repo, pull_number, 'merge'))
end

-- ============================================================
-- 异步 API
-- ============================================================

--- 异步列出 Pull Requests
---@param user string
---@param repo string
---@param state string?
---@param callbacks table
---@param opts table?
---@return integer job_id
function M.list_async(user, repo, state, callbacks, opts)
  state = state or 'open'
  return util.get_async(build_path(user, repo) .. '?state=' .. state, callbacks, opts)
end

--- 异步获取单个 Pull Request
---@return integer job_id
function M.get_async(user, repo, pull_number, callbacks, opts)
  return util.get_async(build_path(user, repo, pull_number), callbacks, opts)
end

--- 异步创建 Pull Request
---@return integer job_id
function M.create_async(user, repo, params, callbacks, opts)
  return util.post_async(build_path(user, repo), vim.json.encode(params), callbacks, opts)
end

--- 异步更新 Pull Request
---@return integer job_id
function M.update_async(user, repo, pull_number, params, callbacks, opts)
  return util.patch_async(build_path(user, repo, pull_number), vim.json.encode(params), callbacks, opts)
end

--- 异步列出 PR commits
---@return integer job_id
function M.list_commits_async(user, repo, pull_number, callbacks, opts)
  return util.get_async(build_path(user, repo, pull_number, 'commits'), callbacks, opts)
end

--- 异步列出 PR 变更文件
---@return integer job_id
function M.list_files_async(user, repo, pull_number, callbacks, opts)
  return util.get_async(build_path(user, repo, pull_number, 'files'), callbacks, opts)
end

--- 异步合并 Pull Request
---@return integer job_id
function M.merge_async(user, repo, pull_number, params, callbacks, opts)
  params = params or {}
  return util.put_async(build_path(user, repo, pull_number, 'merge'), vim.json.encode(params), callbacks, opts)
end

--- 异步创建 Review
---@return integer job_id
function M.create_review_async(user, repo, pull_number, params, callbacks, opts)
  return util.post_async(build_path(user, repo, pull_number, 'reviews'), vim.json.encode(params), callbacks, opts)
end

--- 异步列出 Reviews
---@return integer job_id
function M.list_reviews_async(user, repo, pull_number, callbacks, opts)
  return util.get_async(build_path(user, repo, pull_number, 'reviews'), callbacks, opts)
end

--- 异步检查 PR 合并状态
---@return integer job_id
function M.check_merge_status_async(user, repo, pull_number, callbacks, opts)
  return util.get_async(build_path(user, repo, pull_number, 'merge'), callbacks, opts)
end

return M

