-- test/minimal_init.lua
-- Minimal Neovim configuration for testing github.nvim

print('Initializing test environment...')

-- Set up essential settings
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undofile = false

-- Set up package path for:
-- 1. lua/?.lua      - Main plugin source code
-- 2. test/?.lua     - Mock modules (like job.lua) and test helpers
-- 3. test/.deps/?.lua - Test dependencies (luaunit)
package.path = 'lua/?.lua;test/?.lua;test/.deps/?.lua;' .. package.path
vim.opt.runtimepath:prepend('.')

-- Ensure GITHUB_TOKEN is set for tests (can be a dummy value)
if not vim.env.GITHUB_TOKEN then
  vim.env.GITHUB_TOKEN = 'test-token'
end

print('Test environment initialized successfully')

