--[[
  github.nvim — GitHub API Lua 客户端

  提供 同步 和 异步 两种 API:
  - 同步: M.issues.get(user, repo, id)  → 直接返回 table
  - 异步: M.issues.get_async(user, repo, id, callbacks, opts)  → 返回 job_id

  回调签名:
    on_success(id, data, http_code)  — 2xx 成功
    on_error(id, err, http_code?)    — 非 2xx 或异常
    on_exit(id, code, signal)        — 请求结束
--]]
local M = {}

local util = require('github.util')

--- Configuration for the github.nvim plugin
M.config = {
  -- GitHub token, defaults to vim.env.GITHUB_TOKEN
  token = nil,
  -- Base URL for GitHub API (for Enterprise)
  base_url = 'https://api.github.com/',
}

--- Setup function to configure the plugin
---@param opts table? Configuration options
function M.setup(opts)
  opts = opts or {}
  M.config = vim.tbl_deep_extend('force', M.config, opts)

  -- If token is provided, set it in the environment for util.lua to pick up
  if M.config.token then
    vim.env.GITHUB_TOKEN = M.config.token
  end

  -- Override base URL if provided
  if M.config.base_url then
    util.set_base_url(M.config.base_url)
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

