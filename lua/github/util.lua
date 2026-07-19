--[[
  基于 wsdjeg/job.nvim 的异步请求模块

  特性：
  - 异步 GET / POST / PATCH / PUT / DELETE 请求
  - 支持回调函数 (on_success / on_error / on_exit)
  - 支持超时控制 (job.nvim 层面 + curl 层面)
  - 支持请求取消
  - 保留同步 API 向后兼容
--]]
local job = require('job')
local M = {}

local root_url = 'https://api.github.com/'

-- 私有 token，仅可通过 set_token 写入，不提供读取接口
local token

-- 正在运行的异步请求
M._pending = {}

--- 设置 GitHub API base URL
---@param url string
function M.set_base_url(url)
  root_url = url
end

--- 设置 GitHub token（仅写入，不提供读取）
---@param t string
function M.set_token(t)
  token = t
end

--- 构造完整 URL
---@param path string API 路径
---@return string
local function build_url(path)
  return root_url .. path
end

--- 构造 curl 命令
---@param path string API 路径
---@param args table? 额外 curl 参数 (-X, -d 等)
---@return table cmd curl 命令列表
local function build_curl_cmd(path, args)
  local url = build_url(path)
  local cmd = {
    'curl',
    '-s',
    '-L',
    '-H', 'Accept: application/vnd.github+json',
    '-H', 'Authorization: token ' .. (token or ''),
    '-H', 'X-GitHub-Api-Version: 2022-11-28',
  }
  if args and #args > 0 then
    for _, v in ipairs(args) do
      cmd[#cmd + 1] = v
    end
  end
  cmd[#cmd + 1] = '-w'
  cmd[#cmd + 1] = '\n%{http_code}'
  cmd[#cmd + 1] = url
  return cmd
end

-- ============================================================
-- 同步请求 (向后兼容，基于 vim.fn.systemlist)
-- ============================================================

--- 同步请求 (保持原有 API 不变)
---@param path string API 路径
---@param args table? 额外 curl 参数
---@return table|nil 解析后的 JSON
function M.request(path, args)
  local cmd = build_curl_cmd(path, args)
  -- 去掉最后两个 -w 参数，同步模式不需要解析 http_code
  table.remove(cmd) -- url
  table.remove(cmd) -- %{http_code}
  table.remove(cmd) -- -w
  cmd[#cmd + 1] = build_url(path)

  local result = table.concat(vim.fn.systemlist(cmd), '\n')
  local ok, obj = pcall(vim.json.decode, result)
  if not ok then
    return {}
  end
  return obj
end

-- ============================================================
-- 异步请求 (基于 job.nvim，支持回调函数)
-- ============================================================

--[[
  异步请求

  @param path       string   API 路径，如 "repos/wsdjeg/job.nvim/issues"
  @param args       table?   额外 curl 参数，如 {"-X", "POST", "-d", '{"title":"test"}'}
  @param callbacks  table?   回调函数
    - on_success (fun(id, data, http_code))  请求成功 (2xx)
    - on_error   (fun(id, err, http_code?))  请求失败 (非 2xx 或 curl 异常)
    - on_exit    (fun(id, code, signal))     请求结束 (无论成功/失败)

  @param opts       table?   额外选项
    - timeout  integer  超时毫秒 (job.nvim 层面，默认 30000)

  @return integer job_id (>0 成功, <=0 失败)

  用法示例:

    util.request_async("repos/wsdjeg/job.nvim/issues", nil, {
      on_success = function(id, data, code)
        print("获取到 " .. #data .. " 个 issue")
      end,
      on_error = function(id, err)
        print("请求失败: " .. err)
      end,
    })
--]]
function M.request_async(path, args, callbacks, opts)
  callbacks = callbacks or {}
  opts = opts or {}

  local cmd = build_curl_cmd(path, args)
  local stdout_lines = {}
  local stderr_lines = {}

  local jobid = job.start(cmd, {
    timeout = opts.timeout or 30000,
    on_stdout = function(id, data)
      for _, line in ipairs(data) do
        if line ~= '' then
          stdout_lines[#stdout_lines + 1] = line
        end
      end
    end,
    on_stderr = function(id, data)
      for _, line in ipairs(data) do
        if line ~= '' then
          stderr_lines[#stderr_lines + 1] = line
        end
      end
    end,
    on_exit = function(id, code, signal)
      M._pending[id] = nil

      if code == 0 and signal == 0 then
        -- 解析 HTTP 状态码 (最后一行)
        local http_code = 200
        if #stdout_lines > 0 then
          local last = stdout_lines[#stdout_lines]
          if tonumber(last) then
            http_code = tonumber(last)
            table.remove(stdout_lines)
          end
        end

        local raw = table.concat(stdout_lines, '\n')
        local ok, data = pcall(vim.json.decode, raw)

        if http_code >= 200 and http_code < 300 then
          if callbacks.on_success then
            callbacks.on_success(id, ok and data or {}, http_code)
          end
        else
          local err_msg = ok and (data.message or raw) or raw
          if callbacks.on_error then
            callbacks.on_error(id, err_msg, http_code)
          end
        end
      else
        -- curl 异常退出 (超时 / 网络错误等)
        local err_msg = table.concat(stderr_lines, '\n')
        if err_msg == '' then
          if signal == 15 then
            err_msg = 'request timeout (killed by SIGTERM)'
          else
            err_msg = string.format('curl exited with code %d, signal %d', code, signal)
          end
        end
        if callbacks.on_error then
          callbacks.on_error(id, err_msg)
        end
      end

      if callbacks.on_exit then
        callbacks.on_exit(id, code, signal)
      end
    end,
  })

  if jobid > 0 then
    M._pending[jobid] = {
      path = path,
      start_time = vim.loop.hrtime(),
    }
  end

  return jobid
end

-- ============================================================
-- 便捷方法
-- ============================================================

--- 异步 GET
---@param path string
---@param callbacks table
---@param opts table?
---@return integer
function M.get_async(path, callbacks, opts)
  return M.request_async(path, nil, callbacks, opts)
end

--- 异步 POST
---@param path string
---@param body string JSON 字符串
---@param callbacks table
---@param opts table?
---@return integer
function M.post_async(path, body, callbacks, opts)
  return M.request_async(path, { '-X', 'POST', '-d', body }, callbacks, opts)
end

--- 异步 PATCH
---@param path string
---@param body string JSON 字符串
---@param callbacks table
---@param opts table?
---@return integer
function M.patch_async(path, body, callbacks, opts)
  return M.request_async(path, { '-X', 'PATCH', '-d', body }, callbacks, opts)
end

--- 异步 PUT
---@param path string
---@param body string JSON 字符串
---@param callbacks table
---@param opts table?
---@return integer
function M.put_async(path, body, callbacks, opts)
  return M.request_async(path, { '-X', 'PUT', '-d', body }, callbacks, opts)
end

--- 异步 DELETE
---@param path string
---@param callbacks table
---@param opts table?
---@return integer
function M.delete_async(path, callbacks, opts)
  return M.request_async(path, { '-X', 'DELETE' }, callbacks, opts)
end

--- 取消正在运行的异步请求
---@param jobid integer
function M.cancel(jobid)
  if M._pending[jobid] then
    job.stop(jobid, 15) -- SIGTERM
    M._pending[jobid] = nil
  end
end

--- 获取活跃请求数量
---@return integer
function M.pending_count()
  local n = 0
  for _ in pairs(M._pending) do
    n = n + 1
  end
  return n
end

return M

