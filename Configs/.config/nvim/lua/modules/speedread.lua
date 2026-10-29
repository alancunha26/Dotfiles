-- Speed reading (RSVP, Spritz-style) for markdown notes: words flash one at a
-- time with a focus letter on a fixed column, so the eyes never move.
-- Headings show whole and linger, list items carry a "• 3/7" prefix, quotes
-- and inline code keep their colour, tables and code blocks are shown whole
-- and pause until <Space>. The source cursor follows along, so quitting
-- leaves it on the last word read.
--
-- :SpeedRead starts at the cursor. Inside the reader, ? lists the keys (see
-- `keys` below).

local M = {}

M.wpm = 300 -- kept for the session, changed with - and +
M.wpm_step = 25

local ns = vim.api.nvim_create_namespace('speedread')
local state = nil

-- [[ Highlights ]]

local function link(group, candidates)
  for _, candidate in ipairs(candidates) do
    if vim.fn.hlexists(candidate) == 1 then
      vim.api.nvim_set_hl(0, group, { link = candidate, default = true })
      return
    end
  end
end

local function set_highlights()
  link('SpeedReadWord', { 'Normal' })
  link('SpeedReadFocus', { 'DiagnosticError' })
  link('SpeedReadGuide', { 'NonText' })
  link('SpeedReadMuted', { 'Comment' })
  link('SpeedReadPrefix', { 'Special' })
  link('SpeedReadCode', { '@markup.raw.markdown_inline', 'String' })
  link('SpeedReadQuote', { '@markup.quote.markdown', 'Comment' })
  link('SpeedReadBlock', { '@markup.raw.block.markdown', 'String' })
  link('SpeedReadCurrent', { 'CurSearch', 'Search' })
  link('SpeedReadCurrentBlock', { 'Visual' })
  for level = 1, 6 do
    link('SpeedReadH' .. level, { '@markup.heading.' .. level .. '.markdown', 'Title' })
  end
  vim.api.nvim_set_hl(0, 'SpeedReadBold', { bold = true, default = true })
  vim.api.nvim_set_hl(0, 'SpeedReadItalic', { italic = true, default = true })
  vim.api.nvim_set_hl(0, 'SpeedReadHiddenCursor', { blend = 100, nocombine = true, default = true })
end

-- [[ Parsing ]]
-- The note becomes a list of tokens: word, heading, block (code/table) and
-- gap (a blank beat before headings and at rules). Every token remembers its
-- source position so the cursor can follow.

