# github.nvim

[![GitHub License](https://img.shields.io/github/license/wsdjeg/github.nvim)](LICENSE)
[![GitHub Issues or Pull Requests](https://img.shields.io/github/issues/wsdjeg/github.nvim)](https://github.com/wsdjeg/github.nvim/issues)
[![GitHub commit activity](https://img.shields.io/github/commit-activity/m/wsdjeg/github.nvim)](https://github.com/wsdjeg/github.nvim/commits/master/)
[![GitHub Release](https://img.shields.io/github/v/release/wsdjeg/github.nvim)](https://github.com/wsdjeg/github.nvim/releases)
[![luarocks](https://img.shields.io/luarocks/v/wsdjeg/github.nvim)](https://luarocks.org/modules/wsdjeg/github.nvim)

github.nvim is a github REST api implementation written in lua. It is inspired from [github.vim](https://github.com/wsdjeg/github.vim).

**Note:** This project is under active development. API functions may change without prior notice.

<!-- vim-markdown-toc GFM -->

- [Installation](#installation)
- [APIs](#apis)
    - [rulesets](#rulesets)
- [Credits](#credits)
- [Self-Promotion](#self-promotion)
- [License](#license)

<!-- vim-markdown-toc -->

## Installation

Using [nvim-plug](https://github.com/wsdjeg/nvim-plug)

```lua
require('plug').add({
    { 'wsdjeg/github.nvim' }
})
```

Using [luarocks](https://luarocks.org/)

```
luarocks install github.nvim
```

## APIs

### rulesets

```
get_repository_rules(user, repo)

get_branch_rules(user, repo, branch)

create_ruleset(user, repo, ruleset)

get_repository_ruleset(user, repo, id)

update_ruleset(user, repo, id, ruleset)

delete_ruleset(user, repo, id)

get_ruleset_history(user, repo, id)

get_ruleset_version(user, repo, id, version)
```

## Credits

- [wsdjeg/Github.vim](https://github.com/wsdjeg/Github.vim)

## Self-Promotion

Like this plugin? Star the repository on
GitHub.

Love this plugin? Follow [me](https://wsdjeg.net/) on
[GitHub](https://github.com/wsdjeg).

## License

This project is licensed under the GPL-3.0 License.
