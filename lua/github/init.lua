local M = {}

--- Configuration for the github.nvim plugin
M.config = {
    -- GitHub token, defaults to vim.env.GITHUB_TOKEN
    token = nil,
    -- Base URL for GitHub API (for Enterprise)
    base_url = "https://api.github.com/",
}

--- Setup function to configure the plugin
---@param opts table? Configuration options
function M.setup(opts)
    opts = opts or {}
    M.config = vim.tbl_deep_extend("force", M.config, opts)
    
    -- If token is provided, set it in the environment for util.lua to pick up
    if M.config.token then
        vim.env.GITHUB_TOKEN = M.config.token
    end
    
    -- If base_url is provided, we need to override the root_url in util.lua
    -- Since util.lua is already loaded in other modules, this requires a more complex setup
    -- or passing the URL. For now, we rely on the environment variable or default.
end

-- Load modules
M.issues = require("github.issues")
M.pulls = require("github.pulls")
M.repository = require("github.repository")
M.secrets = require("github.secrets")
M.rulesets = require("github.rulesets")
M.actions = require("github.actions")
M.releases = require("github.releases")
M.search = require("github.search")
M.users = require("github.users")
M.util = require("github.util")

return M

