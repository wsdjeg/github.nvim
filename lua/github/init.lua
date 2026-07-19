--[[
  github.nvim - GitHub API Lua 客户端

  提供 同步 和 异步 两种 API:
  - 同步: M.issues.get(user, repo, id)  -> 直接返回 table
  - 异步: M.issues.get_async(user, repo, id, callbacks, opts)  -> 返回 job_id

  回调签名:
    on_success(id, data, http_code)  - 2xx 成功
    on_error(id, err, http_code?)    - 非 2xx 或异常
    on_exit(id, code, signal)        - 请求结束
--]]
local M = {}

local util = require('github.util')

--- Configuration for the github.nvim plugin
M.config = {
  -- Base URL for GitHub API (for Enterprise)
  base_url = 'https://api.github.com/',
}

--- Setup function to configure the plugin
---@param opts table? Configuration options
---  - token       string  GitHub token (write-only, not stored in config)
---  - base_url    string  GitHub API base URL
function M.setup(opts)
  opts = opts or {}

  -- Token: only write to util, never expose publicly
  if opts.token then
    util.set_token(opts.token)
  end

  -- Override base URL if provided
  if opts.base_url then
    M.config.base_url = opts.base_url
    util.set_base_url(opts.base_url)
  end
end

-- Load modules
M.issues = require('github.issues')
M.pulls = require('github.pulls')
M.repository = require('github.repository')
M.secrets = require('github.secrets')
M.rulesets = require('github.rulesets')
M.actions = require('github.actions')
M.releases = require('github.releases')
M.search = require('github.search')
M.users = require('github.users')
M.util = util

return M

