--[[
  Issues 模块

  同步 API: M.list / M.get / M.create_issue / M.update_issue
            M.list_comments / M.create_comment / M.list_labels / M.list_events
  异步 API: 以上方法名加 _async 后缀
--]]
local M = {}

local util = require('github.util')

--- 构造 API 路径
---@param user string
---@param repo string
---@param ... string|number 路径追加段
---@return string
local function build_path(user, repo, ...)
  local segments = { 'repos', user, repo, 'issues' }
  for _, seg in ipairs({ ... }) do
    segments[#segments + 1] = tostring(seg)
  end
  return table.concat(segments, '/')
end

--- 支持的查询参数（顺序固定，便于测试断言）
local QUERY_KEYS = {
  'state',
  'labels',
  'assignee',
  'creator',
  'mentioned',
  'milestone',
  'sort',
  'direction',
  'per_page',
  'page',
}

--- 构造查询字符串
---@param params table? 查询参数
---@return string 以 ? 开头的查询串；无有效参数时返回 ''
local function build_query(params)
  if not params then
    return ''
  end

  local parts = {}
  for _, key in ipairs(QUERY_KEYS) do
    local v = params[key]
    if v ~= nil and v ~= '' then
      -- 数组转逗号分隔 (如 labels = {'bug', 'help wanted'})
      if type(v) == 'table' then
        local items = {}
        for _, item in ipairs(v) do
          items[#items + 1] = tostring(item)
        end
        v = table.concat(items, ',')
      end
      parts[#parts + 1] = key .. '=' .. vim.uri_encode(tostring(v))
    end
  end

  if #parts == 0 then
    return ''
  end
  return '?' .. table.concat(parts, '&')
end

-- ============================================================
-- 同步 API (向后兼容)
-- ============================================================

--- 浅拷贝 params 并补默认 state (不修改调用方表)
---@param params table?
---@return table
local function with_default_state(params)
  local copy = {}
  for k, v in pairs(params or {}) do
    copy[k] = v
  end
  if copy.state == nil then
    copy.state = 'open'
  end
  return copy
end

--- 列出 issues
---@param user string
---@param repo string
---@param params table? {state?, labels?, assignee?, creator?, mentioned?, milestone?, sort?, direction?, per_page?, page?}
---@return table
function M.list(user, repo, params)
  return util.request(build_path(user, repo) .. build_query(with_default_state(params)))
end

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

--- 列出 issue 评论
---@param user string
---@param repo string
---@param id number
---@param params table? {per_page?, page?}
---@return table
function M.list_comments(user, repo, id, params)
  return util.request(build_path(user, repo, id, 'comments') .. build_query(params))
end

--- 创建 issue 评论
---@param user string
---@param repo string
---@param id number
---@param body string 评论内容
---@return table
function M.create_comment(user, repo, id, body)
  return util.request(build_path(user, repo, id, 'comments'), {
    '-X', 'POST',
    '-d', vim.json.encode({ body = body }),
  })
end

--- 列出 issue 标签
---@param user string
---@param repo string
---@param id number
---@return table
function M.list_labels(user, repo, id)
  return util.request(build_path(user, repo, id, 'labels'))
end

--- 列出 issue 事件（含 timeline 变更记录）
---@param user string
---@param repo string
---@param id number
---@param params table? {per_page?, page?}
---@return table
function M.list_events(user, repo, id, params)
  return util.request(build_path(user, repo, id, 'events') .. build_query(params))
end

-- ============================================================
-- 异步 API
-- ============================================================

--- 异步列出 issues
---@param user string
---@param repo string
---@param params table?
---@param callbacks table {on_success, on_error, on_exit}
---@param opts table?
---@return integer job_id
function M.list_async(user, repo, params, callbacks, opts)
  return util.get_async(build_path(user, repo) .. build_query(with_default_state(params)), callbacks, opts)
end

--- 异步获取单个 issue
---@param user string
---@param repo string
---@param id number
---@param callbacks table
---@param opts table?
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

--- 异步列出 issue 评论
---@param user string
---@param repo string
---@param id number
---@param params table?
---@param callbacks table
---@param opts table?
---@return integer job_id
function M.list_comments_async(user, repo, id, params, callbacks, opts)
  return util.get_async(build_path(user, repo, id, 'comments') .. build_query(params), callbacks, opts)
end

--- 异步创建 issue 评论
---@param user string
---@param repo string
---@param id number
---@param body string
---@param callbacks table
---@param opts table?
---@return integer job_id
function M.create_comment_async(user, repo, id, body, callbacks, opts)
  return util.post_async(
    build_path(user, repo, id, 'comments'),
    vim.json.encode({ body = body }),
    callbacks,
    opts
  )
end

--- 异步列出 issue 标签
---@param user string
---@param repo string
---@param id number
---@param callbacks table
---@param opts table?
---@return integer job_id
function M.list_labels_async(user, repo, id, callbacks, opts)
  return util.get_async(build_path(user, repo, id, 'labels'), callbacks, opts)
end

--- 异步列出 issue 事件
---@param user string
---@param repo string
---@param id number
---@param params table?
---@param callbacks table
---@param opts table?
---@return integer job_id
function M.list_events_async(user, repo, id, params, callbacks, opts)
  return util.get_async(build_path(user, repo, id, 'events') .. build_query(params), callbacks, opts)
end

return M

