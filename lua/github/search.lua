--[[
  Search 模块

  同步 API: M.repositories / M.code / M.issues / M.users / M.commits
  异步 API: 以上方法名加 _async 后缀
--]]
local M = {}

local util = require('github.util')

--- 构造搜索 URL (含查询参数)
---@param endpoint string 搜索端点 (如 "search/repositories")
---@param query string 搜索关键词
---@param params table? 额外参数
---@return string
local function build_search_url(endpoint, query, params)
  local url = endpoint .. '?q=' .. vim.uri_encode(query)
  if params then
    for k, v in pairs(params) do
      url = url .. '&' .. k .. '=' .. vim.uri_encode(tostring(v))
    end
  end
  return url
end

-- ============================================================
-- 同步 API (向后兼容)
-- ============================================================

--- 搜索仓库
---@param query string (如 "neovim in:name")
---@param params table? {sort?, order?, per_page?, page?}
---@return table
function M.repositories(query, params)
  return util.request(build_search_url('search/repositories', query, params))
end

--- 搜索代码
---@param query string (如 "vim.api in:file language:lua")
---@param params table? {sort?, order?, per_page?, page?}
---@return table
function M.code(query, params)
  return util.request(build_search_url('search/code', query, params))
end

--- 搜索 Issues 和 Pull Requests
---@param query string (如 "bug state:open")
---@param params table? {sort?, order?, per_page?, page?}
---@return table
function M.issues(query, params)
  return util.request(build_search_url('search/issues', query, params))
end

--- 搜索用户
---@param query string (如 "tom location:gb")
---@param params table? {sort?, order?, per_page?, page?}
---@return table
function M.users(query, params)
  return util.request(build_search_url('search/users', query, params))
end

--- 搜索 Commits
---@param query string (如 "fix hash:abc123")
---@param params table? {sort?, order?, per_page?, page?}
---@return table
function M.commits(query, params)
  return util.request(build_search_url('search/commits', query, params))
end

-- ============================================================
-- 异步 API
-- ============================================================

--- 异步搜索仓库
---@return integer job_id
function M.repositories_async(query, params, callbacks, opts)
  return util.get_async(build_search_url('search/repositories', query, params), callbacks, opts)
end

--- 异步搜索代码
---@return integer job_id
function M.code_async(query, params, callbacks, opts)
  return util.get_async(build_search_url('search/code', query, params), callbacks, opts)
end

--- 异步搜索 Issues 和 Pull Requests
---@return integer job_id
function M.issues_async(query, params, callbacks, opts)
  return util.get_async(build_search_url('search/issues', query, params), callbacks, opts)
end

--- 异步搜索用户
---@return integer job_id
function M.users_async(query, params, callbacks, opts)
  return util.get_async(build_search_url('search/users', query, params), callbacks, opts)
end

--- 异步搜索 Commits
---@return integer job_id
function M.commits_async(query, params, callbacks, opts)
  return util.get_async(build_search_url('search/commits', query, params), callbacks, opts)
end

return M

