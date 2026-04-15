local M = {}

local util = require("github.util")

--- List releases
---@param user string
---@param repo string
function M.list(user, repo)
    return util.request(table.concat({ "repos", user, repo, "releases" }, "/"))
end

--- Get a specific release by ID
---@param user string
---@param repo string
---@param release_id number
function M.get_by_id(user, repo, release_id)
    return util.request(table.concat({ "repos", user, repo, "releases", release_id }, "/"))
end

--- Get the latest release
---@param user string
---@param repo string
function M.get_latest(user, repo)
    return util.request(table.concat({ "repos", user, repo, "releases/latest" }, "/"))
end

--- Get a release by tag name
---@param user string
---@param repo string
---@param tag string
function M.get_by_tag(user, repo, tag)
    return util.request(table.concat({ "repos", user, repo, "releases/tags", tag }, "/"))
end

--- Create a release
---@param user string
---@param repo string
---@param params table {tag_name, target_commitish?, name?, body?, draft?, prerelease?, generate_release_notes?}
function M.create(user, repo, params)
    return util.request(table.concat({ "repos", user, repo, "releases" }, "/"), {
        "-X",
        "POST",
        "-d",
        vim.json.encode(params),
    })
end

--- Update a release
---@param user string
---@param repo string
---@param release_id number
---@param params table {tag_name?, target_commitish?, name?, body?, draft?, prerelease?}
function M.update(user, repo, release_id, params)
    return util.request(table.concat({ "repos", user, repo, "releases", release_id }, "/"), {
        "-X",
        "PATCH",
        "-d",
        vim.json.encode(params),
    })
end

--- Delete a release
---@param user string
---@param repo string
---@param release_id number
function M.delete(user, repo, release_id)
    return util.request(table.concat({ "repos", user, repo, "releases", release_id }, "/"), {
        "-X",
        "DELETE",
    })
end

--- List release assets
---@param user string
---@param repo string
---@param release_id number
function M.list_assets(user, repo, release_id)
    return util.request(table.concat({ "repos", user, repo, "releases", release_id, "assets" }, "/"))
end

--- Upload a release asset
---@param user string
---@param repo string
---@param release_id number
---@param file_path string path to the file to upload
---@param name string name of the asset
---@param label string? label for the asset
function M.upload_asset(user, repo, release_id, file_path, name, label)
    local url = table.concat({ "repos", user, repo, "releases", release_id, "assets" }, "/")
    url = url .. "?name=" .. vim.uri_encode(name)
    if label then
        url = url .. "&label=" .. vim.uri_encode(label)
    end
    
    -- We need to get the upload URL from the release object first usually, 
    -- but the API allows POST to assets endpoint with name param in some contexts.
    -- Standard upload URL is usually https://uploads.github.com/repos/...
    -- For simplicity, we use the standard API URL but GitHub usually requires the upload URL format.
    -- Let's use the upload URL pattern directly if we know it, or rely on the release object.
    -- However, for a generic helper, we can construct the upload URL.
    
    local upload_url = "https://uploads.github.com/repos/" .. user .. "/" .. repo .. "/releases/" .. release_id .. "/assets?name=" .. vim.uri_encode(name)
    if label then
        upload_url = upload_url .. "&label=" .. vim.uri_encode(label)
    end

    local cmd = {
        "curl",
        "-s",
        "-L",
        "-X",
        "POST",
        "-H",
        "Accept: application/vnd.github+json",
        "-H",
        "Authorization: token " .. (vim.env.GITHUB_TOKEN or ""),
        "-H",
        "X-GitHub-Api-Version: 2022-11-28",
        "-H",
        "Content-Type: application/octet-stream",
        "--data-binary",
        "@" .. file_path,
        upload_url
    }
    
    local result = table.concat(vim.fn.systemlist(cmd), "\n")
    local ok, obj = pcall(vim.json.decode, result)
    if not ok then
        return {}
    else
        return obj
    end
end

--- Delete a release asset
---@param user string
---@param repo string
---@param asset_id number
function M.delete_asset(user, repo, asset_id)
    return util.request(table.concat({ "repos", user, repo, "releases/assets", asset_id }, "/"), {
        "-X",
        "DELETE",
    })
end

return M

