local M = {}
local util = require("github.util")

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
---@field allow_merge_commit boolean Either `true` to allow merging pull requests with a merge commit, or `false` to prevent merging pull requests with merge commits.
---@field allow_rebase_merge boolean Either `true` to allow rebase-merging pull requests, or `false` to prevent rebase-merging. Default: `true`.
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

---@param user string the username
---@param repo string repository name
---@param repository Repository repository information
function M.update(user, repo, repository)
	return util.request(table.concat({ "repos", user, repo }, "/"), {
		"-X",
		"PATCH",
		"-d",
		vim.json.encode(repository),
	})
end
return M
