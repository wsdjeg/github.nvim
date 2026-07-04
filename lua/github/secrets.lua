--[[
  Secrets 模块 (GitHub Actions Secrets)

  同步 API: M.list_repository_secrets / M.delete_repository_secret
            M.get_repository_secrets_public_key / M.update_repository_secret
  异步 API: 以上方法名加 _async 后缀

  注意: update_repository_secret 涉及链式异步操作:
    1. 异步获取公钥
    2. 同步加密 (luasodium)
    3. 异步 PUT 加密后的密钥
--]]
local M = {}

local util = require('github.util')

--- 构造 secrets API 路径
---@param user string
---@param repo string
---@param ... string|number
---@return string
local function build_path(user, repo, ...)
  local segments = { 'repos', user, repo, 'actions', 'secrets' }
  for _, seg in ipairs({ ... }) do
    segments[#segments + 1] = tostring(seg)
  end
  return table.concat(segments, '/')
end

-- ============================================================
-- 同步 API (向后兼容)
-- ============================================================

--- 列出仓库 Secrets
---@param user string
---@param repo string
---@return table
function M.list_repository_secrets(user, repo)
  return util.request(build_path(user, repo))
end

--- 删除仓库 Secret
---@param user string
---@param repo string
---@param secret_name string
---@return table
function M.delete_repository_secret(user, repo, secret_name)
  return util.request(build_path(user, repo, secret_name), {
    '-X', 'DELETE',
  })
end

--- 获取仓库 Secrets 公钥
---@param user string
---@param repo string
---@return table {key_id, key}
function M.get_repository_secrets_public_key(user, repo)
  return util.request(build_path(user, repo, 'public-key'))
end

--- 更新（创建）仓库 Secret
--- 该操作包含链式步骤: 获取公钥 → 加密 → PUT
---@param user string
---@param repo string
---@param secret table {name, value}
---@return table|nil
function M.update_repository_secret(user, repo, secret)
  local key_info = M.get_repository_secrets_public_key(user, repo)
  local key_id = key_info.key_id
  local b64_key = key_info.key

  local ok, sodium = pcall(require, 'luasodium')
  if not ok then
    vim.notify('failed to load luasodium module')
    return
  end

  local public_key_bin = vim.base64.decode(b64_key)
  local encrypted_bin = sodium.crypto_box_seal(secret.value, public_key_bin)
  local encrypted_b64 = vim.base64.encode(encrypted_bin)

  local body = {
    encrypted_value = encrypted_b64,
    key_id = key_id,
  }

  return util.request(build_path(user, repo, secret.name), {
    '-X', 'PUT',
    '-d', vim.json.encode(body),
  })
end

-- ============================================================
-- 异步 API
-- ============================================================

--- 异步列出仓库 Secrets
---@param user string
---@param repo string
---@param callbacks table
---@param opts table?
---@return integer job_id
function M.list_repository_secrets_async(user, repo, callbacks, opts)
  return util.get_async(build_path(user, repo), callbacks, opts)
end

--- 异步删除仓库 Secret
---@return integer job_id
function M.delete_repository_secret_async(user, repo, secret_name, callbacks, opts)
  return util.delete_async(build_path(user, repo, secret_name), callbacks, opts)
end

--- 异步获取仓库 Secrets 公钥
---@return integer job_id
function M.get_repository_secrets_public_key_async(user, repo, callbacks, opts)
  return util.get_async(build_path(user, repo, 'public-key'), callbacks, opts)
end

--- 异步更新（创建）仓库 Secret
--- 链式异步: 获取公钥 → 加密 → PUT
---@param user string
---@param repo string
---@param secret table {name, value}
---@param callbacks table {on_success, on_error, on_exit}
---@param opts table? {timeout?}
---@return integer job_id (第一步的 job_id)
function M.update_repository_secret_async(user, repo, secret, callbacks, opts)
  callbacks = callbacks or {}

  -- Step 1: 异步获取公钥
  return M.get_repository_secrets_public_key_async(user, repo, {
    on_success = function(id, key_info, http_code)
      -- Step 2: 同步加密
      local key_id = key_info.key_id
      local b64_key = key_info.key

      local ok, sodium = pcall(require, 'luasodium')
      if not ok then
        if callbacks.on_error then
          callbacks.on_error(id, 'failed to load luasodium module')
        end
        if callbacks.on_exit then
          callbacks.on_exit(id, 1, 0)
        end
        return
      end

      local public_key_bin = vim.base64.decode(b64_key)
      local encrypted_bin = sodium.crypto_box_seal(secret.value, public_key_bin)
      local encrypted_b64 = vim.base64.encode(encrypted_bin)

      local body = {
        encrypted_value = encrypted_b64,
        key_id = key_id,
      }

      -- Step 3: 异步 PUT 加密后的密钥
      util.put_async(
        build_path(user, repo, secret.name),
        vim.json.encode(body),
        callbacks,
        opts
      )
    end,
    on_error = callbacks.on_error,
    -- 不转发 on_exit，由最终步骤的 on_exit 触发
  }, opts)
end

return M

