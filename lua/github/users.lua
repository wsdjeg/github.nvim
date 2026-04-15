local M = {}

local util = require("github.util")

--- Get user profile
---@param username string GitHub username
function M.get_user(username)
    return util.request(table.concat({ "users", username }, "/"))
end

--- Get authenticated user profile
function M.get_authenticated_user()
    return util.request("user")
end

--- Update authenticated user profile
---@param params table {name?, email?, blog?, company?, location?, hireable?, bio?, twitter_username?}
function M.update_user(params)
    return util.request("user", {
        "-X",
        "PATCH",
        "-d",
        vim.json.encode(params),
    })
end

--- List followers of a user
---@param username string
function M.list_followers(username)
    return util.request(table.concat({ "users", username, "followers" }, "/"))
end

--- List users a user is following
---@param username string
function M.list_following(username)
    return util.request(table.concat({ "users", username, "following" }, "/"))
end

--- List user's repositories
---@param username string
---@param params table? {type?: "all"|"owner"|"member", sort?: "created"|"updated"|"pushed"|"full_name", direction?: "asc"|"desc", per_page?: number, page?: number}
function M.list_repos(username, params)
    local url = table.concat({ "users", username, "repos" }, "/")
    if params then
        local query_parts = {}
        for k, v in pairs(params) do
            table.insert(query_parts, k .. "=" .. v)
        end
        if #query_parts > 0 then
            url = url .. "?" .. table.concat(query_parts, "&")
        end
    end
    return util.request(url)
end

--- Get organization profile
---@param org string Organization name
function M.get_org(org)
    return util.request(table.concat({ "orgs", org }, "/"))
end

--- Update organization profile
---@param org string
---@param params table {billing_email?, company?, email?, location?, name?, description?, has_organization_projects?, has_repository_projects?, default_repository_permission?, members_can_create_repositories?, members_can_create_public_repositories?, members_can_create_private_repositories?, members_can_create_internal_repositories?, members_allowed_repository_creation_type?, members_can_create_pages?, members_can_create_public_pages?, members_can_create_private_pages?, members_can_fork_private_repositories?, web_commit_signoff_required?, blog?, twitter_username?, location?,}
function M.update_org(org, params)
    return util.request(table.concat({ "orgs", org }, "/"), {
        "-X",
        "PATCH",
        "-d",
        vim.json.encode(params),
    })
end

--- List organization members
---@param org string
---@param params table? {filter?: "2fa_disabled"|"all", role?: "all"|"admin"|"member", per_page?: number, page?: number}
function M.list_members(org, params)
    local url = table.concat({ "orgs", org, "members" }, "/")
    if params then
        local query_parts = {}
        for k, v in pairs(params) do
            table.insert(query_parts, k .. "=" .. v)
        end
        if #query_parts > 0 then
            url = url .. "?" .. table.concat(query_parts, "&")
        end
    end
    return util.request(url)
end

--- List organization repositories
---@param org string
---@param params table? {type?: "all"|"public"|"private"|"forks"|"sources"|"member", sort?: "created"|"updated"|"pushed"|"full_name", direction?: "asc"|"desc", per_page?: number, page?: number}
function M.list_repos(org, params)
    local url = table.concat({ "orgs", org, "repos" }, "/")
    if params then
        local query_parts = {}
        for k, v in pairs(params) do
            table.insert(query_parts, k .. "=" .. v)
        end
        if #query_parts > 0 then
            url = url .. "?" .. table.concat(query_parts, "&")
        end
    end
    return util.request(url)
end

return M

