local M = {}

local github = require('github')

-- ============================================================
-- Base64 decode helper
-- ============================================================

--- Decode base64 encoded content
---@param content string base64 encoded string
---@return string|nil decoded text
local function decode_base64(content)
  if not content then
    return nil
  end
  -- Remove newlines from base64 content
  content = content:gsub('[\r\n]', '')
  -- Try vim.base64 (Neovim 0.10+)
  if vim.base64 and vim.base64.decode then
    local ok, decoded = pcall(vim.base64.decode, content)
    if ok and decoded then
      return decoded
    end
  end
  -- Fallback: return nil, caller shows raw
  return nil
end

-- ============================================================
-- Result formatting helpers
-- ============================================================

--- Format repository info
---@param data table repo info from API
---@return string
local function format_repo(data)
  local lines = {}
  table.insert(lines, string.format('  Name: %s', data.name or 'N/A'))
  table.insert(lines, string.format('  Full name: %s', data.full_name or 'N/A'))
  if data.description then
    table.insert(lines, string.format('  Description: %s', data.description))
  end
  table.insert(lines, string.format('  Private: %s', data.private and 'yes' or 'no'))
  table.insert(lines, string.format('  Stars: %d', data.stargazers_count or 0))
  table.insert(lines, string.format('  Forks: %d', data.forks_count or 0))
  table.insert(lines, string.format('  Open issues: %d', data.open_issues_count or 0))
  if data.language then
    table.insert(lines, string.format('  Language: %s', data.language))
  end
  table.insert(lines, string.format('  Default branch: %s', data.default_branch or 'N/A'))
  if data.license and data.license.name then
    table.insert(lines, string.format('  License: %s', data.license.name))
  end
  if data.created_at then
    table.insert(lines, string.format('  Created: %s', data.created_at))
  end
  if data.updated_at then
    table.insert(lines, string.format('  Updated: %s', data.updated_at))
  end
  if data.pushed_at then
    table.insert(lines, string.format('  Last push: %s', data.pushed_at))
  end
  if data.html_url then
    table.insert(lines, string.format('  URL: %s', data.html_url))
  end
  if data.clone_url then
    table.insert(lines, string.format('  Clone URL: %s', data.clone_url))
  end
  return table.concat(lines, '\n')
end

