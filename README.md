# github.nvim [WIP]

github.nvim is a github REST api implementation written in lua. It is inspired from [github.vim](https://github.com/wsdjeg/github.vim).

this status of this project is wip, and api functions maybe changed without notification.

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

