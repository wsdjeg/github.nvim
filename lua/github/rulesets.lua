local M = {}
local util = require("github.util")

function M.get_repository_rules(user, repo)
	return util.request(table.concat({ "repos", user, repo, "rulesets" }, "/"))
end

function M.get_branch_rules(user, repo, branch)
	return util.request(table.concat({ "repos", user, repo, "rules/branchs", branch }, "/"))
end

function M.create_ruleset(user, repo, ruleset)
	return util.request(table.concat({ "repos", user, repo, "rulesets" }, "/"), {
		"-X",
		"POST",
		"-d",
		vim.json.encode(ruleset),
	})
end

function M.get_repository_ruleset(user, repo, id)
	return util.request(table.concat({ "repos", user, repo, "rulesets", id }, "/"))
end

function M.update_ruleset(user, repo, id, ruleset)
	return util.request(table.concat({ "repos", user, repo, "rulesets", id }, "/"), {
		"-X",
		"PUT",
		"-d",
		vim.json.encode(ruleset),
	})
end

function M.delete_ruleset(user, repo, id)
	return util.request(table.concat({ "repos", user, repo, "rulesets", id }, "/"), {
		"-X",
		"DELETE",
	})
end

function M.get_ruleset_history(user, repo, id)
	return util.request(table.concat({ "repos", user, repo, "rulesets", id, "history" }, "/"))
end

function M.get_ruleset_version(user, repo, id, version)
	return util.request(table.concat({ "repos", user, repo, "rulesets", id, "history", version }, "/"))
end

return M
