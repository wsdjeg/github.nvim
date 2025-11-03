local M = {}

local util = require("github.util")

function M.get(user, repo, id)
	return util.get(table.concat({ "repos", user, repo, "issues", id }, "/"))
end

return M
