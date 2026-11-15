local M = {}

local github = require('github')

-- ============================================================
-- Result formatting helpers
-- ============================================================

--- Format a single issue
---@param issue table issue object from API
---@return string
local function format_issue(issue)
  local lines = {}
  table.insert(lines, string.format('  Number: #%d', issue.number or 0))
  table.insert(lines, string.format('  Title: %s', issue.title or 'N/A'))
  table.insert(lines, string.format('  State: %s', issue.state or 'N/A'))
  if issue.state_reason then
    table.insert(lines, string.format('  State reason: %s', issue.state_reason))
  end
  if issue.user and issue.user.login then
    table.insert(lines, string.format('  Author: %s', issue.user.login))
  end
  if issue.assignees and #issue.assignees > 0 then
    local names = {}
    for _, a in ipairs(issue.assignees) do
      names[#names + 1] = a.login or '?'
    end
    table.insert(lines, string.format('  Assignees: %s', table.concat(names, ', ')))
  end
  if issue.labels and #issue.labels > 0 then
    local names = {}
    for _, l in ipairs(issue.labels) do
      if type(l) == 'string' then
        names[#names + 1] = l
      else
        names[#names + 1] = l.name or '?'
      end
    end
    table.insert(lines, string.format('  Labels: %s', table.concat(names, ', ')))
  end
  if issue.milestone and issue.milestone.title then
    table.insert(lines, string.format('  Milestone: %s', issue.milestone.title))
  end
  if issue.comments then
    table.insert(lines, string.format('  Comments: %d', issue.comments))
  end
  if issue.created_at then
    table.insert(lines, string.format('  Created: %s', issue.created_at))
  end
  if issue.updated_at then
    table.insert(lines, string.format('  Updated: %s', issue.updated_at))
  end
  if issue.closed_at then
    table.insert(lines, string.format('  Closed: %s', issue.closed_at))
  end
  if issue.pull_request then
    table.insert(lines, '  Note: this entry is a pull request')
  end
  if issue.html_url then
    table.insert(lines, string.format('  URL: %s', issue.html_url))
  end
  if issue.body and issue.body ~= '' then
    table.insert(lines, '  Body:')
    for _, line in ipairs(vim.split(issue.body, '\n')) do
      table.insert(lines, '    ' .. line)
    end
  end
  return table.concat(lines, '\n')
end

--- Format a comment
---@param comment table comment object from API
---@return string
local function format_comment(comment)
  local lines = {}
  local author = (comment.user and comment.user.login) or '?'
  table.insert(lines, string.format('  Comment ID: %d by %s', comment.id or 0, author))
  if comment.created_at then
    table.insert(lines, string.format('  Created: %s', comment.created_at))
  end
  if comment.updated_at then
    table.insert(lines, string.format('  Updated: %s', comment.updated_at))
  end
  if comment.html_url then
    table.insert(lines, string.format('  URL: %s', comment.html_url))
  end
  table.insert(lines, '  Body:')
  for _, line in ipairs(vim.split(comment.body or '', '\n')) do
    table.insert(lines, '    ' .. line)
  end
  return table.concat(lines, '\n')
end

--- Format an event
---@param event table event object from API
---@return string
local function format_event(event)
  local lines = {}
  table.insert(lines, string.format('  Event: %s', event.event or 'N/A'))
  table.insert(lines, string.format('  Event ID: %d', event.id or 0))
  if event.actor and event.actor.login then
    table.insert(lines, string.format('  Actor: %s', event.actor.login))
  end
  if event.commit_id then
    table.insert(lines, string.format('  Commit: %s', event.commit_id))
  end
  if event.label and event.label.name then
    table.insert(lines, string.format('  Label: %s', event.label.name))
  end
  if event.assignee and event.assignee.login then
    table.insert(lines, string.format('  Assignee: %s', event.assignee.login))
  end
  if event.created_at then
    table.insert(lines, string.format('  Created: %s', event.created_at))
  end
  return table.concat(lines, '\n')
end

--- Format API response data into readable text lines
---@param op string operation name
---@param data table parsed JSON response
---@param user string repo owner
---@param repo string repo name
---@param action table original action parameters
---@return string[]
local function format_result(op, data, user, repo, action)
  local lines = {}

  if op == 'list' then
    local issues = type(data) == 'table' and data or {}
    table.insert(lines, string.format('Issues for %s/%s (%d):', user, repo, #issues))
    table.insert(lines, '')
    for i, issue in ipairs(issues) do
      table.insert(lines, string.format('%d. #%d %s', i, issue.number or 0, issue.title or 'N/A'))
      table.insert(lines, format_issue(issue))
      table.insert(lines, '')
    end

  elseif op == 'get' then
    table.insert(lines, string.format('Issue %s/%s#%s:', user, repo, tostring(action.issue_number)))
    table.insert(lines, format_issue(data))

  elseif op == 'create_issue' then
    table.insert(lines, string.format('Issue created in %s/%s:', user, repo))
    table.insert(lines, format_issue(data))

  elseif op == 'update_issue' then
    table.insert(lines, string.format('Issue updated in %s/%s:', user, repo))
    table.insert(lines, format_issue(data))

  elseif op == 'list_comments' then
    local comments = type(data) == 'table' and data or {}
    table.insert(lines, string.format('Comments for %s/%s#%s (%d):', user, repo, tostring(action.issue_number), #comments))
    table.insert(lines, '')
    for i, comment in ipairs(comments) do
      table.insert(lines, string.format('%d. comment %d', i, comment.id or 0))
      table.insert(lines, format_comment(comment))
      table.insert(lines, '')
    end

  elseif op == 'create_comment' then
    table.insert(lines, string.format('Comment created on %s/%s#%s:', user, repo, tostring(action.issue_number)))
    table.insert(lines, format_comment(data))

  elseif op == 'list_labels' then
    local labels = type(data) == 'table' and data or {}
    table.insert(lines, string.format('Labels for %s/%s#%s (%d):', user, repo, tostring(action.issue_number), #labels))
    table.insert(lines, '')
    for i, label in ipairs(labels) do
      local name = type(label) == 'string' and label or (label.name or 'N/A')
      local extra = ''
      if type(label) == 'table' then
        if label.color then
          extra = extra .. string.format(' [#%s]', label.color)
        end
        if label.description and label.description ~= '' then
          extra = extra .. ' - ' .. label.description
        end
      end
      table.insert(lines, string.format('%d. %s%s', i, name, extra))
    end

  elseif op == 'list_events' then
    local events = type(data) == 'table' and data or {}
    table.insert(lines, string.format('Events for %s/%s#%s (%d):', user, repo, tostring(action.issue_number), #events))
    table.insert(lines, '')
    for i, event in ipairs(events) do
      table.insert(lines, string.format('%d. %s', i, event.event or 'N/A'))
      table.insert(lines, format_event(event))
      table.insert(lines, '')
    end
  end

  return lines
end

-- ============================================================
-- Async tool entry point
-- ============================================================

--- Build query params from action (only include provided values)
---@param action table
---@param keys string[] query keys to collect
---@return table|nil
local function collect_params(action, keys)
  local params = {}
  local found = false
  for _, key in ipairs(keys) do
    local v = action[key]
    if v ~= nil and v ~= '' then
      params[key] = v
      found = true
    end
  end
  if not found then
    return nil
  end
  return params
end

---@param action table
---@param ctx table { callback = fun(result: table), cwd = string }
---@return table
function M.github_issue(action, ctx)
  -- Parameter validation (synchronous, immediate error)
  if not action.user or type(action.user) ~= 'string' or action.user == '' then
    return { error = 'user is required and must be a non-empty string.' }
  end
  if not action.repo or type(action.repo) ~= 'string' or action.repo == '' then
    return { error = 'repo is required and must be a non-empty string.' }
  end
  if not action.operation or type(action.operation) ~= 'string' then
    return { error = 'operation is required and must be a string.' }
  end

  local ops = github.issues
  local op = action.operation
  local user, repo = action.user, action.repo

  -- Valid operations
  local valid_ops = {
    list = true,
    get = true,
    create_issue = true,
    update_issue = true,
    list_comments = true,
    create_comment = true,
    list_labels = true,
    list_events = true,
  }
  if not valid_ops[op] then
    return {
      error = string.format(
        'Unknown operation: "%s". Valid operations: list, get, create_issue, update_issue, '
          .. 'list_comments, create_comment, list_labels, list_events',
        op
      ),
    }
  end

  -- Operation-specific parameter validation
  local needs_issue_number = {
    get = true,
    update_issue = true,
    list_comments = true,
    create_comment = true,
    list_labels = true,
    list_events = true,
  }
  if needs_issue_number[op] and not action.issue_number then
    return { error = 'issue_number is required for ' .. op .. ' operation.' }
  end

  if op == 'create_issue' and (not action.title or action.title == '') then
    return { error = 'title is required for create_issue operation.' }
  end

  if op == 'create_comment' and (not action.body or action.body == '') then
    return { error = 'body is required for create_comment operation.' }
  end

  if op == 'update_issue' then
    local has_field = action.title
      or action.body
      or action.state
      or action.labels
      or action.assignees
      or action.milestone
    if not has_field then
      return {
        error = 'update_issue requires at least one of: title, body, state, labels, assignees, milestone.',
      }
    end
    if action.state and action.state ~= 'open' and action.state ~= 'closed' then
      return { error = 'state must be "open" or "closed".' }
    end
  end

  -- Build async callbacks
  local callbacks = {
    on_success = function(id, data, _http_code)
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

  if op == 'list' then
    local params = collect_params(action, {
      'state',
      'labels',
      'assignee',
      'creator',
      'mentioned',
      'milestone',
      'sort',
      'direction',
      'per_page',
      'page',
    })
    jobid = ops.list_async(user, repo, params, callbacks)

  elseif op == 'get' then
    jobid = ops.get_async(user, repo, action.issue_number, callbacks)

  elseif op == 'create_issue' then
    local issue = { title = action.title }
    if action.body then
      issue.body = action.body
    end
    if action.labels then
      issue.labels = action.labels
    end
    if action.assignees then
      issue.assignees = action.assignees
    end
    if action.milestone then
      issue.milestone = action.milestone
    end
    jobid = ops.create_issue_async(user, repo, issue, callbacks)

  elseif op == 'update_issue' then
    local issue = {}
    if action.title then
      issue.title = action.title
    end
    if action.body then
      issue.body = action.body
    end
    if action.state then
      issue.state = action.state
    end
    if action.labels then
      issue.labels = action.labels
    end
    if action.assignees then
      issue.assignees = action.assignees
    end
    if action.milestone then
      issue.milestone = action.milestone
    end
    jobid = ops.update_issue_async(user, repo, action.issue_number, issue, callbacks)

  elseif op == 'list_comments' then
    local params = collect_params(action, { 'per_page', 'page' })
    jobid = ops.list_comments_async(user, repo, action.issue_number, params, callbacks)

  elseif op == 'create_comment' then
    jobid = ops.create_comment_async(user, repo, action.issue_number, action.body, callbacks)

  elseif op == 'list_labels' then
    jobid = ops.list_labels_async(user, repo, action.issue_number, callbacks)

  elseif op == 'list_events' then
    local params = collect_params(action, { 'per_page', 'page' })
    jobid = ops.list_events_async(user, repo, action.issue_number, params, callbacks)
  end

  return { jobid = jobid }
end

function M.scheme()
  return {
    type = 'function',
    ['function'] = {
      name = 'github_issue',
      description = [[
        Manage GitHub issues via github.nvim.

        Requires github.nvim to be installed and configured with a valid GITHUB_TOKEN.

        OPERATIONS:

        Read:
        - list: List issues (optional filters: state, labels, assignee, creator, mentioned, milestone, sort, direction, per_page, page)
        - get: Get a single issue (requires issue_number)
        - list_comments: List issue comments (requires issue_number; optional per_page, page)
        - list_labels: List labels on an issue (requires issue_number)
        - list_events: List issue events/timeline (requires issue_number; optional per_page, page)

        Write:
        - create_issue: Create an issue (requires title; optional body, labels, assignees, milestone)
        - update_issue: Update an issue (requires issue_number and at least one of title, body, state, labels, assignees, milestone)
        - create_comment: Add a comment to an issue (requires issue_number and body)

        EXAMPLES:

        1. List open issues:
           @github_issue user="wsdjeg" repo="github.nvim" operation="list"

        2. List closed issues with a label:
           @github_issue user="wsdjeg" repo="github.nvim" operation="list" state="closed" labels=["bug"]

        3. Get a single issue:
           @github_issue user="wsdjeg" repo="github.nvim" operation="get" issue_number=42

        4. List comments:
           @github_issue user="wsdjeg" repo="github.nvim" operation="list_comments" issue_number=42

        5. List labels:
           @github_issue user="wsdjeg" repo="github.nvim" operation="list_labels" issue_number=42

        6. List events:
           @github_issue user="wsdjeg" repo="github.nvim" operation="list_events" issue_number=42

        7. Create an issue:
           @github_issue user="wsdjeg" repo="github.nvim" operation="create_issue" title="Bug: crash on startup" body="Steps to reproduce..." labels=["bug"]

        8. Close an issue:
           @github_issue user="wsdjeg" repo="github.nvim" operation="update_issue" issue_number=42 state="closed"

        9. Add a comment:
           @github_issue user="wsdjeg" repo="github.nvim" operation="create_comment" issue_number=42 body="Fixed in master."
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
              'list',
              'get',
              'create_issue',
              'update_issue',
              'list_comments',
              'create_comment',
              'list_labels',
              'list_events',
            },
          },
          issue_number = {
            type = 'integer',
            description = 'Issue number (without #). Required for get, update_issue, list_comments, create_comment, list_labels, list_events',
          },
          title = {
            type = 'string',
            description = 'Issue title. Required for create_issue, optional for update_issue',
          },
          body = {
            type = 'string',
            description = 'Issue or comment body (Markdown). Required for create_comment, optional for create_issue and update_issue',
          },
          state = {
            type = 'string',
            description = 'Issue state: "open" or "closed". Optional for update_issue, filter for list',
            enum = { 'open', 'closed' },
          },
          labels = {
            type = 'array',
            items = { type = 'string' },
            description = 'Label names. Optional for create_issue and update_issue; filter for list',
          },
          assignees = {
            type = 'array',
            items = { type = 'string' },
            description = 'Assignee logins. Optional for create_issue and update_issue',
          },
          assignee = {
            type = 'string',
            description = 'Filter issues by assignee login (optional, for list)',
          },
          creator = {
            type = 'string',
            description = 'Filter issues by creator login (optional, for list)',
          },
          mentioned = {
            type = 'string',
            description = 'Filter issues mentioning a user (optional, for list)',
          },
          milestone = {
            type = 'string',
            description = 'Milestone number ("*", "none", or number). Optional for create_issue and update_issue; filter for list',
          },
          sort = {
            type = 'string',
            description = 'Sort field for list: created, updated, comments (default: created)',
            enum = { 'created', 'updated', 'comments' },
          },
          direction = {
            type = 'string',
            description = 'Sort direction for list: asc or desc (default: desc)',
            enum = { 'asc', 'desc' },
          },
          per_page = {
            type = 'integer',
            description = 'Results per page (max 100)',
          },
          page = {
            type = 'integer',
            description = 'Page number (starts at 1)',
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
      string.format('github_issue %s/%s', action.user or '?', action.repo or '?'),
    }
    if action.operation then
      table.insert(parts, string.format('op=%s', action.operation))
    end
    if action.issue_number then
      table.insert(parts, string.format('issue=%d', action.issue_number))
    end
    if action.state then
      table.insert(parts, string.format('state=%s', action.state))
    end
    if action.title then
      table.insert(parts, string.format('title=%s', action.title))
    end
    return table.concat(parts, ' ')
  end
  return 'github_issue'
end

return M