--- Format API response data into readable text
---@param op string operation name
---@param data table parsed JSON response
---@param user string repo owner
---@param repo string repo name
---@param action table original action parameters
---@return string[]
local function format_result(op, data, user, repo, action)
  local lines = {}

  if op == 'get_repo' then
    table.insert(lines, string.format('Repository: %s/%s', user, repo))
    table.insert(lines, format_repo(data))

  elseif op == 'get_readme' then
    local name = data.name or 'README'
    local size = data.size or 0
    table.insert(lines, string.format('README for %s/%s (%s, %d bytes):', user, repo, name, size))
    table.insert(lines, '---')
    local decoded = decode_base64(data.content)
    if decoded then
      table.insert(lines, decoded)
    else
      table.insert(lines, data.content or '(empty)')
    end

  elseif op == 'get_contents' then
    local path = action.path or ''
    if type(data) == 'table' and data[1] then
      -- Directory listing
      table.insert(lines, string.format('Contents of %s/%s/%s (%d items):', user, repo, path, #data))
      table.insert(lines, '')
      for i, item in ipairs(data) do
        local item_type = item.type or 'unknown'
        local marker = item_type == 'dir' and '/' or ''
        local size_str = item_type == 'file' and string.format(' (%d bytes)', item.size or 0) or ''
        table.insert(lines, string.format('%d. %s%s%s', i, item.name or 'N/A', marker, size_str))
      end
    else
      -- Single file
      local name = data.name or path
      local size = data.size or 0
      table.insert(lines, string.format('Contents of %s/%s/%s (file, %d bytes):', user, repo, path, size))
      table.insert(lines, '---')
      local decoded = decode_base64(data.content)
      if decoded then
        table.insert(lines, decoded)
      else
        table.insert(lines, data.content or '(empty)')
      end
    end

  elseif op == 'get_tree' then
    local sha = action.sha or '?'
    local truncated = data.truncated and ' (truncated)' or ''
    local entries = data.tree or {}
    table.insert(lines, string.format('Git tree for %s/%s @ %s (%d entries%s):', user, repo, sha, #entries, truncated))
    table.insert(lines, '')
    for i, item in ipairs(entries) do
      local item_type = item.type or 'unknown'
      local marker = item_type == 'tree' and '/' or ''
      local mode = item.mode or ''
      local size_str = item_type == 'blob' and string.format(' (%d bytes)', item.size or 0) or ''
      table.insert(lines, string.format('%d. %s%s%s%s', i, item.path or 'N/A', marker, size_str, mode ~= '' and string.format(' [%s]', mode) or ''))
    end
  end

  return lines
end

-- ============================================================
-- Async tool entry point
-- ============================================================

---@param action table
---@param ctx table { callback = fun(result: table), cwd = string }
---@return table
function M.github_repo(action, ctx)
  -- Parameter validation
  if not action.user or type(action.user) ~= 'string' or action.user == '' then
    return { error = 'user is required and must be a non-empty string.' }
  end
  if not action.repo or type(action.repo) ~= 'string' or action.repo == '' then
    return { error = 'repo is required and must be a non-empty string.' }
  end
  if not action.operation or type(action.operation) ~= 'string' then
    return { error = 'operation is required and must be a string.' }
  end

  local op = action.operation
  local user, repo = action.user, action.repo

  -- Valid operations
  local valid_ops = {
    get_repo = true,
    get_readme = true,
    get_contents = true,
    get_tree = true,
  }
  if not valid_ops[op] then
    return {
      error = string.format(
        'Unknown operation: "%s". Valid operations: get_repo, get_readme, get_contents, get_tree',
        op
      ),
    }
  end

  -- Operation-specific parameter validation
  if op == 'get_contents' and (not action.path or action.path == '') then
    return { error = 'path is required for get_contents operation.' }
  end
  if op == 'get_tree' and (not action.sha or action.sha == '') then
    return { error = 'sha is required for get_tree operation.' }
  end

  -- Build async callbacks
  local callbacks = {
    on_success = function(id, data, http_code)
      local lines = format_result(op, data, user, repo, action)
      ctx.callback({
        content = table.concat(lines, '\n'),
        jobid = id,
      })
    end,
    on_error = function(id, err, http_code)
      local msg = err
      if http_code then
        msg = string.format('%s (HTTP %d)', err, http_code)
      end
      ctx.callback({
        error = string.format('GitHub API error: %s', msg),
        jobid = id,
      })
    end,
  }

  -- Dispatch to async API
  local jobid
  local repo_api = github.repository

  if op == 'get_repo' then
    jobid = repo_api.get_async(user, repo, callbacks)

  elseif op == 'get_readme' then
    jobid = repo_api.get_readme_async(user, repo, action.ref, callbacks)

  elseif op == 'get_contents' then
    jobid = repo_api.get_contents_async(user, repo, action.path, action.ref, callbacks)

  elseif op == 'get_tree' then
    local recursive = action.recursive == true or action.recursive == 'true'
    jobid = repo_api.get_tree_async(user, repo, action.sha, recursive, callbacks)
  end

  return { jobid = jobid }
end

function M.scheme()
  return {
    type = 'function',
    ['function'] = {
      name = 'github_repo',
      description = [[
        Get GitHub repository information, README, and file contents via github.nvim.

        Requires github.nvim to be installed and configured with a valid GITHUB_TOKEN.

        OPERATIONS:

        - get_repo: Get repository information (stars, forks, description, language, etc.)
        - get_readme: Get the README content of a repository (decoded from base64)
        - get_contents: Get file or directory contents (requires path; decoded from base64 for files)
        - get_tree: Get the Git tree for a branch/tag/commit (requires sha; use recursive=true for full tree)

        EXAMPLES:

        1. Get repository info:
           @github_repo user="wsdjeg" repo="github.nvim" operation="get_repo"

        2. Get README:
           @github_repo user="wsdjeg" repo="github.nvim" operation="get_readme"

        3. Get file contents:
           @github_repo user="wsdjeg" repo="github.nvim" operation="get_contents" path="lua/github/init.lua"

        4. List directory contents:
           @github_repo user="wsdjeg" repo="github.nvim" operation="get_contents" path="lua/github"

        5. Get file from specific branch:
           @github_repo user="wsdjeg" repo="github.nvim" operation="get_contents" path="README.md" ref="develop"

        6. Get full recursive tree:
           @github_repo user="wsdjeg" repo="github.nvim" operation="get_tree" sha="master" recursive=true

        7. Get tree for a specific commit:
           @github_repo user="wsdjeg" repo="github.nvim" operation="get_tree" sha="abc1234"
      ]],
      parameters = {
        type = 'object',
        properties = {
          user = {
            type = 'string',
            description = 'GitHub repository owner (username or organization)',
          },
          repo = {
            type = 'string',
            description = 'Repository name',
          },
          operation = {
            type = 'string',
            description = 'Action to perform',
            enum = {
              'get_repo',
              'get_readme',
              'get_contents',
              'get_tree',
            },
          },
          path = {
            type = 'string',
            description = 'File or directory path (e.g. "lua/github/init.lua"), required for get_contents',
          },
          ref = {
            type = 'string',
            description = 'Git ref (branch, tag, or commit) for get_readme and get_contents (optional)',
          },
          sha = {
            type = 'string',
            description = 'Tree SHA, branch name, tag, or commit SHA for get_tree (e.g. "master", "v1.0.0", "abc1234")',
          },
          recursive = {
            type = 'boolean',
            description = 'If true, fetch the entire tree recursively (for get_tree). Default: false',
          },
        },
        required = { 'user', 'repo', 'operation' },
      },
    },
  }
end

function M.info(action, _)
  if type(action) == 'string' then
    local ok, args = pcall(vim.json.decode, action)
    if ok then
      action = args
    end
  end
  if type(action) == 'table' then
    local parts = {
      string.format('github_repo %s/%s', action.user or '?', action.repo or '?'),
    }
    if action.operation then
      table.insert(parts, string.format('op=%s', action.operation))
    end
    if action.path then
      table.insert(parts, string.format('path=%s', action.path))
    end
    if action.ref then
      table.insert(parts, string.format('ref=%s', action.ref))
    end
    if action.sha then
      table.insert(parts, string.format('sha=%s', action.sha))
    end
    if action.recursive then
      table.insert(parts, 'recursive=true')
    end
    return table.concat(parts, ' ')
  end
  return 'github_repo'
end

return M

