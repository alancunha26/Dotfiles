local dir = vim.fn.getcwd() .. '/.zk'
if vim.fn.isdirectory(dir) == 0 then
  return false
end

local config_path = dir .. '/config.json'
if vim.fn.filereadable(config_path) == 0 then
  return false
end

local data = vim.fn.readfile(config_path)
local config = vim.fn.json_decode(data)

config.notes_path = config.notes_path or ''

return config