local function hide(s)
  return string.rep(' ', #s)
end

-- Replace markdown syntax that isn't read (link targets, images, html) with
-- spaces, so the byte columns of the remaining words still match the source
local function strip_syntax(line)
  line = line:gsub('!%[[^%]]*%]%b()', hide)
  line = line:gsub('%[%[([^%]|]*)|([^%]]*)%]%]', function(target, alias)
    return hide('[[' .. target .. '|') .. alias .. '  '
  end)
  line = line:gsub('%[%[([^%]]*)%]%]', '  %1  ')
  line = line:gsub('%[([^%]]*)%](%b())', function(text, url)
    return ' ' .. text .. ' ' .. hide(url)
  end)
  line = line:gsub('%[%^[^%]]*%]', hide)
  line = line:gsub('<[^>]+>', hide)
  return line
end

local function clean_text(text)
  text = strip_syntax(text):gsub('[*_`]', ''):gsub('%s+', ' ')
  return vim.trim(text)
end

-- Emphasis markers turn styles on (leading) or off (trailing)
local function toggle_style(style, markers, on)
  if markers:find('`') then
    style.code = on
  end
  local stars = #markers:gsub('[^*_]', '')
  if stars >= 2 then
    style.bold = on
  end
  if stars == 1 or stars >= 3 then
    style.italic = on
  end
end

local function count_words(text)
  return select(2, text:gsub('%S+', ''))
end

local function parse(lines)
  local tokens = {}
  local ctx = { crumbs = '', prefix = nil, quote = false, style = {}, new_para = true, new_sentence = true }
  local headings = {}
  local lists = {} -- open lists, innermost last: { indent, count, ordered }
  local prev_blank = true

  local function end_para()
    local last = tokens[#tokens]
    if last and last.kind == 'word' then
      last.para_end = true
    end
    ctx.style = {}
    ctx.new_para = true
    ctx.new_sentence = true
  end

  local function leave_lists()
    lists = {}
    ctx.prefix = nil
  end

  local function add_structure(tok)
    tok.para = true
    tok.sentence = true
    tok.crumbs = tok.crumbs or ctx.crumbs
    tok.last = tok.last or tok.lnum
    table.insert(tokens, tok)
  end

  local function add_words(line, lnum)
    line = strip_syntax(line)
    local pos = 1
    while true do
      local s, e = line:find('%S+', pos)
      if not s then
        break
      end
      pos = e + 1
      local raw = line:sub(s, e)
      local lead = raw:match('^[*_`~]+') or ''
      local rest = raw:sub(#lead + 1)
      local body, close, punct = rest:match('^(.-)([*_`~]+)(%p*)$')
      if not body then
        body, close, punct = rest, '', ''
      end
      toggle_style(ctx.style, lead, true)
      local text = body .. punct
      local prev = tokens[#tokens]
      if text:match('^%p+$') and prev and prev.kind == 'word' and prev.lnum == lnum then
        -- Punctuation left alone after a link: "[text](url)."
        prev.text = prev.text .. text
        ctx.new_sentence = text:find('[.!?]["\')%]]*$') ~= nil
      elseif text ~= '' then
        table.insert(tokens, {
          kind = 'word',
          text = text,
          lnum = lnum,
          last = lnum,
          col = s - 1 + #lead,
          ecol = s - 1 + #lead + #body,
          bold = ctx.style.bold,
          italic = ctx.style.italic,
          code = ctx.style.code,
          quote = ctx.quote,
          crumbs = ctx.crumbs,
          prefix = ctx.prefix,
          para = ctx.new_para,
          sentence = ctx.new_sentence,
        })
        ctx.new_para = false
        ctx.new_sentence = text:find('[.!?]["\')%]]*$') ~= nil
      end
      toggle_style(ctx.style, close, false)
    end
  end

  local i = 1
  if lines[1] == '---' then -- frontmatter
    local j = 2
    while j <= #lines and lines[j] ~= '---' and lines[j] ~= '...' do
      j = j + 1
    end
    if j <= #lines then
      i = j + 1
    end
  end

  while i <= #lines do
    local line = lines[i]
    local indent = line:match('^%s*')
    local blank = line:match('^%s*$') ~= nil

    if line:match('^%s*<!%-%-') and not line:find('%-%->') then
      while i < #lines and not lines[i]:find('%-%->') do
        i = i + 1
      end
    elseif line:match('^%s*<!%-%-.*%-%->%s*$') then
      -- whole-line comment, e.g. zk-view markers: nothing to read
    elseif line:match('^%s*```') or line:match('^%s*~~~') then
      local fence = line:match('^%s*([`~]+)')
      local lang = vim.trim(line:sub(#indent + #fence + 1))
      local body = {}
      local j = i + 1
      while j <= #lines and not lines[j]:match('^%s*' .. vim.pesc(fence)) do
        table.insert(body, (lines[j]:gsub('^' .. indent, '')))
        j = j + 1
      end
      end_para()
      if #indent == 0 then
        leave_lists()
      end
      add_structure({ kind = 'block', block = 'code', lang = lang, lines = body, lnum = i, last = math.min(j, #lines) })
      i = j
    elseif line:match('^%s*|') then
      local body = {}
      local j = i
      while j <= #lines and lines[j]:match('^%s*|') do
        table.insert(body, vim.trim(lines[j]))
        j = j + 1
      end
      end_para()
      if #indent == 0 then
        leave_lists()
      end
      add_structure({ kind = 'block', block = 'table', lines = body, lnum = i, last = j - 1 })
      i = j - 1
    elseif line:match('^#+%s') and #line:match('^#+') <= 6 then
      local level = #line:match('^#+')
      local text = clean_text(line:gsub('^#+%s+', ''):gsub('%s+#+%s*$', ''))
      end_para()
      leave_lists()
      if #tokens > 0 then
        add_structure({ kind = 'gap', lnum = i })
      end
      add_structure({ kind = 'heading', level = level, text = text, nwords = count_words(text), lnum = i })
      headings[level] = text
      for l = level + 1, 6 do
        headings[l] = nil
      end
      local crumbs = {}
      for l = 1, 6 do
        if headings[l] then
          table.insert(crumbs, headings[l])
        end
      end
      ctx.crumbs = table.concat(crumbs, ' › ')
    elseif line:match('^%s*[-*_]%s*[-*_]%s*[-*_][-*_%s]*$') and not line:match('[^-*_%s]') then
      end_para()
      add_structure({ kind = 'gap', lnum = i })
    elseif blank then
      end_para()
      ctx.quote = false
    else
      local marker, rest = line:match('^%s*([-*+])%s+(.*)$')
      local number
      if not marker then
        number, rest = line:match('^%s*(%d+)[.)]%s+(.*)$')
      end
      local content_start
      if marker or number then
        end_para()
        while #lists > 0 and lists[#lists].indent > #indent do
          table.remove(lists)
        end
        local list = lists[#lists]
        if list and list.indent == #indent and list.ordered == (number ~= nil) then
          list.count = list.count + 1
        else
          if list and list.indent == #indent then
            table.remove(lists)
          end
          list = { indent = #indent, count = 1, ordered = number ~= nil }
          table.insert(lists, list)
        end
        local check, task_rest = rest:match('^%[([ xX])%]%s+(.*)$')
        if check then
          rest = task_rest
        end
        local bullet = check and (check == ' ' and '☐' or '☑') or (number and '') or ({ '•', '◦', '▪' })[(#lists - 1) % 3 + 1]
        ctx.prefix = { bullet = bullet, index = list.count, list = list, depth = #lists }
        content_start = #line - #rest
      elseif line:match('^%s*>') then
        if not ctx.quote then
          end_para()
        end
        if #indent == 0 and prev_blank then
          leave_lists()
        end
        ctx.quote = true
        local quoted = line:match('^[%s>]*')
        content_start = #quoted
        -- Callouts: > [!note] reads as "NOTE:"
        local kind = line:sub(content_start + 1):match('^%[!(%w+)%]')
        if kind then
          line = line:sub(1, content_start) .. kind:upper() .. ':  ' .. line:sub(content_start + #kind + 4)
        end
      else
        if ctx.quote then
          end_para()
          ctx.quote = false
        end
        if #indent == 0 and prev_blank then
          leave_lists()
        end
        content_start = #indent
      end
      add_words(hide(line:sub(1, content_start)) .. line:sub(content_start + 1), i)
    end

    prev_blank = blank
    i = i + 1
  end
  end_para()

  -- Words left from each token on, for the time estimate
  local left = 0
  for j = #tokens, 1, -1 do
    local tok = tokens[j]
    left = left + (tok.kind == 'word' and 1 or tok.nwords or 0)
    tok.words_left = left
  end
  return tokens
end

-- [[ Timing ]]

local function duration(tok)
  local base = 60000 / M.wpm
  if tok.kind == 'gap' then
    return math.floor(base)
  elseif tok.kind == 'heading' then
    return math.floor(base * (2 + 0.6 * tok.nwords))
  end
  local m = 1
  local len = vim.fn.strchars(tok.text)
  if len > 8 then
    m = m + math.min((len - 8) * 0.08, 0.8)
  end
  if tok.code then
    m = m + 0.3
  end
  if tok.text:find('[.!?]["\')%]]*$') then
    m = m + 1
  elseif tok.text:find('[,;:]["\')%]]*$') or tok.text:find('—$') then
    m = m + 0.5
  end
  if tok.para_end then
    m = m + 1
  end
  return math.floor(base * m)
end

-- [[ Rendering ]]

local function dw(s)
  return vim.fn.strdisplaywidth(s)
end

local function wrap(text, width)
  local out, cur = {}, ''
  for w in text:gmatch('%S+') do
    if cur ~= '' and dw(cur .. ' ' .. w) > width then
      table.insert(out, cur)
      cur = w
    else
      cur = cur == '' and w or cur .. ' ' .. w
    end
  end
  if cur ~= '' then
    table.insert(out, cur)
  end
  return out
end

local function truncate(s, width)
  if dw(s) <= width then
    return s
  end
  return vim.fn.strcharpart(s, 0, width - 1) .. '…'
end

local function prefix_text(prefix)
  local count = prefix.index .. '/' .. prefix.list.count
  local text = prefix.bullet == '' and count or prefix.bullet .. ' ' .. count
  return string.rep('  ', prefix.depth - 1) .. text
end

-- Optimal recognition point: the letter the eye lands on (Spritz's rule)
local function focus_index(text)
  local chars = vim.fn.strchars(text)
  local lead = #(text:match('^[%p]*'))
  local letters = chars - lead
  local orp = letters <= 1 and 1 or letters <= 5 and 2 or letters <= 9 and 3 or letters <= 13 and 4 or 5
  return math.min(lead + orp, chars)
end

local keys -- defined after the actions they call, listed by the help page

local function help_lines()
  local out = {}
  for _, key in ipairs(keys) do
    table.insert(out, string.format('%-12s %s', key[2], key[3]))
  end
  return out
end

local function render()
  local tok = state.tokens[state.idx]
  local width = math.max(40, math.min(vim.o.columns - 4, 72))
  local block_lines = state.help and help_lines() or tok.kind == 'block' and tok.lines or nil
  if block_lines then
    for _, l in ipairs(block_lines) do
      width = math.max(width, dw(l) + 4)
    end
    width = math.min(width, vim.o.columns - 4)
  end
  local center = math.floor(width / 2)
  local lines, hls = {}, {}

  local function add(text, group)
    table.insert(lines, text)
    if group then
      table.insert(hls, { #lines - 1, 0, #text, group })
    end
  end

  local crumbs = tok.crumbs ~= '' and tok.crumbs or vim.fn.fnamemodify(state.name, ':t:r')
  add('  ' .. truncate(crumbs, width - 4), 'SpeedReadMuted')

  if block_lines then
    local label = state.help and 'keys'
      or tok.block == 'table' and 'table'
      or ('code' .. (tok.lang ~= '' and ' · ' .. tok.lang or ''))
    add('── ' .. label .. ' ' .. string.rep('─', width - dw(label) - 4), 'SpeedReadGuide')
    local max_lines = state.help and math.huge or math.max(3, vim.o.lines - 12)
    for n, l in ipairs(block_lines) do
      if n > max_lines then
        add(string.format('  … %d more lines', #block_lines - max_lines), 'SpeedReadMuted')
        break
      end
      if state.help then
        add('  ' .. l)
        table.insert(hls, { #lines - 1, 2, 14, 'SpeedReadPrefix' })
      else
        add('  ' .. l, tok.block == 'code' and 'SpeedReadBlock' or (n == 1 and 'SpeedReadBold' or nil))
      end
    end
    add(string.rep('─', width), 'SpeedReadGuide')
  else
    add(string.rep('─', center) .. '┬' .. string.rep('─', width - center - 1), 'SpeedReadGuide')
    if tok.kind == 'heading' then
      for _, l in ipairs(wrap(tok.text, width - 4)) do
        add(string.rep(' ', math.floor((width - dw(l)) / 2)) .. l, 'SpeedReadH' .. math.min(tok.level, 6))
      end
    elseif tok.kind == 'word' then
      local orp = focus_index(tok.text)
      local before = vim.fn.strcharpart(tok.text, 0, orp - 1)
      local focus = vim.fn.strcharpart(tok.text, orp - 1, 1)
      local prefix = tok.prefix and prefix_text(tok.prefix) or ''
      local gap = math.max(1, center - dw(before) - 2 - dw(prefix))
      local line = '  ' .. prefix .. string.rep(' ', gap) .. tok.text
      local row = #lines
      local start = 2 + #prefix + gap
      add(line)
      table.insert(hls, { row, 2, 2 + #prefix, 'SpeedReadPrefix' })
      local base = tok.code and 'SpeedReadCode' or tok.quote and 'SpeedReadQuote' or 'SpeedReadWord'
      table.insert(hls, { row, start, #line, base })
      if tok.bold then
        table.insert(hls, { row, start, #line, 'SpeedReadBold' })
      end
      if tok.italic then
        table.insert(hls, { row, start, #line, 'SpeedReadItalic' })
      end
      table.insert(hls, { row, start + #before, start + #before + #focus, 'SpeedReadFocus' })
    else
      add('')
    end
    add(string.rep('─', center) .. '┴' .. string.rep('─', width - center - 1), 'SpeedReadGuide')
  end

  -- Status: play state, speed, progress, time left
  local icon = state.playing and '▶' or '⏸'
  local left = string.format('%s %d wpm', icon, M.wpm)
  local pct = #state.tokens > 1 and (state.idx - 1) / (#state.tokens - 1) or 1
  local minutes = tok.words_left / M.wpm
  local right = string.format('%3d%%  %s left', math.floor(pct * 100), minutes < 1 and '<1m' or string.format('%dm', minutes))
  local bar_w = math.max(0, width - dw(left) - dw(right) - 8)
  local filled = math.floor(bar_w * pct + 0.5)
  add('  ' .. left .. '  ' .. string.rep('━', filled) .. string.rep('─', bar_w - filled) .. '  ' .. right, 'SpeedReadMuted')

  if not state.playing then
    local hint
    if state.help then
      hint = '? or q close help'
    elseif state.idx == #state.tokens and state.finished then
      hint = 'end of note  gg start  ? help  q quit'
    else
      hint = (tok.kind == 'block' and '␣ next' or '␣ play') .. '  h l word  ( ) sentence  { } para  [ ] heading  ? help'
    end
    hint = truncate(hint, width - 2)
    add(string.rep(' ', math.max(0, math.floor((width - dw(hint)) / 2))) .. hint, 'SpeedReadMuted')
  end

  local buf, win = state.buf, state.win
  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  for n, hl in ipairs(hls) do
    vim.api.nvim_buf_set_extmark(buf, ns, hl[1], hl[2], { end_col = hl[3], hl_group = hl[4], priority = 100 + n })
  end
  vim.api.nvim_win_set_config(win, {
    relative = 'editor',
    width = width,
    height = #lines,
    row = math.floor((vim.o.lines - #lines) / 2) - 1,
    col = math.floor((vim.o.columns - width) / 2),
  })
  vim.api.nvim_win_set_cursor(win, { 1, 0 })
end

-- The source window follows: cursor and highlight on the current token, and
-- the line kept in the top part of the window, clear of the reader
local function sync_source(tok)
  if not vim.api.nvim_win_is_valid(state.src_win) or not vim.api.nvim_buf_is_valid(state.src_buf) then
    return
  end
  vim.api.nvim_buf_clear_namespace(state.src_buf, ns, 0, -1)
  pcall(vim.api.nvim_win_set_cursor, state.src_win, { tok.lnum, tok.col or 0 })
  if tok.kind == 'word' then
    vim.api.nvim_buf_set_extmark(state.src_buf, ns, tok.lnum - 1, tok.col, { end_col = tok.ecol, hl_group = 'SpeedReadCurrent' })
  elseif tok.kind ~= 'gap' then
    pcall(vim.api.nvim_buf_set_extmark, state.src_buf, ns, tok.lnum - 1, 0, { end_row = tok.last, hl_group = 'SpeedReadCurrentBlock', hl_eol = true })
  end
  if tok.lnum ~= state.shown_lnum then
    state.shown_lnum = tok.lnum
    vim.api.nvim_win_call(state.src_win, function()
      vim.fn.winrestview({ topline = math.max(1, tok.lnum - math.floor(vim.api.nvim_win_get_height(0) / 5)) })
    end)
  end
end

-- [[ Playback ]]

local function show()
  if not state then
    return
  end
  state.timer:stop()
  state.help = false -- any key but ? leaves the help page
  local tok = state.tokens[state.idx]
  if tok.kind == 'block' then
    state.playing = false -- blocks wait for <Space>
  end
  render()
  sync_source(tok)
  if not state.playing then
    return
  end
  state.timer:start(
    duration(tok),
    0,
    vim.schedule_wrap(function()
      if not state or not state.playing then
        return
      end
      if state.idx >= #state.tokens then
        state.playing = false
        state.finished = true
        render()
        return
      end
      state.idx = state.idx + 1
      show()
    end)
  )
end

local function jump(idx, step)
  if not idx then
    return
  end
  idx = math.max(1, math.min(idx, #state.tokens))
  -- Gaps are only a beat during playback, never a place to land
  while state.tokens[idx].kind == 'gap' and state.tokens[idx + (step or 1)] do
    idx = idx + (step or 1)
  end
  state.idx = idx
  state.finished = false
  show()
end

local function find(field, step)
  local j = state.idx + step
  while j >= 1 and j <= #state.tokens do
    if state.tokens[j][field] then
      return j
    end
    j = j + step
  end
end

local function toggle()
  if state.playing then
    state.playing = false
    show()
  elseif state.finished then
    return
  else
    state.playing = true
    if state.tokens[state.idx].kind == 'block' then
      if state.idx >= #state.tokens then
        state.playing = false
        state.finished = true
        return render()
      end
      state.idx = state.idx + 1
    end
    show()
  end
end

local function set_speed(delta)
  M.wpm = math.max(100, math.min(1500, M.wpm + delta))
  show()
end

function M.stop()
  if not state then
    return
  end
  local s = state
  state = nil
  s.timer:stop()
  s.timer:close()
  vim.o.guicursor = s.guicursor
  pcall(vim.api.nvim_del_augroup_by_id, s.augroup)
  if vim.api.nvim_buf_is_valid(s.src_buf) then
    vim.api.nvim_buf_clear_namespace(s.src_buf, ns, 0, -1)
  end
  if vim.api.nvim_win_is_valid(s.win) then
    vim.api.nvim_win_close(s.win, true)
  end
  if vim.api.nvim_win_is_valid(s.src_win) then
    vim.api.nvim_set_current_win(s.src_win)
  end
end

local function toggle_help()
  if state.help then
    show()
  else
    state.playing = false
    state.timer:stop()
    state.help = true
    render()
  end
end

local function quit()
  if state.help then
    show()
  else
    M.stop()
  end
end

-- Keys inside the reader: { lhs, label on the help page, description, action }
keys = {
  { { '<Space>', '<CR>' }, 'Space Enter', 'Play / pause, continue past a table or code block', toggle },
  { { 'l' }, 'l', 'Next word', function()
    jump(state.idx + 1, 1)
  end },
  { { 'h' }, 'h', 'Previous word', function()
    jump(state.idx - 1, -1)
  end },
  { { ')' }, ')', 'Next sentence', function()
    jump(find('sentence', 1), 1)
  end },
  { { '(' }, '(', 'Start of the sentence, then the previous one', function()
    jump(find('sentence', -1), -1)
  end },
  { { '}' }, '}', 'Next paragraph or list item', function()
    jump(find('para', 1), 1)
  end },
  { { '{' }, '{', 'Start of the paragraph, then the previous one', function()
    jump(find('para', -1), -1)
  end },
  { { ']' }, ']', 'Next heading', function()
    jump(find('level', 1), 1)
  end },
  { { '[' }, '[', 'Section heading, then the previous one', function()
    jump(find('level', -1), -1)
  end },
  { { 'gg' }, 'gg', 'Start of the note', function()
    jump(1, 1)
  end },
  { { 'G' }, 'G', 'End of the note', function()
    jump(#state.tokens, -1)
  end },
  { { '+', '=' }, '+', 'Faster (' .. M.wpm_step .. ' wpm)', function()
    set_speed(M.wpm_step)
  end },
  { { '-' }, '-', 'Slower (' .. M.wpm_step .. ' wpm)', function()
    set_speed(-M.wpm_step)
  end },
  { { '?' }, '?', 'This help', toggle_help },
  { { 'q', '<Esc>' }, 'q Esc', 'Quit, the cursor stays on the last word read', quit },
}

function M.start()
  M.stop()
  set_highlights()

  local src_win = vim.api.nvim_get_current_win()
  local src_buf = vim.api.nvim_get_current_buf()
  local tokens = parse(vim.api.nvim_buf_get_lines(src_buf, 0, -1, false))
  if #tokens == 0 then
    vim.notify('Nothing to read', vim.log.levels.WARN)
    return
  end

  -- Start at the first token at or after the cursor
  local cursor = vim.api.nvim_win_get_cursor(src_win)
  local start = 1
  for j, tok in ipairs(tokens) do
    if tok.last > cursor[1] or (tok.last == cursor[1] and (tok.ecol == nil or tok.ecol > cursor[2])) then
      start = j
      break
    end
  end

  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = 'wipe'
  local win = vim.api.nvim_open_win(buf, true, {
    relative = 'editor',
    width = 40,
    height = 1,
    row = 1,
    col = 1,
    style = 'minimal',
    border = 'rounded',
    title = ' Speed read ',
    title_pos = 'center',
  })
  vim.wo[win].wrap = false

  state = {
    tokens = tokens,
    idx = start,
    playing = false,
    finished = false,
    buf = buf,
    win = win,
    src_win = src_win,
    src_buf = src_buf,
    name = vim.api.nvim_buf_get_name(src_buf),
    timer = vim.uv.new_timer(),
    guicursor = vim.o.guicursor,
    augroup = vim.api.nvim_create_augroup('speedread', { clear = true }),
  }

  -- Hide the cursor while the reader has focus; pause when it loses it
  local hidden = 'a:SpeedReadHiddenCursor'
  vim.o.guicursor = hidden
  vim.api.nvim_create_autocmd('WinEnter', {
    group = state.augroup,
    buffer = buf,
    callback = function()
      vim.o.guicursor = hidden
    end,
  })
  vim.api.nvim_create_autocmd('WinLeave', {
    group = state.augroup,
    buffer = buf,
    callback = function()
      if not state then
        return
      end
      vim.o.guicursor = state.guicursor
      if state.playing then
        state.playing = false
        show()
      end
    end,
  })
  vim.api.nvim_create_autocmd('WinClosed', {
    group = state.augroup,
    pattern = tostring(win),
    callback = function()
      vim.schedule(M.stop)
    end,
  })
  vim.api.nvim_create_autocmd('VimResized', {
    group = state.augroup,
    callback = function()
      if state then
        render()
      end
    end,
  })

  for _, key in ipairs(keys) do
    for _, lhs in ipairs(key[1]) do
      vim.keymap.set('n', lhs, key[4], { buffer = buf, nowait = true, desc = key[3] })
    end
  end

  jump(start, 1)
end

M._parse = parse -- for testing

return M
