local M = { notes_path = '', grimoire_port = 24680, grimoire_http_port = 4321 }

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
-- Grimoire ports for this vault (see the grimoire README): sync relay and web server.
M.grimoire_port = tonumber(config.grimoire_port) or M.grimoire_port
M.grimoire_http_port = tonumber(config.grimoire_http_port) or M.grimoire_http_port

return M
