-- Gutter marks for methods connected to signals in Godot scene files,
-- mirroring the editor's connection indicator.
--
-- Editor-made connections are stored in .tscn files as
-- [connection signal="pressed" from="Button" to="." method="_on_pressed"].
-- This scans the project's scenes, resolves which script the receiving
-- node has attached, and places a sign on the matching `func` line.
-- :GodotSignalConnections lists the buffer's connections and jumps to the
-- scene file that defines them.

local M = {}

local ns = vim.api.nvim_create_namespace('godot-signals')
local root
local cache = {} -- tscn path -> { key = mtime:size, connections }

local function attrs(line)
  local t = {}
  for k, v in line:gmatch('(%w+)="([^"]*)"') do
    t[k] = v
  end
  -- Godot 3 uses unquoted numeric ids
  t.id = t.id or line:match('%sid=(%d+)')
  return t
end

---@return table { [res:// script] = { [method] = { {signal, from, scene, lnum} } } }
local function parse_scene(path)
  local stat = vim.uv.fs_stat(path)
  if not stat then
    return nil
  end
  local key = stat.mtime.sec .. ':' .. stat.size
  if cache[path] and cache[path].key == key then
    return cache[path].connections
  end

  local scripts = {} -- ext_resource id -> res:// path
  local node_script = {} -- node path -> res:// path
  local node -- path of the [node] section currently being read
  local conns = {}
  local lnum = 0
  for line in io.lines(path) do
    lnum = lnum + 1
    local section = line:match('^%[([%w_]+)')
    if section == 'ext_resource' then
      local a = attrs(line)
      if a.type == 'Script' and a.id and a.path then
        scripts[a.id] = a.path
      end
    elseif section == 'node' then
      local a = attrs(line)
      if not a.parent then
        node = '.'
      elseif a.parent == '.' then
        node = a.name
      else
        node = a.parent .. '/' .. a.name
      end
    elseif section == 'connection' then
      local a = attrs(line)
      local script = node_script[a.to]
      if script and a.method then
        local per = conns[script] or {}
        local list = per[a.method] or {}
        list[#list + 1] = { signal = a.signal, from = a.from, scene = path, lnum = lnum }
        per[a.method] = list
        conns[script] = per
      end
    elseif section then
      node = nil
    elseif node then
      local id = line:match('^script = ExtResource%(%s*"?([^%)"]+)"?%s*%)')
      if id and scripts[id] then
        node_script[node] = scripts[id]
      end
    end
  end
  cache[path] = { key = key, connections = conns }
  return conns
end

local function buffer_methods(buf)
  local methods = {}
  for i, line in ipairs(vim.api.nvim_buf_get_lines(buf, 0, -1, false)) do
    local name = line:match('^%s*func%s+([%w_]+)')
    if name and not methods[name] then
      methods[name] = i
    end
  end
  return methods
end

function M.refresh(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  local file = vim.api.nvim_buf_get_name(buf)
  if not root or file:sub(1, #root + 1) ~= root .. '/' then
    return
  end
  local res_path = 'res://' .. file:sub(#root + 2)

  local conns = {}
  for _, scene in ipairs(vim.fn.glob(root .. '/**/*.tscn', true, true)) do
    local per = (parse_scene(scene) or {})[res_path]
    if per then
      for method, list in pairs(per) do
        conns[method] = vim.list_extend(conns[method] or {}, list)
      end
    end
  end
  vim.b[buf].godot_signal_connections = conns

  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  local lines = vim.empty_dict()
  for method, lnum in pairs(buffer_methods(buf)) do
    if conns[method] then
      lines[tostring(lnum)] = true
      vim.api.nvim_buf_set_extmark(buf, ns, lnum - 1, 0, {
        sign_text = '',
        sign_hl_group = 'GodotSignSignal',
        priority = 11, -- above override marks: connection wins when both apply
      })
    end
  end
  -- read by the snacks statuscolumn to place these next to the code
  vim.b[buf].godot_signal_lines = lines
end

function M.setup(project_root)
  root = project_root
  -- "GodotSign" prefix is matched by the snacks statuscolumn git patterns
  vim.api.nvim_set_hl(0, 'GodotSignSignal', { link = 'DiagnosticSignOk', default = true })
  local group = vim.api.nvim_create_augroup('godot-signals', { clear = true })

  vim.api.nvim_create_autocmd({ 'FileType', 'BufWritePost' }, {
    desc = 'Mark signal-connected methods',
    group = group,
    callback = function(event)
      if vim.bo[event.buf].filetype == 'gdscript' then
        M.refresh(event.buf)
      end
    end,
  })

  -- Scenes are edited in Godot; re-check when coming back to nvim
  vim.api.nvim_create_autocmd('FocusGained', {
    desc = 'Refresh signal marks after scene changes',
    group = group,
    callback = function()
      for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.bo[buf].filetype == 'gdscript' and vim.api.nvim_buf_is_loaded(buf) then
          M.refresh(buf)
        end
      end
    end,
  })

  vim.api.nvim_create_user_command('GodotSignalConnections', function()
    local conns = vim.b.godot_signal_connections or {}
    local items = {}
    for method, list in pairs(conns) do
      for _, c in ipairs(list) do
        items[#items + 1] = {
          label = ('%s ← %s.%s (%s)'):format(
            method,
            c.from,
            c.signal,
            vim.fn.fnamemodify(c.scene, ':t')
          ),
          conn = c,
        }
      end
    end
    if #items == 0 then
      return vim.notify('No signal connections for this script', vim.log.levels.INFO)
    end
    table.sort(items, function(a, b)
      return a.label < b.label
    end)
    vim.ui.select(items, {
      prompt = 'Signal connections',
      format_item = function(item)
        return item.label
      end,
    }, function(choice)
      if choice then
        vim.cmd('edit ' .. vim.fn.fnameescape(choice.conn.scene))
        vim.api.nvim_win_set_cursor(0, { choice.conn.lnum, 0 })
      end
    end)
  end, { desc = 'List signal connections targeting this script' })
end

return M
