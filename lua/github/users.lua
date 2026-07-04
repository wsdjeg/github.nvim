--[[
  Users 模块 (Users & Organizations)

  同步 API: M.get_user / M.get_authenticated_user / M.update_user
            M.list_followers / M.list_following / M.list_repos
            M.get_org / M.update_org / M.list_members / M.list_org_repos
  异步 API: 以上方法名加 _async 后缀
--]]
local M = {}

local util = require('github.util')

--- 构造查询字符串
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

-- ============================================================
-- 同步 API (向后兼容)
-- ============================================================

--- 获取用户资料
---@param username string
---@return table
function M.get_user(username)
  return util.request(table.concat({ 'users', username }, '/'))
end

--- 获取已认证用户资料
---@return table
function M.get_authenticated_user()
  return util.request('user')
end

--- 更新已认证用户资料
---@param params table {name?, email?, blog?, company?, location?, hireable?, bio?, twitter_username?}
---@return table
function M.update_user(params)
  return util.request('user', {
    '-X', 'PATCH',
    '-d', vim.json.encode(params),
  })
end

--- 列出用户粉丝
---@param username string
---@return table
function M.list_followers(username)
  return util.request(table.concat({ 'users', username, 'followers' }, '/'))
end

--- 列出用户关注的人
---@param username string
---@return table
function M.list_following(username)
  return util.request(table.concat({ 'users', username, 'following' }, '/'))
end

--- 列出用户仓库
---@param username string
---@param params table? {type?, sort?, direction?, per_page?, page?}
---@return table
function M.list_repos(username, params)
  local url = table.concat({ 'users', username, 'repos' }, '/') .. build_query(params)
  return util.request(url)
end

--- 获取组织资料
---@param org string
---@return table
function M.get_org(org)
  return util.request(table.concat({ 'orgs', org }, '/'))
end

--- 更新组织资料
---@param org string
---@param params table
---@return table
function M.update_org(org, params)
  return util.request(table.concat({ 'orgs', org }, '/'), {
    '-X', 'PATCH',
    '-d', vim.json.encode(params),
  })
end

--- 列出组织成员
---@param org string
---@param params table? {filter?, role?, per_page?, page?}
---@return table
function M.list_members(org, params)
  local url = table.concat({ 'orgs', org, 'members' }, '/') .. build_query(params)
  return util.request(url)
end

--- 列出组织仓库
---@param org string
---@param params table? {type?, sort?, direction?, per_page?, page?}
---@return table
function M.list_org_repos(org, params)
  local url = table.concat({ 'orgs', org, 'repos' }, '/') .. build_query(params)
  return util.request(url)
end

-- ============================================================
-- 异步 API
-- ============================================================

--- 异步获取用户资料
---@return integer job_id
function M.get_user_async(username, callbacks, opts)
  return util.get_async(table.concat({ 'users', username }, '/'), callbacks, opts)
end

--- 异步获取已认证用户资料
---@return integer job_id
function M.get_authenticated_user_async(callbacks, opts)
  return util.get_async('user', callbacks, opts)
end

--- 异步更新已认证用户资料
---@return integer job_id
function M.update_user_async(params, callbacks, opts)
  return util.patch_async('user', vim.json.encode(params), callbacks, opts)
end

--- 异步列出用户粉丝
---@return integer job_id
function M.list_followers_async(username, callbacks, opts)
  return util.get_async(table.concat({ 'users', username, 'followers' }, '/'), callbacks, opts)
end

--- 异步列出用户关注的人
---@return integer job_id
function M.list_following_async(username, callbacks, opts)
  return util.get_async(table.concat({ 'users', username, 'following' }, '/'), callbacks, opts)
end

--- 异步列出用户仓库
---@return integer job_id
function M.list_repos_async(username, params, callbacks, opts)
  return util.get_async(table.concat({ 'users', username, 'repos' }, '/') .. build_query(params), callbacks, opts)
end

--- 异步获取组织资料
---@return integer job_id
function M.get_org_async(org, callbacks, opts)
  return util.get_async(table.concat({ 'orgs', org }, '/'), callbacks, opts)
end

--- 异步更新组织资料
---@return integer job_id
function M.update_org_async(org, params, callbacks, opts)
  return util.patch_async(table.concat({ 'orgs', org }, '/'), vim.json.encode(params), callbacks, opts)
end

--- 异步列出组织成员
---@return integer job_id
function M.list_members_async(org, params, callbacks, opts)
  return util.get_async(table.concat({ 'orgs', org, 'members' }, '/') .. build_query(params), callbacks, opts)
end

--- 异步列出组织仓库
---@return integer job_id
function M.list_org_repos_async(org, params, callbacks, opts)
  return util.get_async(table.concat({ 'orgs', org, 'repos' }, '/') .. build_query(params), callbacks, opts)
end

return M

