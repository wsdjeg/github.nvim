local M = {}
local util = require("github.util")

---@class Repository
---@field name string the name of repository
---@field description string A short description of the repository.
---@field homepage string A URL with more information about the repository.
---@field private boolean change the repository visibility
---@field visibility boolean
---@field has_issue boolean
---@field has_projects boolean
---@field has_wiki boolean
---@field is_template boolean
---@field default_branch string
---@field allow_squash_merge boolean Either `true` to allow squash-merging pull requests, or `false` to prevent squash-merging. Default: `true`. 



---@param user string the username
---@param repo string repository name
---@param repository Repository repository information
function M.update(user, repo, repository)
	return util.request(table.concat({ "repos", user, repo, "rulesets" }, "/"), {
		"-X",
		"PATCH",
		"-d",
		vim.json.encode(repository),
	})
end
return M
