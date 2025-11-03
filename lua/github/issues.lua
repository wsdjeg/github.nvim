local M = {}

local util = require("github.util")

function M.get(user, repo, id)
	return util.request(table.concat({ "repos", user, repo, "issues", id }, "/"))
end

function M.create_issue(user, repo, issue)
	local url = table.concat({ "repos", user, repo, "issues" }, "/")
	return util.request(url, {
		"-X",
		"POST",
		"-d",
		vim.json.encode(issue),
	})
end

function M.update_issue(user, repo, id, issue)
	local url = table.concat({ "repos", user, repo, "issues", id }, "/")
	return util.request(url, {
		"-X",
		"PATCH",
		"-d",
		vim.json.encode(issue),
	})
end

return M
