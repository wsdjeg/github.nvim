-- test/job.lua
-- Mock job module for testing async requests
-- Simulates the job.nvim API without making real subprocess calls

local M = {}

M._calls = {}
M._next_id = 1
M._responses = {}
M._auto_response = nil

--- Reset mock state
function M.reset()
  M._calls = {}
  M._next_id = 1
  M._responses = {}
  M._auto_response = nil
end

--- Set a default response for all jobs
--- @param response table {stdout={...}, stderr={...}, code=0, signal=0}
function M.set_auto_response(response)
  M._auto_response = response
end

--- Set a specific response for a job_id
function M.set_response(job_id, response)
  M._responses[job_id] = response
end

--- Get all recorded calls
function M.get_calls()
  return M._calls
end

--- Start a mock job
--- @param cmd table command list
--- @param opts table job options (on_stdout, on_stderr, on_exit, timeout)
--- @return integer job_id
function M.start(cmd, opts)
  local id = M._next_id
  M._next_id = M._next_id + 1

  M._calls[#M._calls + 1] = {
    id = id,
    cmd = cmd,
    opts = opts,
  }

  -- Determine response
  local response = M._responses[id] or M._auto_response or {
    stdout = { '{}', '200' },
    stderr = {},
    code = 0,
    signal = 0,
  }

  -- Call callbacks synchronously for test simplicity
  if opts.on_stdout and response.stdout then
    opts.on_stdout(id, response.stdout)
  end
  if opts.on_stderr and response.stderr and #response.stderr > 0 then
    opts.on_stderr(id, response.stderr)
  end
  if opts.on_exit then
    opts.on_exit(id, response.code or 0, response.signal or 0)
  end

  return id
end

--- Stop a mock job
--- @param jobid integer
--- @param signal integer
function M.stop(jobid, signal)
  -- no-op for testing
end

return M

