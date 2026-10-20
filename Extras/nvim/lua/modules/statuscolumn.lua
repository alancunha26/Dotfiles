-- Custom status column, replacing the snacks one to fit more per line:
--
--   [margin][diagnostics/dap][godot mark]  [number]  [fold]  code
--
-- The snacks statuscolumn only has one icon slot per side, so the Godot
-- connection/override marks (modules/godot) would displace the fold arrow
-- or the diagnostics. Here each gets its own cell: diagnostics and Godot
-- marks sit side by side before the numbers with a margin from the screen
-- edge, and fold arrows are always visible. Git signs color the fold
-- arrow when both are present (as snacks' folds.git_hl did) and otherwise
-- show in the fold cell.

local M = {}

-- Built via nr2char so the glyphs can't be mangled in the source file
local FOLD_OPEN = vim.fn.nr2char(0xf078) -- fa chevron-down
local FOLD_CLOSE = vim.fn.nr2char(0xf054) -- fa chevron-right

local sign_cache = {} ---@type table<number, table<number, table>>
local timer = vim.uv.new_timer()

-- One extmark scan per buffer per 50ms tick, shared by all displayed lines
local function buf_signs(buf)
  if sign_cache[buf] then
    return sign_cache[buf]
  end
  local signs = {}
  for _, e in ipairs(vim.api.nvim_buf_get_extmarks(buf, -1, 0, -1, { details = true, type = 'sign' })) do
    local lnum, d = e[2] + 1, e[4]
    local name = d.sign_hl_group or d.sign_name or ''
    local kind = 'sign' -- diagnostics, dap, anything else
    if name:find('GodotSign') then
      kind = 'godot'
    elseif name:find('GitSign') or name:find('MiniDiffSign') then
      kind = 'git'
    end
    local cur = signs[lnum] and signs[lnum][kind]
    if not cur or (d.priority or 0) > (cur.priority or 0) then
      signs[lnum] = signs[lnum] or {}
      signs[lnum][kind] = { text = d.sign_text, hl = d.sign_hl_group, priority = d.priority }
    end
  end
  sign_cache[buf] = signs
  timer:start(50, 0, function()
    sign_cache = {}
  end)
  return signs
end

-- A 2-cell icon slot: pad or truncate, wrap in its highlight
local function cell(sign)
  if not sign or not sign.text then
    return '  '
  end
  local text = vim.fn.strcharpart(sign.text, 0, 2)
  text = text .. (' '):rep(2 - vim.fn.strchars(text))
  return sign.hl and ('%#' .. sign.hl .. '#' .. text .. '%*') or text
end

local function fold_sign(win, lnum, git)
  local fillchars = vim.opt.fillchars:get()
  local icon
  vim.api.nvim_win_call(win, function()
    if vim.fn.foldclosed(lnum) == lnum then
      icon = { text = fillchars.foldclose or FOLD_CLOSE, hl = git and git.hl or 'Folded' }
    elseif vim.fn.foldlevel(lnum) > vim.fn.foldlevel(lnum - 1) then
      icon = { text = fillchars.foldopen or FOLD_OPEN, hl = git and git.hl }
    end
  end)
  return icon or git
end

function M.click_fold()
  local pos = vim.fn.getmousepos()
  vim.api.nvim_win_call(pos.winid, function()
    if vim.fn.foldlevel(pos.line) > 0 then
      vim.cmd(pos.line .. (vim.fn.foldclosed(pos.line) == -1 and 'foldclose' or 'foldopen'))
    end
  end)
end

local function render()
  local win = vim.g.statusline_winid or vim.api.nvim_get_current_win()
  local buf = vim.api.nvim_win_get_buf(win)
  if vim.v.virtnum ~= 0 then -- wrapped or virtual line
    return ''
  end

  local signs = buf_signs(buf)[vim.v.lnum] or {}
  local parts = { ' ' .. cell(signs.sign) }

  -- Godot cell only in buffers that have marks, to not widen everything else
  local b = vim.b[buf]
  if b.godot_signal_lines or b.godot_override_lines then
    parts[#parts + 1] = cell(signs.godot)
  end

  local nu, rnu = vim.wo[win].number, vim.wo[win].relativenumber
  if nu or rnu then
    local num = (rnu and nu and vim.v.relnum == 0) and vim.v.lnum
      or (rnu and vim.v.relnum or vim.v.lnum)
    parts[#parts + 1] = '%=' .. num .. ' '
  end

  parts[#parts + 1] = cell(fold_sign(win, vim.v.lnum, signs.git))

  return "%@v:lua.require'modules.statuscolumn'.click_fold@" .. table.concat(parts) .. '%T'
end

function M.get()
  local ok, ret = pcall(render)
  return ok and ret or ''
end

return M
