local default_config = { notes_path = '' }

local dir = vim.fn.getcwd() .. '/.zk'
if vim.fn.isdirectory(dir) == 0 then
  return default_config
end

local config_path = dir .. '/config.json'
if vim.fn.filereadable(config_path) == 0 then
  return default_config
end

local data = vim.fn.readfile(config_path)
local config = vim.fn.json_decode(data)

config.notes_path = config.notes_path or ''

return config
