--[[
  Repository 模块

  同步 API: M.update, M.get, M.get_readme, M.get_contents, M.get_tree
  异步 API: M.update_async, M.get_async, M.get_readme_async, M.get_contents_async, M.get_tree_async
--]]
local M = {}

local util = require('github.util')

---@class Repository
---@field name string The name of the repository.
---@field description string A short description of the repository.
---@field homepage string A URL with more information about the repository.
---@field private boolean change the repository visibility
---@field visibility boolean
---@field has_issue boolean Either `true` to enable issues for this repository or `false` to disable them. Default: `true`.
---@field has_projects boolean Either `true` to enable projects for this repository or `false` to disable them. **Note:** If you're creating a repository in an organization that has disabled repository projects, the default is `false`, and if you pass true, the API returns an error. Default: `true`.
---@field has_wiki boolean Either `true` to enable the wiki for this repository or `false` to disable it. Default: `true`.
---@field is_template boolean Either `true` to make this repo available as a template repository or `false` to prevent it. Default: `false`.
---@field default_branch string Updates the default branch for this repository.
---@field allow_squash_merge boolean Either `true` to allow squash-merging pull requests, or `false` to prevent squash-merging. Default: `true`.
---@field allow_merge_commit boolean Either `true` to allow merging pull requests with a merge commit, or `false` to prevent merging with merge commits.
---@field allow_rebase_merge boolean Either `true` to allow rebase-merging pull requests, or `false` to prevent. Default: `true`.
---@field allow_auto_merge boolean Either `true` to allow auto-merge on pull requests, or `false` to disallow auto-merge. Default: `false`.
---@field delete_branch_on_merge boolean  Either `true` to allow automatically deleting head branches when pull requests are merged, or `false` to prevent automatic deletion. Default: `false`.
---@field allow_update_branch boolean Either `true` to always allow a pull request head branch that is behind its base branch to be updated even if it is not required to be up to date before merging, or `false` otherwise. Default: `false`.
---@field use_squash_pr_title_as_default boolean Either `true` to allow squash-merge commits to use pull request title, or `false` to use commit message. **This property is closing down**. Please use `squash_merge_commit_title` instead. Default: `false`.
---@field squash_merge_commit_title string
---@field squash_merge_commit_message string
---@field merge_commit_title string
---@field merge_commit_message string
---@field archived boolean
---@field allow_forking boolean
---@field web_commit_signoff_required boolean

--- 构造 repo API 路径
---@param user string
---@param repo string
---@return string
local function build_path(user, repo)
  return table.concat({ 'repos', user, repo }, '/')
end

-- ============================================================
-- 同步 API (向后兼容)
-- ============================================================

--- 更新仓库信息
---@param user string
---@param repo string
---@param repository Repository
---@return table
function M.update(user, repo, repository)
  return util.request(build_path(user, repo), {
    '-X', 'PATCH',
    '-d', vim.json.encode(repository),
  })
end

--- 获取仓库信息
---@param user string
---@param repo string
---@return table
function M.get(user, repo)
  return util.request(build_path(user, repo))
end

--- 获取仓库 README
---@param user string
---@param repo string
---@param ref? string Optional git ref (branch/tag/commit)
---@return table
function M.get_readme(user, repo, ref)
  local path = build_path(user, repo) .. '/readme'
  local args = nil
  if ref then
    args = { '-H', 'Accept: application/vnd.github.raw' }
    -- Use query param for ref
    path = path .. '?ref=' .. ref
  end
  return util.request(path, args)
end

--- 获取仓库文件/目录内容
---@param user string
---@param repo string
---@param path string 文件或目录路径 (如 "lua/github/init.lua" 或 "lua/github")
---@param ref? string Optional git ref (branch/tag/commit)
---@return table
function M.get_contents(user, repo, path, ref)
  local api_path = build_path(user, repo) .. '/contents/' .. path
  if ref then
    api_path = api_path .. '?ref=' .. ref
  end
  return util.request(api_path)
end

--- 获取仓库文件树 (Git Trees API)
--- 比 get_contents 列目录更高效：不返回文件内容，只返回路径和类型
---@param user string 仓库所有者
---@param repo string 仓库名称
---@param sha string tree SHA，也可传分支名 (如 "master")、tag 或 commit SHA
---@param recursive? boolean 是否递归获取整棵树 (默认 false)
---@return table
function M.get_tree(user, repo, sha, recursive)
  local api_path = build_path(user, repo) .. '/git/trees/' .. sha
  if recursive then
    api_path = api_path .. '?recursive=1'
  end
  return util.request(api_path)
end

-- ============================================================
-- 异步 API
-- ============================================================

--- 异步更新仓库信息
---@param user string
---@param repo string
---@param repository Repository
---@param callbacks table {on_success, on_error, on_exit}
---@param opts table? {timeout?}
---@return integer job_id
function M.update_async(user, repo, repository, callbacks, opts)
  return util.patch_async(build_path(user, repo), vim.json.encode(repository), callbacks, opts)
end

--- 异步获取仓库信息
---@param user string
---@param repo string
---@param callbacks table {on_success, on_error, on_exit}
---@param opts table? {timeout?}
---@return integer job_id
function M.get_async(user, repo, callbacks, opts)
  return util.get_async(build_path(user, repo), callbacks, opts)
end

--- 异步获取仓库 README
---@param user string
---@param repo string
---@param ref? string Optional git ref (branch/tag/commit)
---@param callbacks table {on_success, on_error, on_exit}
---@param opts table? {timeout?}
---@return integer job_id
function M.get_readme_async(user, repo, ref, callbacks, opts)
  local path = build_path(user, repo) .. '/readme'
  if ref then
    path = path .. '?ref=' .. ref
  end
  return util.get_async(path, callbacks, opts)
end

--- 异步获取仓库文件/目录内容
---@param user string
---@param repo string
---@param path string 文件或目录路径
---@param ref? string Optional git ref (branch/tag/commit)
---@param callbacks table {on_success, on_error, on_exit}
---@param opts table? {timeout?}
---@return integer job_id
function M.get_contents_async(user, repo, path, ref, callbacks, opts)
  local api_path = build_path(user, repo) .. '/contents/' .. path
  if ref then
    api_path = api_path .. '?ref=' .. ref
  end
  return util.get_async(api_path, callbacks, opts)
end

--- 异步获取仓库文件树 (Git Trees API)
---@param user string 仓库所有者
---@param repo string 仓库名称
---@param sha string tree SHA，也可传分支名 (如 "master")、tag 或 commit SHA
---@param recursive? boolean 是否递归获取整棵树 (默认 false)
---@param callbacks table {on_success, on_error, on_exit}
---@param opts table? {timeout?}
---@return integer job_id
function M.get_tree_async(user, repo, sha, recursive, callbacks, opts)
  local api_path = build_path(user, repo) .. '/git/trees/' .. sha
  if recursive then
    api_path = api_path .. '?recursive=1'
  end
  return util.get_async(api_path, callbacks, opts)
end

return M

