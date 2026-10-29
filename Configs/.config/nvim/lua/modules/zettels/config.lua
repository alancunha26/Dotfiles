local M = { notes_path = '' }

function M.is_zk_workspace()
  return vim.fn.isdirectory(vim.fn.getcwd() .. '/.zk') == 1
end

if not M.is_zk_workspace() then
  return M
end

local config_path = vim.fn.getcwd() .. '/.zk/config.json'
if vim.fn.filereadable(config_path) == 0 then
  return M
end

local data = vim.fn.readfile(config_path)
local config = vim.fn.json_decode(data)

M.notes_path = config.notes_path or ''

return M
