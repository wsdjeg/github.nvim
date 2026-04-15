local M = {}

local util = require("github.util")

--- List pull requests
---@param user string
---@param repo string
---@param state string? "open", "closed", "all" (default: "open")
function M.list(user, repo, state)
    state = state or "open"
    return util.request(table.concat({ "repos", user, repo, "pulls", "?state=" .. state }, "/"))
end

--- Get a specific pull request
---@param user string
---@param repo string
---@param pull_number number
function M.get(user, repo, pull_number)
    return util.request(table.concat({ "repos", user, repo, "pulls", pull_number }, "/"))
end

--- Create a new pull request
---@param user string
---@param repo string
---@param params table {title, body, head, base, draft?, maintainer_can_modify?}
function M.create(user, repo, params)
    return util.request(table.concat({ "repos", user, repo, "pulls" }, "/"), {
        "-X",
        "POST",
        "-d",
        vim.json.encode(params),
    })
end

--- Update a pull request
---@param user string
---@param repo string
---@param pull_number number
---@param params table {title?, body?, state?, base?, maintainer_can_modify?}
function M.update(user, repo, pull_number, params)
    return util.request(table.concat({ "repos", user, repo, "pulls", pull_number }, "/"), {
        "-X",
        "PATCH",
        "-d",
        vim.json.encode(params),
    })
end

--- List commits on a pull request
---@param user string
---@param repo string
---@param pull_number number
function M.list_commits(user, repo, pull_number)
    return util.request(table.concat({ "repos", user, repo, "pulls", pull_number, "commits" }, "/"))
end

--- List files changed in a pull request
---@param user string
---@param repo string
---@param pull_number number
function M.list_files(user, repo, pull_number)
    return util.request(table.concat({ "repos", user, repo, "pulls", pull_number, "files" }, "/"))
end

--- Merge a pull request
---@param user string
---@param repo string
---@param pull_number number
---@param params table? {commit_title?, commit_message?, merge_method?: "merge"|"squash"|"rebase"}
function M.merge(user, repo, pull_number, params)
    params = params or {}
    return util.request(table.concat({ "repos", user, repo, "pulls", pull_number, "merge" }, "/"), {
        "-X",
        "PUT",
        "-d",
        vim.json.encode(params),
    })
end

--- Create a review on a pull request
---@param user string
---@param repo string
---@param pull_number number
---@param params table {body?, event?: "APPROVE"|"REQUEST_CHANGES"|"COMMENT", comments?}
function M.create_review(user, repo, pull_number, params)
    return util.request(table.concat({ "repos", user, repo, "pulls", pull_number, "reviews" }, "/"), {
        "-X",
        "POST",
        "-d",
        vim.json.encode(params),
    })
end

--- List reviews on a pull request
---@param user string
---@param repo string
---@param pull_number number
function M.list_reviews(user, repo, pull_number)
    return util.request(table.concat({ "repos", user, repo, "pulls", pull_number, "reviews" }, "/"))
end

--- Merge status/checks for a pull request
---@param user string
---@param repo string
---@param pull_number number
function M.check_merge_status(user, repo, pull_number)
    return util.request(table.concat({ "repos", user, repo, "pulls", pull_number, "merge" }, "/"))
end

return M

