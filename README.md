# github.nvim

`github.nvim` is a comprehensive GitHub REST API client for Neovim,
written in Lua. It provides both synchronous and asynchronous APIs
for interacting with GitHub's REST API, covering issues, pull requests,
releases, actions, secrets, rulesets, search, users, and more.

Inspired by [github.vim](https://github.com/wsdjeg/github.vim), it brings
GitHub interaction directly into your editor with a clean and composable
module-based design.

[![Run Tests](https://github.com/wsdjeg/github.nvim/actions/workflows/test.yml/badge.svg)](https://github.com/wsdjeg/github.nvim/actions/workflows/test.yml)
[![GitHub License](https://img.shields.io/github/license/wsdjeg/github.nvim)](LICENSE)
[![GitHub Issues or Pull Requests](https://img.shields.io/github/issues/wsdjeg/github.nvim)](https://github.com/wsdjeg/github.nvim/issues)
[![GitHub commit activity](https://img.shields.io/github/commit-activity/m/wsdjeg/github.nvim)](https://github.com/wsdjeg/github.nvim/commits/master/)
[![GitHub Release](https://img.shields.io/github/v/release/wsdjeg/github.nvim)](https://github.com/wsdjeg/github.nvim/releases)
[![luarocks](https://img.shields.io/luarocks/v/wsdjeg/github.nvim)](https://luarocks.org/modules/wsdjeg/github.nvim)

<!-- vim-markdown-toc GFM -->

- [✨ Features](#-features)
- [📦 Installation](#-installation)
- [🔧 Configuration](#-configuration)
- [⚡ Sync vs Async](#-sync-vs-async)
- [📚 API Reference](#-api-reference)
    - [Issues](#issues)
    - [Pull Requests](#pull-requests)
    - [Repository](#repository)
    - [Releases](#releases)
    - [GitHub Actions](#github-actions)
    - [Secrets](#secrets)
    - [Rulesets](#rulesets)
    - [Search](#search)
    - [Users & Organizations](#users--organizations)
- [🧩 Chat.nvim Integration](#-chatnvim-integration)
- [❓ FAQ](#-faq)
- [🙏 Credits](#-credits)
- [📣 Self-Promotion](#-self-promotion)
- [📄 License](#-license)

<!-- vim-markdown-toc -->

## ✨ Features

- Full GitHub REST API coverage across 9 modules
- Both synchronous and asynchronous APIs for every function
- Async powered by [job.nvim](https://github.com/wsdjeg/job.nvim) with callback support
- Secure token handling — write-only, never exposed publicly
- GitHub Enterprise support via configurable base URL
- 143 tests with CI on Neovim nightly/stable across Ubuntu, Windows, and macOS
- Integrates with [chat.nvim](https://github.com/wsdjeg/chat.nvim) as a built-in tool

## 📦 Installation

github.nvim works with all major Neovim plugin managers.
Neovim 0.10+ is recommended for best compatibility.

- **Using [nvim-plug](https://github.com/wsdjeg/nvim-plug)**

  ```lua
  require('plug').add({
    {
      'wsdjeg/github.nvim',
      config = function()
        require('github').setup({
          token = 'your-github-token',
        })
      end,
    },
  })
  ```

- **Using [lazy.nvim](https://github.com/folke/lazy.nvim)**

  ```lua
  {
    'wsdjeg/github.nvim',
    config = function()
      require('github').setup({
        token = 'your-github-token',
      })
    end,
  }
  ```

- **Using [packer.nvim](https://github.com/wbthomason/packer.nvim)**

  ```lua
  use({
    'wsdjeg/github.nvim',
    config = function()
      require('github').setup({
        token = 'your-github-token',
      })
    end,
  })
  ```

- **Using [luarocks](https://luarocks.org/)**

  ```
  luarocks install github.nvim
  ```

  Then in your config:

  ```lua
  require('github').setup({
    token = 'your-github-token',
  })
  ```

## 🔧 Configuration

```lua
require('github').setup({
  -- GitHub personal access token (required)
  -- Token is stored internally and cannot be read back via any public API
  token = 'your-github-token',

  -- Base URL for GitHub API
  -- Use this for GitHub Enterprise: 'https://github.example.com/api/v3/'
  base_url = 'https://api.github.com/',
})
```

| Option      | Type   | Default                    | Description                                      |
| ----------- | ------ | -------------------------- | ------------------------------------------------ |
| `token`     | string | `nil`                      | GitHub personal access token (write-only)        |
| `base_url`  | string | `'https://api.github.com/'`| API base URL, change for GitHub Enterprise       |

> **Security:** The token is stored in a private local variable inside `util.lua`.
> No public function or variable exposes it. It can only be set via `setup()`.

## ⚡ Sync vs Async

Every API function comes in two flavors:

| | Sync | Async |
|---|---|---|
| **Returns** | `table` (parsed JSON) | `integer` (job_id) |
| **Blocking?** | Yes — uses `vim.fn.systemlist` | No — uses `job.nvim` |
| **Naming** | `M.get(user, repo, id)` | `M.get_async(user, repo, id, callbacks, opts)` |

### Async Callbacks

```lua
local callbacks = {
  on_success = function(id, data, http_code) end,  -- 2xx response
  on_error   = function(id, err, http_code?) end,   -- non-2xx or error
  on_exit    = function(id, code, signal) end,      -- always called
}

local opts = { timeout = 30000 }  -- optional, milliseconds
```

### Async Example

```lua
local pulls = require('github').pulls

pulls.list_async('wsdjeg', 'github.nvim', 'open', {
  on_success = function(id, data, http_code)
    for _, pr in ipairs(data) do
      print(pr.number, pr.title)
    end
  end,
  on_error = function(id, err)
    vim.notify('Failed: ' .. err, vim.log.levels.ERROR)
  end,
})
```

## 📚 API Reference

Most API functions require `user` (owner) and `repo` (repository name) as
the first two arguments. Each sync function has an `_async` counterpart with
the same parameters plus `callbacks` and `opts`.

### Issues

```lua
local M = require('github').issues

M.get(user, repo, id)
M.create_issue(user, repo, issue_data)
M.update_issue(user, repo, id, issue_data)

-- Async (add _async suffix + callbacks + opts)
M.get_async(user, repo, id, callbacks, opts)
M.create_issue_async(user, repo, issue_data, callbacks, opts)
M.update_issue_async(user, repo, id, issue_data, callbacks, opts)
```

### Pull Requests

```lua
local M = require('github').pulls

M.list(user, repo, state)            -- state: 'open', 'closed', 'all'
M.get(user, repo, pull_number)
M.create(user, repo, params)
M.update(user, repo, pull_number, params)
M.merge(user, repo, pull_number, params)
M.create_review(user, repo, pull_number, params)
M.list_reviews(user, repo, pull_number)
M.list_commits(user, repo, pull_number)
M.list_files(user, repo, pull_number)
M.check_merge_status(user, repo, pull_number)
```

### Repository

```lua
local M = require('github').repository

M.update(user, repo, repository_data)
```

### Releases

```lua
local M = require('github').releases

M.list(user, repo)
M.get_by_id(user, repo, release_id)
M.get_latest(user, repo)
M.get_by_tag(user, repo, tag)
M.create(user, repo, params)
M.update(user, repo, release_id, params)
M.delete(user, repo, release_id)
M.list_assets(user, repo, release_id)
M.upload_asset(user, repo, release_id, file_path, name, label)
M.delete_asset(user, repo, asset_id)
```

### GitHub Actions

```lua
local M = require('github').actions

M.list_workflows(user, repo)
M.get_workflow(user, repo, workflow_id)
M.list_workflow_runs(user, repo, params)
M.get_workflow_run(user, repo, run_id)
M.re_run_workflow(user, repo, run_id)
M.cancel_workflow_run(user, repo, run_id)
M.list_jobs_for_run(user, repo, run_id)
M.list_artifacts(user, repo)
M.get_artifact(user, repo, artifact_id)
M.delete_artifact(user, repo, artifact_id)
```

### Secrets

```lua
local M = require('github').secrets

M.list_repository_secrets(user, repo)
M.delete_repository_secret(user, repo, secret_name)
M.get_repository_secrets_public_key(user, repo)
M.update_repository_secret(user, repo, secret)
```

> **Note:** `update_repository_secret` requires
> [luasodium](https://luarocks.org/modules/luasodium) for encrypting secret
> values with the repository's public key.

### Rulesets

```lua
local M = require('github').rulesets

M.get_repository_rules(user, repo)
M.get_branch_rules(user, repo, branch)
M.create_ruleset(user, repo, ruleset)
M.get_repository_ruleset(user, repo, id)
M.update_ruleset(user, repo, id, ruleset)
M.delete_ruleset(user, repo, id)
M.get_ruleset_history(user, repo, id)
M.get_ruleset_version(user, repo, id, version)
```

### Search

```lua
local M = require('github').search

M.repositories(query, params)
M.code(query, params)
M.issues(query, params)
M.users(query, params)
M.commits(query, params)
```

### Users & Organizations

```lua
local M = require('github').users

-- Users
M.get_user(username)
M.get_authenticated_user()
M.update_user(params)
M.list_followers(username)
M.list_following(username)
M.list_repos(username, params)

-- Organizations
M.get_org(org)
M.update_org(org, params)
M.list_members(org, params)
M.list_org_repos(org, params)
```

## 🧩 Chat.nvim Integration

github.nvim integrates with [chat.nvim](https://github.com/wsdjeg/chat.nvim)
as a built-in tool, allowing the AI assistant to interact with GitHub
Actions directly from the chat window.

Supported operations:

| Operation              | Description                        |
| ---------------------- | ---------------------------------- |
| `list_workflows`       | List all workflows in a repository |
| `get_workflow`         | Get a specific workflow            |
| `list_workflow_runs`   | List workflow runs with filters    |
| `get_workflow_run`     | Get a specific workflow run        |
| `list_jobs_for_run`    | List jobs for a workflow run       |
| `list_artifacts`       | List artifacts for a repository    |
| `get_artifact`         | Get a specific artifact            |
| `re_run_workflow`      | Re-run a workflow                  |
| `cancel_workflow_run`  | Cancel a workflow run              |
| `delete_artifact`      | Delete an artifact                 |

## ❓ FAQ

<details>
<summary>How do I get a GitHub token?</summary>

1. Go to [GitHub Settings → Developer settings → Personal access tokens](https://github.com/settings/tokens)
2. Generate a new token with the required scopes (e.g., `repo`, `workflow`)
3. Pass it to `setup({ token = 'ghp_xxxx' })`

</details>

<details>
<summary>Can I use environment variables for the token?</summary>

No. As of v0.2.0, the token is set exclusively via `setup()`. This ensures
the token is stored securely in a private local variable and cannot be
read back through any public API.

</details>

<details>
<summary>Does it support GitHub Enterprise?</summary>

Yes. Set `base_url` in `setup()`:

```lua
require('github').setup({
  token = 'your-token',
  base_url = 'https://github.example.com/api/v3/',
})
```

</details>

## 🙏 Credits

- [wsdjeg/Github.vim](https://github.com/wsdjeg/Github.vim) — the original Vim plugin

## 📣 Self-Promotion

Like this plugin? Star the repository on
[GitHub](https://github.com/wsdjeg/github.nvim).

Love this plugin? Follow [me](https://wsdjeg.net/) on
[GitHub](https://github.com/wsdjeg).

## 📄 License

This project is licensed under the GPL-3.0 License.

