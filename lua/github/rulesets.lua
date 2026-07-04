--[[
  Rulesets 模块 (Repository Rulesets)

  同步 API: M.get_repository_rules / M.get_branch_rules / M.create_ruleset
            M.get_repository_ruleset / M.update_ruleset / M.delete_ruleset
            M.get_ruleset_history / M.get_ruleset_version
  异步 API: 以上方法名加 _async 后缀
--]]
local M = {}

local util = require('github.util')

--- 构造 rulesets API 路径
---@param user string
---@param repo string
---@param ... string|number
---@return string
local function build_path(user, repo, ...)
  local segments = { 'repos', user, repo, 'rulesets' }
  for _, seg in ipairs({ ... }) do
    segments[#segments + 1] = tostring(seg)
  end
  return table.concat(segments, '/')
end

-- ============================================================
-- 同步 API (向后兼容)
-- ============================================================

--- 列出仓库 Rulesets
---@param user string
---@param repo string
---@return table
function M.get_repository_rules(user, repo)
  return util.request(build_path(user, repo))
end

--- 获取分支规则
---@param user string
---@param repo string
---@param branch string
---@return table
function M.get_branch_rules(user, repo, branch)
  return util.request(table.concat({ 'repos', user, repo, 'rules/branches', branch }, '/'))
end

--- 创建 Ruleset
---@param user string
---@param repo string
---@param ruleset table
---@return table
function M.create_ruleset(user, repo, ruleset)
  return util.request(build_path(user, repo), {
    '-X', 'POST',
    '-d', vim.json.encode(ruleset),
  })
end

--- 获取单个 Ruleset
---@param user string
---@param repo string
---@param id number
---@return table
function M.get_repository_ruleset(user, repo, id)
  return util.request(build_path(user, repo, id))
end

--- 更新 Ruleset
---@param user string
---@param repo string
---@param id number
---@param ruleset table
---@return table
function M.update_ruleset(user, repo, id, ruleset)
  return util.request(build_path(user, repo, id), {
    '-X', 'PUT',
    '-d', vim.json.encode(ruleset),
  })
end

--- 删除 Ruleset
---@param user string
---@param repo string
---@param id number
---@return table
function M.delete_ruleset(user, repo, id)
  return util.request(build_path(user, repo, id), {
    '-X', 'DELETE',
  })
end

--- 获取 Ruleset 历史
---@param user string
---@param repo string
---@param id number
---@return table
function M.get_ruleset_history(user, repo, id)
  return util.request(build_path(user, repo, id, 'history'))
end

--- 获取 Ruleset 特定版本
---@param user string
---@param repo string
---@param id number
---@param version number
---@return table
function M.get_ruleset_version(user, repo, id, version)
  return util.request(build_path(user, repo, id, 'history', version))
end

-- ============================================================
-- 异步 API
-- ============================================================

--- 异步列出仓库 Rulesets
---@return integer job_id
function M.get_repository_rules_async(user, repo, callbacks, opts)
  return util.get_async(build_path(user, repo), callbacks, opts)
end

--- 异步获取分支规则
---@return integer job_id
function M.get_branch_rules_async(user, repo, branch, callbacks, opts)
  return util.get_async(table.concat({ 'repos', user, repo, 'rules/branches', branch }, '/'), callbacks, opts)
end

--- 异步创建 Ruleset
---@return integer job_id
function M.create_ruleset_async(user, repo, ruleset, callbacks, opts)
  return util.post_async(build_path(user, repo), vim.json.encode(ruleset), callbacks, opts)
end

--- 异步获取单个 Ruleset
---@return integer job_id
function M.get_repository_ruleset_async(user, repo, id, callbacks, opts)
  return util.get_async(build_path(user, repo, id), callbacks, opts)
end

--- 异步更新 Ruleset
---@return integer job_id
function M.update_ruleset_async(user, repo, id, ruleset, callbacks, opts)
  return util.put_async(build_path(user, repo, id), vim.json.encode(ruleset), callbacks, opts)
end

--- 异步删除 Ruleset
---@return integer job_id
function M.delete_ruleset_async(user, repo, id, callbacks, opts)
  return util.delete_async(build_path(user, repo, id), callbacks, opts)
end

--- 异步获取 Ruleset 历史
---@return integer job_id
function M.get_ruleset_history_async(user, repo, id, callbacks, opts)
  return util.get_async(build_path(user, repo, id, 'history'), callbacks, opts)
end

--- 异步获取 Ruleset 特定版本
---@return integer job_id
function M.get_ruleset_version_async(user, repo, id, version, callbacks, opts)
  return util.get_async(build_path(user, repo, id, 'history', version), callbacks, opts)
end

return M

