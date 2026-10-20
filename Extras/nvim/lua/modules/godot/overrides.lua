-- Gutter marks for methods that override an engine virtual (_ready,
-- _process, ...) or a method from a parent script, mirroring the Godot
-- editor's override indicator.
--
-- Engine class data comes from `godot --headless --dump-extension-api`,
-- reduced to { class = { inherits, virtuals } } and cached across sessions
-- in stdpath('cache'); it is generated automatically on first use and
-- :GodotApiDump regenerates it (e.g. after an engine upgrade). Without a
-- godot binary a small builtin subset of common virtuals is used.

local M = {}

local ns = vim.api.nvim_create_namespace('godot-overrides')
local root
local api, api_is_fallback
local cache_file = vim.fn.stdpath('cache') .. '/godot-extension-api.json'
local script_cache = {} -- .gd path -> { key, funcs, extends, class_name }

-- stylua: ignore
local FALLBACK = {
  Object = { virtuals = { _init = true, _notification = true, _to_string = true, _get = true, _set = true, _get_property_list = true, _validate_property = true } },
  Node = { inherits = 'Object', virtuals = { _ready = true, _process = true, _physics_process = true, _enter_tree = true, _exit_tree = true, _input = true, _unhandled_input = true, _unhandled_key_input = true, _shortcut_input = true, _get_configuration_warnings = true } },
  CanvasItem = { inherits = 'Node', virtuals = { _draw = true } },
  Control = { inherits = 'CanvasItem', virtuals = { _gui_input = true, _can_drop_data = true, _drop_data = true, _get_drag_data = true, _has_point = true, _get_minimum_size = true, _get_tooltip = true } },
}

local function read_file(path)
  local f = io.open(path)
  if not f then
    return nil
  end
  local text = f:read('*a')
  f:close()
  return text
end

local function load_cached_api()
  local text = read_file(cache_file)
  if not text then
    return nil
  end
  local ok, data = pcall(vim.json.decode, text)
  return ok and type(data) == 'table' and next(data) and data or nil
end

function M.dump_api(on_done)
  local godot = vim.fn.exepath('godot')
  if godot == '' then
    return vim.notify('godot executable not found in PATH', vim.log.levels.WARN)
  end
  local tmp = vim.fn.tempname()
  vim.fn.mkdir(tmp, 'p')
  vim.system(
    { godot, '--headless', '--dump-extension-api' },
    { cwd = tmp },
    vim.schedule_wrap(function()
      local text = read_file(tmp .. '/extension_api.json')
      vim.fn.delete(tmp, 'rf')
      if not text then
        return vim.notify('godot --dump-extension-api produced no output', vim.log.levels.WARN)
      end
      local reduced = {}
      for _, cls in ipairs(vim.json.decode(text).classes or {}) do
        local virtuals = {}
        for _, method in ipairs(cls.methods or {}) do
          if method.is_virtual then
            virtuals[method.name] = true
          end
        end
        reduced[cls.name] = { inherits = cls.inherits, virtuals = virtuals }
      end
      vim.fn.writefile({ vim.json.encode(reduced) }, cache_file)
      api, api_is_fallback = reduced, false
      if on_done then
        on_done()
      end
    end)
  )
end

local function engine_virtuals(class)
  local set, seen = {}, {}
  if api_is_fallback and class and not api[class] then
    class = 'Node' -- unknown class in the small fallback table: assume a Node
  end
  while class and api[class] and not seen[class] do
    seen[class] = true
    for name in pairs(api[class].virtuals or {}) do
      set[name] = true
    end
    class = api[class].inherits
  end
  return set
end

local function parse_extends(line)
  local ext = line:match('^extends%s+(%S+)')
    or line:match('^class_name%s+[%w_]+%s+extends%s+(%S+)')
  return ext and ext:gsub('"', '') or nil
end

