local M = {}

local util = require("github.util")

--- Search for repositories
---@param query string search query (e.g., "neovim in:name")
---@param params table? {sort?: "stars"|"forks"|"help-wanted-issues"|"updated", order?: "asc"|"desc", per_page?: number, page?: number}
function M.repositories(query, params)
    local url = "search/repositories?q=" .. vim.uri_encode(query)
    if params then
        for k, v in pairs(params) do
            url = url .. "&" .. k .. "=" .. v
        end
    end
    return util.request(url)
end

--- Search for code
---@param query string search query (e.g., "vim.api in:file language:lua")
---@param params table? {sort?: "indexed", order?: "asc"|"desc", per_page?: number, page?: number}
function M.code(query, params)
    local url = "search/code?q=" .. vim.uri_encode(query)
    if params then
        for k, v in pairs(params) do
            url = url .. "&" .. k .. "=" .. v
        end
    end
    return util.request(url)
end

--- Search for issues and pull requests
---@param query string search query (e.g., "bug state:open")
---@param params table? {sort?: "comments"|"reactions"|"created"|"updated", order?: "asc"|"desc", per_page?: number, page?: number}
function M.issues(query, params)
    local url = "search/issues?q=" .. vim.uri_encode(query)
    if params then
        for k, v in pairs(params) do
            url = url .. "&" .. k .. "=" .. v
        end
    end
    return util.request(url)
end

--- Search for users
---@param query string search query (e.g., "tom location:gb")
---@param params table? {sort?: "followers"|"repositories"|"joined", order?: "asc"|"desc", per_page?: number, page?: number}
function M.users(query, params)
    local url = "search/users?q=" .. vim.uri_encode(query)
    if params then
        for k, v in pairs(params) do
            url = url .. "&" .. k .. "=" .. v
        end
    end
    return util.request(url)
end

--- Search for commits
---@param query string search query (e.g., "fix hash:abc123")
---@param params table? {sort?: "author-date"|"committer-date", order?: "asc"|"desc", per_page?: number, page?: number}
function M.commits(query, params)
    local url = "search/commits?q=" .. vim.uri_encode(query)
    if params then
        for k, v in pairs(params) do
            url = url .. "&" .. k .. "=" .. v
        end
    end
    -- Requires Accept header for commits search preview, but util.request handles base headers
    -- We might need to pass extra header if util.request supports it easily, 
    -- but for now we rely on standard versioned API.
    return util.request(url)
end

return M

