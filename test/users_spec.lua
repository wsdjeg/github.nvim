-- test/users_spec.lua
local lu = require('luaunit')
local helpers = require('helpers')
local users = require('github.users')

TestUsers = {}

-- ============================================================
-- Sync API
-- ============================================================

function TestUsers:testGetUser()
  local captured, restore = helpers.mock_util()
  users.get_user('octocat')
  restore()

  lu.assertEquals(captured.sync[1].path, 'users/octocat')
end

function TestUsers:testGetAuthenticatedUser()
  local captured, restore = helpers.mock_util()
  users.get_authenticated_user()
  restore()

  lu.assertEquals(captured.sync[1].path, 'user')
end

function TestUsers:testUpdateUser()
  local captured, restore = helpers.mock_util()
  users.update_user({ name = 'New Name', location = 'Earth' })
  restore()

  lu.assertEquals(captured.sync[1].path, 'user')
  lu.assertEquals(captured.sync[1].args[2], 'PATCH')
  local body = vim.json.decode(captured.sync[1].args[4])
  lu.assertEquals(body.name, 'New Name')
  lu.assertEquals(body.location, 'Earth')
end

function TestUsers:testListFollowers()
  local captured, restore = helpers.mock_util()
  users.list_followers('octocat')
  restore()

  lu.assertEquals(captured.sync[1].path, 'users/octocat/followers')
end

function TestUsers:testListFollowing()
  local captured, restore = helpers.mock_util()
  users.list_following('octocat')
  restore()

  lu.assertEquals(captured.sync[1].path, 'users/octocat/following')
end

function TestUsers:testListRepos()
  local captured, restore = helpers.mock_util()
  users.list_repos('octocat')
  restore()

  lu.assertEquals(captured.sync[1].path, 'users/octocat/repos')
end

function TestUsers:testListReposWithParams()
  local captured, restore = helpers.mock_util()
  users.list_repos('octocat', { type = 'owner', sort = 'updated' })
  restore()

  local path = captured.sync[1].path
  lu.assertStrContains(path, 'type=owner')
  lu.assertStrContains(path, 'sort=updated')
end

function TestUsers:testGetOrg()
  local captured, restore = helpers.mock_util()
  users.get_org('github')
  restore()

  lu.assertEquals(captured.sync[1].path, 'orgs/github')
end

function TestUsers:testUpdateOrg()
  local captured, restore = helpers.mock_util()
  users.update_org('github', { description = 'New desc' })
  restore()

  lu.assertEquals(captured.sync[1].path, 'orgs/github')
  lu.assertEquals(captured.sync[1].args[2], 'PATCH')
end

function TestUsers:testListMembers()
  local captured, restore = helpers.mock_util()
  users.list_members('github')
  restore()

  lu.assertEquals(captured.sync[1].path, 'orgs/github/members')
end

function TestUsers:testListMembersWithParams()
  local captured, restore = helpers.mock_util()
  users.list_members('github', { role = 'admin' })
  restore()

  lu.assertStrContains(captured.sync[1].path, 'role=admin')
end

function TestUsers:testListOrgRepos()
  local captured, restore = helpers.mock_util()
  users.list_org_repos('github')
  restore()

  lu.assertEquals(captured.sync[1].path, 'orgs/github/repos')
end

-- ============================================================
-- Async API
-- ============================================================

function TestUsers:testGetUserAsync()
  local captured, restore = helpers.mock_util()
  users.get_user_async('octocat', {})
  restore()

  lu.assertEquals(captured.async[1].method, 'GET')
  lu.assertEquals(captured.async[1].path, 'users/octocat')
end

function TestUsers:testGetAuthenticatedUserAsync()
  local captured, restore = helpers.mock_util()
  users.get_authenticated_user_async({})
  restore()

  lu.assertEquals(captured.async[1].path, 'user')
end

function TestUsers:testUpdateUserAsync()
  local captured, restore = helpers.mock_util()
  users.update_user_async({ name = 'New' }, {})
  restore()

  lu.assertEquals(captured.async[1].method, 'PATCH')
  lu.assertEquals(captured.async[1].path, 'user')
end

function TestUsers:testListFollowersAsync()
  local captured, restore = helpers.mock_util()
  users.list_followers_async('octocat', {})
  restore()

  lu.assertEquals(captured.async[1].path, 'users/octocat/followers')
end

function TestUsers:testListReposAsync()
  local captured, restore = helpers.mock_util()
  users.list_repos_async('octocat', { sort = 'created' }, {})
  restore()

  lu.assertEquals(captured.async[1].method, 'GET')
  lu.assertStrContains(captured.async[1].path, 'sort=created')
end

function TestUsers:testGetOrgAsync()
  local captured, restore = helpers.mock_util()
  users.get_org_async('github', {})
  restore()

  lu.assertEquals(captured.async[1].path, 'orgs/github')
end

function TestUsers:testUpdateOrgAsync()
  local captured, restore = helpers.mock_util()
  users.update_org_async('github', { description = 'x' }, {})
  restore()

  lu.assertEquals(captured.async[1].method, 'PATCH')
  lu.assertEquals(captured.async[1].path, 'orgs/github')
end

function TestUsers:testListMembersAsync()
  local captured, restore = helpers.mock_util()
  users.list_members_async('github', nil, {})
  restore()

  lu.assertEquals(captured.async[1].path, 'orgs/github/members')
end

function TestUsers:testListOrgReposAsync()
  local captured, restore = helpers.mock_util()
  users.list_org_repos_async('github', nil, {})
  restore()

  lu.assertEquals(captured.async[1].path, 'orgs/github/repos')
end

return TestUsers

