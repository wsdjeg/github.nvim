local M = {}

local util = require("github.util")

--- List workflows in a repository
---@param user string
---@param repo string
function M.list_workflows(user, repo)
    return util.request(table.concat({ "repos", user, repo, "actions/workflows" }, "/"))
end

--- Get a specific workflow
---@param user string
---@param repo string
---@param workflow_id string|number workflow ID or file name (e.g., "main.yml")
function M.get_workflow(user, repo, workflow_id)
    return util.request(table.concat({ "repos", user, repo, "actions/workflows", workflow_id }, "/"))
end

--- List workflow runs
---@param user string
---@param repo string
---@param params table? {actor?, branch?, event?, status?}
function M.list_workflow_runs(user, repo, params)
    local url = table.concat({ "repos", user, repo, "actions/runs" }, "/")
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

--- Get a specific workflow run
---@param user string
---@param repo string
---@param run_id number
function M.get_workflow_run(user, repo, run_id)
    return util.request(table.concat({ "repos", user, repo, "actions/runs", run_id }, "/"))
end

--- Re-run a workflow run
---@param user string
---@param repo string
---@param run_id number
function M.re_run_workflow(user, repo, run_id)
    return util.request(table.concat({ "repos", user, repo, "actions/runs", run_id, "rerun" }, "/"), {
        "-X",
        "POST",
    })
end

--- Cancel a workflow run
---@param user string
---@param repo string
---@param run_id number
function M.cancel_workflow_run(user, repo, run_id)
    return util.request(table.concat({ "repos", user, repo, "actions/runs", run_id, "cancel" }, "/"), {
        "-X",
        "POST",
    })
end

--- List jobs for a workflow run
---@param user string
---@param repo string
---@param run_id number
function M.list_jobs_for_run(user, repo, run_id)
    return util.request(table.concat({ "repos", user, repo, "actions/runs", run_id, "jobs" }, "/"))
end

--- List artifacts for a repository
---@param user string
---@param repo string
function M.list_artifacts(user, repo)
    return util.request(table.concat({ "repos", user, repo, "actions/artifacts" }, "/"))
end

--- Download an artifact (returns URL/info, actual download is complex via curl)
---@param user string
---@param repo string
---@param artifact_id number
function M.get_artifact(user, repo, artifact_id)
    return util.request(table.concat({ "repos", user, repo, "actions/artifacts", artifact_id }, "/"))
end

--- Delete an artifact
---@param user string
---@param repo string
---@param artifact_id number
function M.delete_artifact(user, repo, artifact_id)
    return util.request(table.concat({ "repos", user, repo, "actions/artifacts", artifact_id }, "/"), {
        "-X",
        "DELETE",
    })
end

return M