local function script_info(path)
  local stat = vim.uv.fs_stat(path)
  if not stat then
    return nil
  end
  local key = stat.mtime.sec .. ':' .. stat.size
  if script_cache[path] and script_cache[path].key == key then
    return script_cache[path]
  end
  local info = { key = key, funcs = {} }
  for line in io.lines(path) do
    info.extends = info.extends or parse_extends(line)
    info.class_name = info.class_name or line:match('^class_name%s+([%w_]+)')
    local name = line:match('^func%s+([%w_]+)')
    if name then
      info.funcs[name] = true
    end
  end
  script_cache[path] = info
  return info
end

-- class_name -> script path, over all project scripts (parses are cached)
local function class_index()
  local idx = {}
  for _, path in ipairs(vim.fn.glob(root .. '/**/*.gd', true, true)) do
    local info = script_info(path)
    if info and info.class_name then
      idx[info.class_name] = path
    end
  end
  return idx
end

function M.refresh(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  local file = vim.api.nvim_buf_get_name(buf)
  if not root or file:sub(1, #root + 1) ~= root .. '/' then
    return
  end

  local funcs, extends = {}, nil -- from the buffer, not disk: edits count
  for i, line in ipairs(vim.api.nvim_buf_get_lines(buf, 0, -1, false)) do
    extends = extends or parse_extends(line)
    local name = line:match('^func%s+([%w_]+)')
    if name and not funcs[name] then
      funcs[name] = i
    end
  end

  -- Walk the script inheritance chain until an engine class is reached
  local idx = class_index()
  local parent_funcs, engine_class = {}, nil
  local ext, seen = extends, {}
  while ext do
    local path = ext:find('^res://') and (root .. '/' .. ext:sub(7)) or idx[ext]
    if not path or seen[path] then
      engine_class = not path and ext or nil
      break
    end
    seen[path] = true
    local info = script_info(path)
    if not info then
      break
    end
    for name in pairs(info.funcs) do
      parent_funcs[name] = true
    end
    ext = info.extends
  end
  local virtuals = engine_virtuals(engine_class)

  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  local lines = vim.empty_dict()
  for name, lnum in pairs(funcs) do
    if parent_funcs[name] or virtuals[name] then
      lines[tostring(lnum)] = true
      vim.api.nvim_buf_set_extmark(buf, ns, lnum - 1, 0, {
        sign_text = '󰕍',
        sign_hl_group = 'GodotSignOverride',
        priority = 9, -- below signal connection marks
      })
    end
  end
  -- read by the snacks statuscolumn to place these next to the code
  vim.b[buf].godot_override_lines = lines
end

local function refresh_loaded()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.bo[buf].filetype == 'gdscript' and vim.api.nvim_buf_is_loaded(buf) then
      M.refresh(buf)
    end
  end
end

function M.setup(project_root)
  root = project_root
  -- "GodotSign" prefix is matched by the snacks statuscolumn git patterns
  vim.api.nvim_set_hl(0, 'GodotSignOverride', { link = 'DiagnosticSignInfo', default = true })
  api = load_cached_api()
  api_is_fallback = api == nil
  api = api or FALLBACK
  if api_is_fallback and vim.fn.exepath('godot') ~= '' then
    M.dump_api(refresh_loaded)
  end

  local group = vim.api.nvim_create_augroup('godot-overrides', { clear = true })
  vim.api.nvim_create_autocmd({ 'FileType', 'BufWritePost' }, {
    desc = 'Mark methods overriding engine or parent-script methods',
    group = group,
    callback = function(event)
      if vim.bo[event.buf].filetype == 'gdscript' then
        M.refresh(event.buf)
      end
    end,
  })
  vim.api.nvim_create_autocmd('FocusGained', {
    desc = 'Refresh override marks after external script changes',
    group = group,
    callback = refresh_loaded,
  })

  vim.api.nvim_create_user_command('GodotApiDump', function()
    M.dump_api(function()
      refresh_loaded()
      vim.notify('Godot extension API cache regenerated')
    end)
  end, { desc = 'Regenerate the cached Godot class API (after engine upgrades)' })
end

return M
