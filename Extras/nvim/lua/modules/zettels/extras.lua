local vim_utils = require('modules.utils.vim')
local config = require('modules.zettels.config')
local notes_path = vim.fn.expand(config.notes_path)

local M = {}

function M.suid()
  local command = 'suid -l 4 -d "$HOME/.local/assets/alphanum-lower.json"'
  local handle = io.popen(command)

  if handle == nil then
    return
  end

  local result = handle:read('*a')
  handle:close()

  if result == nil then
    return
  end

  return vim.fn.trim(result)
end

function M.new_zettel(opts)
  opts = opts or {}
  opts.template = opts.template or nil

  if vim.fn.mode():match('^[vV\x16]$') then
    local title = vim_utils.get_visual_selection()
    local location = vim_utils.get_selection_lsp_location()

    if location.range.start.line == location.range['end'].line then
      require('zk').new({
        title = title,
        template = opts.template,
        insertLinkAtLocation = location,
        dir = notes_path,
      })
    end

    return
  end

  vim.ui.input({ prompt = 'Title' }, function(title)
    if title ~= nil then
      require('zk').new({
        title = title,
        template = opts.template,
        dir = notes_path,
      })
    end
  end)
end

function M.new_zettel_from_template()
  local is_visual = vim.fn.mode():match('^[vV\x16]$')
  local title, location

  if is_visual then
    title = vim_utils.get_visual_selection()
    location = vim_utils.get_selection_lsp_location()

    -- Only proceed if selection is on a single line
    if location.range.start.line ~= location.range['end'].line then
      vim.notify('Selection must be on a single line', vim.log.levels.WARN)
      return
    end
  end

  Snacks.picker.files({
    dirs = { '.zk/templates' },
    title = 'Templates',
    confirm = function(picker, item)
      picker:close()
      local template = vim.fn.fnamemodify(item.file, ':p')

      if is_visual then
        require('zk').new({
          title = title,
          template = template,
          insertLinkAtLocation = location,
          dir = notes_path,
        })
      else
        M.new_zettel({ template = template })
      end
    end,
  })
end

function M.insert_template()
  Snacks.picker.files({
    dirs = { '.zk/templates' },
    title = 'Templates',
    confirm = function(picker, item)
      picker:close()
      local template_path = vim.fn.fnamemodify(item.file, ':p')

      -- Read template content
      local template_lines = vim.fn.readfile(template_path)
      if not template_lines or #template_lines == 0 then
        vim.notify('Template is empty', vim.log.levels.WARN)
        return
      end

      -- Get current position
      local cursor_pos = vim.fn.getcurpos()
      local line = cursor_pos[2]
      local col = cursor_pos[3]

      -- Check if in visual mode
      if vim.fn.mode():match('^[vV\x16]$') then
        -- Delete visual selection and insert template
        vim.cmd('normal! d')
        vim.api.nvim_put(template_lines, 'c', true, true)
      else
        -- Insert template at cursor position
        vim.api.nvim_buf_set_text(0, line - 1, col - 1, line - 1, col - 1, template_lines)
      end
    end,
  })
end

function M.mentions()
  local mention = vim.fn.expand('%:t')

  if mention == nil or mention == '' then
    vim.notify("There's no buffer currently open", vim.log.levels.INFO)
    return
  end

  local options = {
    linkTo = { mention },
    select = { 'path' },
  }

  require('zk.api').list(nil, options, function(err, notes)
    if err ~= nil then
      vim.notify(err, vim.log.levels.ERROR)
      return
    end

    local paths = vim
      .iter(ipairs(notes))
      :map(function(_, note)
        return note.path
      end)
      :totable()

    require('zk').pick_notes({ mention = { mention }, excludeHrefs = paths }, nil, function(selected)
      if selected[1] ~= nil then
        vim.cmd('edit ' .. selected[1].absPath)
      end
    end)
  end)
end

function M.open_index()
  vim.cmd('edit ' .. notes_path .. '/index.md')
end

--- Given an array of lines and a 1-indexed start of a task line, return the
--- end index that includes the bullet line plus any continuation lines
--- (indented non-bullet, non-empty lines). Single-line tasks return start == end.
local function get_task_range(lines, start_idx)
  local end_idx = start_idx
  local i = start_idx + 1
  while i <= #lines do
    local line = lines[i]
    if line and line:match('^%s+%S') and not line:match('^%s*[%-*]%s') then
      end_idx = i
      i = i + 1
    else
      break
    end
  end
  return start_idx, end_idx
end

--- Find the most recent daily note before `today` (YYYY-MM-DD), or nil if none.
local function find_prev_daily(today)
  local files = vim.fn.glob(notes_path .. '/[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9].md', false, true)
  table.sort(files, function(a, b)
    return a > b
  end)
  for _, file in ipairs(files) do
    local d = file:match('(%d%d%d%d%-%d%d%-%d%d)%.md$')
    if d and d < today then
      return file
    end
  end
  return nil
end

--- Extract unchecked goals (with continuations) from the previous daily note's
--- `## Goals` section AND mark each bullet line as strikethrough in place.
--- Goals that are empty placeholders (`- [ ]` with no content) or already
--- struck through (`~~...~~`) are skipped.
--- Returns a list of tasks; each task is a list of lines (bullet + any
--- continuation lines) preserving the original, non-struck content.
local function extract_and_strike_goals(filepath)
  local lines = vim.fn.readfile(filepath)
  local tasks = {}
  local in_goals = false
  local modified = false
  local i = 1
  while i <= #lines do
    local line = lines[i]
    if line:match('^##%s+Goals%s*$') then
      in_goals = true
      i = i + 1
    elseif in_goals and line:match('^##%s+') then
      in_goals = false
      i = i + 1
    elseif in_goals then
      local prefix, content = line:match('^(%- %[ %]%s+)(.+)$')
      if prefix and content and not content:match('^~~') then
        local _, end_idx = get_task_range(lines, i)
        local task = {}
        for k = i, end_idx do
          table.insert(task, lines[k])
        end
        table.insert(tasks, task)
        lines[i] = prefix .. '~~' .. content .. '~~'
        for k = i + 1, end_idx do
          local indent, cont = lines[k]:match('^(%s+)(.+)$')
          if indent and cont and not cont:match('^~~') then
            lines[k] = indent .. '~~' .. cont .. '~~'
          end
        end
        modified = true
        i = end_idx + 1
      else
        i = i + 1
      end
    else
      i = i + 1
    end
  end
  if modified then
    vim.fn.writefile(lines, filepath)
  end
  return tasks
end

--- Replace the empty `- [ ]` placeholder in today's `## Goals` section with
--- the carried-over tasks (each task is a list of lines).
local function carry_over_goals(filepath, tasks)
  if #tasks == 0 then
    return
  end
  local lines = vim.fn.readfile(filepath)
  local new_lines = {}
  local in_goals = false
  local replaced = false
  for _, line in ipairs(lines) do
    if line:match('^##%s+Goals%s*$') then
      in_goals = true
      table.insert(new_lines, line)
    elseif in_goals and not replaced and line:match('^%- %[ %]%s*$') then
      for _, task in ipairs(tasks) do
        for _, l in ipairs(task) do
          table.insert(new_lines, l)
        end
      end
      replaced = true
    elseif in_goals and line:match('^##%s+') then
      in_goals = false
      table.insert(new_lines, line)
    else
      table.insert(new_lines, line)
    end
  end
  vim.fn.writefile(new_lines, filepath)
end

--- Ensure today's daily note exists. Creates it via `zk new --group daily` and
--- runs goal carryover (from the most recent prior daily) on first creation.
--- Returns the path, or nil on failure.
local function ensure_daily_note()
  local date = os.date('%Y-%m-%d')
  local daily_path = notes_path .. '/' .. date .. '.md'

  if vim.fn.filereadable(daily_path) == 1 then
    return daily_path
  end

  local result = vim
    .system({ 'zk', 'new', '--group', 'daily', '--print-path', '--no-input', notes_path }, { text = true })
    :wait()

  if result.code ~= 0 then
    vim.notify('Failed to create daily note: ' .. (result.stderr or ''), vim.log.levels.ERROR)
    return nil
  end

  local prev = find_prev_daily(date)
  if prev then
    local carried = extract_and_strike_goals(prev)
    if #carried > 0 then
      carry_over_goals(daily_path, carried)
      local prev_date = vim.fn.fnamemodify(prev, ':t:r')
      vim.notify(string.format('Carried %d goal(s) from %s', #carried, prev_date), vim.log.levels.INFO)
    end
  end

  return daily_path
end

function M.open_daily()
  local daily_path = ensure_daily_note()
  if daily_path then
    vim.cmd('edit ' .. daily_path)
  end
end

function M.buffers()
  -- Get only loaded buffers
  local buffers = vim.api.nvim_list_bufs()
  local paths = {}

  for _, buf in ipairs(buffers) do
    -- Only include loaded buffers
    if vim.api.nvim_buf_is_loaded(buf) then
      local path = vim.api.nvim_buf_get_name(buf)
      if path ~= '' then
        table.insert(paths, path)
      end
    end
  end

  require('zk').edit({ hrefs = paths }, { title = 'Zk Buffers' })
end

-- Helper to build note title collection
local function build_title_collection(callback)
  local collection = {}
  local list_opts = { select = { 'title', 'path', 'absPath' } }

  require('zk.api').list(nil, list_opts, function(_, notes)
    if notes then
      for _, note in ipairs(notes) do
        collection[note.absPath] = note.title or note.path
      end
    end
    callback(collection)
  end)
end

-- Custom format function for grep results with titles
local function grep_format_with_titles(collection)
  return function(item, picker)
    local ret = {}

    if not item.file then
      return ret
    end

    -- Get title and filename
    local abs_path = vim.fn.fnamemodify(item.file, ':p')
    local title = collection[abs_path]
    local filename = vim.fn.fnamemodify(item.file, ':t')

    -- Add icon
    local icon, icon_hl = Snacks.util.icon(item.file, 'file')
    ret[#ret + 1] = { icon .. ' ', icon_hl }

    -- Add title (or filename if no title)
    if title then
      ret[#ret + 1] = { title, 'SnacksPickerFile' }
      ret[#ret + 1] = { ' (' .. filename .. ')', 'SnacksPickerDir' }
    else
      ret[#ret + 1] = { filename, 'SnacksPickerFile' }
    end

    -- Add line number
    if item.pos and item.pos[1] > 0 then
      ret[#ret + 1] = { ':' .. item.pos[1], 'SnacksPickerPos' }
    end

    ret[#ret + 1] = { ' ' }

    -- Add line content with match highlighting
    if item.line then
      local offset = Snacks.picker.highlight.offset(ret)

      if item.positions then
        Snacks.picker.highlight.matches(ret, item.positions, offset)
      end

      ret[#ret + 1] = { item.line }
    end

    return ret
  end
end

function M.grep()
  build_title_collection(function(collection)
    Snacks.picker.grep({
      dirs = { notes_path },
      format = grep_format_with_titles(collection),
    })
  end)
end

function M.headings()
  build_title_collection(function(collection)
    -- Run rg to get all headings
    local cmd = { 'rg', '--line-number', '--no-heading', '--color=never', '^#{1,6} ', '-g', '*.md', notes_path }
    local output = vim.fn.systemlist(cmd)

    local items = {}
    for _, line in ipairs(output) do
      local file, lnum, content = line:match('^([^:]+):(%d+):(.*)$')
      if file and lnum and content then
        local heading = vim.fn.trim((content:gsub('^#+ ', '')))
        local abs_path = vim.fn.fnamemodify(file, ':p')
        local title = collection[abs_path]
        local filename = vim.fn.fnamemodify(file, ':t')
        local level = #(content:match('^#+') or '')

        table.insert(items, {
          text = heading, -- Only match on heading text
          file = file,
          pos = { tonumber(lnum), 0 },
          heading = heading,
          level = level,
          title = title or filename,
          filename = filename,
        })
      end
    end

    Snacks.picker({
      title = 'Zk Headings',
      items = items,
      format = function(item, picker)
        local ret = {}

        -- Add icon (virtual = no match highlighting)
        local icon, icon_hl = Snacks.util.icon(item.file, 'file')
        ret[#ret + 1] = { icon .. ' ', icon_hl, virtual = true }

        -- Add title (virtual = no match highlighting)
        ret[#ret + 1] = { item.title, 'SnacksPickerFile', virtual = true }
        if item.title ~= item.filename then
          ret[#ret + 1] = { ' (' .. item.filename .. ')', 'SnacksPickerDir', virtual = true }
        end

        ret[#ret + 1] = { ' ', virtual = true }

        -- Add heading level indicator (virtual)
        local level_hl = '@markup.heading.' .. item.level .. '.markdown'
        ret[#ret + 1] = { 'H' .. item.level .. ' ', level_hl, virtual = true }

        -- Heading text gets match highlighting
        ret[#ret + 1] = { item.heading }

        return ret
      end,
    })
  end)
end

-- ============================================================================
-- Backlog & Capture
-- ============================================================================

local function get_backlog_path()
  local backlog_path = notes_path .. '/backlog.md'

  if vim.fn.filereadable(backlog_path) == 0 then
    local date = os.date('%Y-%m-%d')
    local content = {
      '---',
      'title: Backlog',
      'date: ' .. date,
      'tags: []',
      '---',
      '',
      '# Backlog',
      '',
      "Long-horizon items I want to remember but haven't committed to. When I",
      "intend to actually do one, I move it to today's Journal Goals.",
      '',
    }
    vim.fn.writefile(content, backlog_path)
  end

  return backlog_path
end

--- Normalize a value to an array of lines.
local function as_lines(value)
  if type(value) == 'string' then
    return { value }
  end
  return value
end

--- Insert each line of `new_lines` (in order) starting at position `pos`.
local function insert_lines(target, pos, new_lines)
  for k = #new_lines, 1, -1 do
    table.insert(target, pos, new_lines[k])
  end
end

--- Append lines to the backlog file (after the last non-blank line).
local function append_to_backlog_file(new_lines)
  new_lines = as_lines(new_lines)
  local backlog_path = get_backlog_path()
  local lines = vim.fn.readfile(backlog_path)
  local insert_pos = #lines
  while insert_pos > 0 and lines[insert_pos]:match('^%s*$') do
    insert_pos = insert_pos - 1
  end
  insert_lines(lines, insert_pos + 1, new_lines)
  vim.fn.writefile(lines, backlog_path)
end

--- Append lines to the named `## section` in a markdown file.
--- If the section contains an empty `- [ ]` placeholder, replace it with the
--- new lines. Otherwise insert after the last non-blank line in the section.
--- Returns true on success.
local function append_to_section(filepath, section_name, new_lines)
  new_lines = as_lines(new_lines)
  local lines = vim.fn.readfile(filepath)
  local section_header = '## ' .. section_name
  local section_start = nil
  local next_section_idx = nil

  for i, line in ipairs(lines) do
    if line == section_header then
      section_start = i
    elseif section_start and line:match('^##%s+') then
      next_section_idx = i
      break
    end
  end

  if not section_start then
    return false
  end

  local section_end = next_section_idx and (next_section_idx - 1) or #lines

  for i = section_start + 1, section_end do
    if lines[i] and lines[i]:match('^%- %[ %]%s*$') then
      table.remove(lines, i)
      insert_lines(lines, i, new_lines)
      vim.fn.writefile(lines, filepath)
      return true
    end
  end

  local insert_pos = section_end
  while insert_pos > section_start and (lines[insert_pos] == nil or lines[insert_pos]:match('^%s*$')) do
    insert_pos = insert_pos - 1
  end
  insert_lines(lines, insert_pos + 1, new_lines)
  vim.fn.writefile(lines, filepath)
  return true
end

--- Find the start index of a task whose lines exactly match `task_lines`,
--- preferring `expected_idx`. Returns nil if no match.
local function find_task_at(file_lines, task_lines, expected_idx)
  local function matches_at(start)
    for k = 1, #task_lines do
      if file_lines[start + k - 1] ~= task_lines[k] then
        return false
      end
    end
    return true
  end

  if expected_idx and matches_at(expected_idx) then
    return expected_idx
  end
  for k = 1, #file_lines - #task_lines + 1 do
    if matches_at(k) then
      return k
    end
  end
  return nil
end

--- Reload the buffer for `filepath` from disk if it's currently loaded.
local function reload_buffer_if_open(filepath)
  local bufnr = vim.fn.bufnr(filepath)
  if bufnr ~= -1 and vim.api.nvim_buf_is_loaded(bufnr) then
    vim.api.nvim_buf_call(bufnr, function()
      vim.cmd('checktime')
    end)
  end
end

function M.open_backlog()
  vim.cmd('edit ' .. get_backlog_path())
end

--- Capture a new task. Picks destination (today's Goals or backlog), prompts
--- for text, appends to the chosen target.
function M.capture()
  local destinations = {
    { text = "Today's Goals", target = 'today' },
    { text = 'Backlog', target = 'backlog' },
  }

  Snacks.picker({
    title = 'Capture To',
    items = destinations,
    layout = { preset = 'vscode' },
    format = function(item)
      return { { item.text } }
    end,
    confirm = function(picker, item)
      picker:close()

      vim.schedule(function()
        vim.ui.input({ prompt = 'Task: ' }, function(text)
          vim.schedule(function()
            vim.cmd('stopinsert')
          end)

          if not text or text == '' then
            return
          end

          text = vim.fn.trim(text)
          local task_line = '- [ ] ' .. text

          if item.target == 'today' then
            local daily_path = ensure_daily_note()
            if not daily_path then
              return
            end
            if append_to_section(daily_path, 'Goals', task_line) then
              reload_buffer_if_open(daily_path)
              vim.notify("Captured to today's Goals", vim.log.levels.INFO)
            end
          else
            append_to_backlog_file(task_line)
            reload_buffer_if_open(get_backlog_path())
            vim.notify('Captured to backlog', vim.log.levels.INFO)
          end
        end)
      end)
    end,
  })
end

--- True if the current buffer is `backlog.md`.
local function in_backlog()
  return vim.fn.expand('%:t') == 'backlog.md'
end

--- True if the current buffer is today's daily note.
local function in_today_daily()
  return vim.fn.expand('%:t') == os.date('%Y-%m-%d') .. '.md'
end

--- Move a known backlog task (already removed from source) into today's Goals.
local function commit_pull(task_lines)
  task_lines = as_lines(task_lines)
  local daily_path = ensure_daily_note()
  if daily_path then
    append_to_section(daily_path, 'Goals', task_lines)
    reload_buffer_if_open(daily_path)
    vim.notify('Pulled to today: ' .. task_lines[1]:gsub('^%- %[ %]%s+', ''), vim.log.levels.INFO)
  end
end

--- Pull a backlog item into today's Goals. If the cursor is on a `- [ ]` line
--- in `backlog.md`, that task (including continuation lines) is pulled
--- directly. Otherwise shows a picker of backlog items.
function M.pull_from_backlog()
  local backlog_path = get_backlog_path()

  if in_backlog() then
    local bufnr = vim.api.nvim_get_current_buf()
    local lnum = vim.api.nvim_win_get_cursor(0)[1]
    local cursor_line = vim.api.nvim_buf_get_lines(bufnr, lnum - 1, lnum, false)[1] or ''

    if cursor_line:match('^%- %[ %]%s*%S') then
      local buf_lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
      local _, end_idx = get_task_range(buf_lines, lnum)
      local task_lines = vim.api.nvim_buf_get_lines(bufnr, lnum - 1, end_idx, false)

      vim.api.nvim_buf_set_lines(bufnr, lnum - 1, end_idx, false, {})
      vim.api.nvim_buf_call(bufnr, function()
        vim.cmd('silent write')
      end)
      commit_pull(task_lines)
      return
    end
  end

  local lines = vim.fn.readfile(backlog_path)
  local tasks_by_id = {}
  local items = {}
  local i = 1
  while i <= #lines do
    if lines[i]:match('^%- %[ %]%s*%S') then
      local _, end_idx = get_task_range(lines, i)
      local task_lines = {}
      for k = i, end_idx do
        table.insert(task_lines, lines[k])
      end
      tasks_by_id[i] = { lnum = i, task_lines = task_lines }
      table.insert(items, {
        text = task_lines[1]:gsub('^%- %[ %]%s+', ''),
        task_id = i,
      })
      i = end_idx + 1
    else
      i = i + 1
    end
  end

  if #items == 0 then
    vim.notify('Backlog is empty', vim.log.levels.WARN)
    return
  end

  Snacks.picker({
    title = 'Pull to Today',
    items = items,
    layout = { preset = 'vscode' },
    format = function(item)
      return { { item.text } }
    end,
    confirm = function(picker, item)
      picker:close()

      vim.schedule(function()
        local data = tasks_by_id[item.task_id]
        if not data then
          vim.notify('Lost task data', vim.log.levels.ERROR)
          return
        end

        local cur_lines = vim.fn.readfile(backlog_path)
        local found = find_task_at(cur_lines, data.task_lines, data.lnum)
        if not found then
          vim.notify('Could not find backlog task to remove', vim.log.levels.ERROR)
          return
        end

        for _ = 1, #data.task_lines do
          table.remove(cur_lines, found)
        end
        vim.fn.writefile(cur_lines, backlog_path)
        reload_buffer_if_open(backlog_path)
        commit_pull(data.task_lines)
      end)
    end,
  })
end

--- Push a task to the backlog. If the cursor is on a `- [ ]` line in a file
--- other than the backlog itself, that task (including continuation lines) is
--- pushed directly. Otherwise shows a picker of today's Goals.
function M.push_to_backlog()
  local cursor_line = vim.api.nvim_get_current_line()

  if not in_backlog() and cursor_line:match('^%- %[ %]') then
    local bufnr = vim.api.nvim_get_current_buf()
    local lnum = vim.api.nvim_win_get_cursor(0)[1]
    local buf_lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    local _, end_idx = get_task_range(buf_lines, lnum)
    local task_lines = vim.api.nvim_buf_get_lines(bufnr, lnum - 1, end_idx, false)

    vim.api.nvim_buf_set_lines(bufnr, lnum - 1, end_idx, false, {})
    if vim.api.nvim_buf_get_name(bufnr) ~= '' then
      vim.api.nvim_buf_call(bufnr, function()
        vim.cmd('silent write')
      end)
    end
    append_to_backlog_file(task_lines)
    reload_buffer_if_open(get_backlog_path())
    vim.notify('Pushed to backlog', vim.log.levels.INFO)
    return
  end

  local daily_path = ensure_daily_note()
  if not daily_path then
    return
  end

  local daily_lines = vim.fn.readfile(daily_path)
  local tasks_by_id = {}
  local items = {}
  local in_goals = false
  local i = 1
  while i <= #daily_lines do
    local l = daily_lines[i]
    if l:match('^##%s+Goals%s*$') then
      in_goals = true
      i = i + 1
    elseif in_goals and l:match('^##%s+') then
      break
    elseif in_goals and l:match('^%- %[ %]%s*%S') and not l:match('~~') then
      local _, end_idx = get_task_range(daily_lines, i)
      local task_lines = {}
      for k = i, end_idx do
        table.insert(task_lines, daily_lines[k])
      end
      tasks_by_id[i] = { lnum = i, task_lines = task_lines }
      table.insert(items, {
        text = task_lines[1]:gsub('^%- %[ %]%s+', ''),
        task_id = i,
      })
      i = end_idx + 1
    else
      i = i + 1
    end
  end

  if #items == 0 then
    vim.notify("No goals in today's note to push", vim.log.levels.WARN)
    return
  end

  Snacks.picker({
    title = 'Push to Backlog',
    items = items,
    layout = { preset = 'vscode' },
    format = function(item)
      return { { item.text } }
    end,
    confirm = function(picker, item)
      picker:close()
      vim.schedule(function()
        local data = tasks_by_id[item.task_id]
        if not data then
          vim.notify('Lost task data', vim.log.levels.ERROR)
          return
        end

        local cur_lines = vim.fn.readfile(daily_path)
        local found = find_task_at(cur_lines, data.task_lines, data.lnum)
        if not found then
          vim.notify('Could not find goal to remove', vim.log.levels.ERROR)
          return
        end

        for _ = 1, #data.task_lines do
          table.remove(cur_lines, found)
        end
        vim.fn.writefile(cur_lines, daily_path)
        reload_buffer_if_open(daily_path)

        append_to_backlog_file(data.task_lines)
        reload_buffer_if_open(get_backlog_path())
        vim.notify('Pushed to backlog', vim.log.levels.INFO)
      end)
    end,
  })
end

function M.toggle_task()
  local line = vim.api.nvim_get_current_line()
  local lnum = vim.api.nvim_win_get_cursor(0)[1]

  local new_line
  if line:match('^%s*%- %[ %]') then
    new_line = line:gsub('%- %[ %]', '- [x]', 1)
  elseif line:match('^%s*%- %[x%]') then
    new_line = line:gsub('%- %[x%]', '- [ ]', 1)
  else
    vim.notify('Not on a task line', vim.log.levels.WARN)
    return
  end

  vim.api.nvim_buf_set_lines(0, lnum - 1, lnum, false, { new_line })
end

local function plain_replace(s, old, new)
  local parts = {}
  local i = 1
  while i <= #s do
    local j = s:find(old, i, true)
    if j then
      parts[#parts + 1] = s:sub(i, j - 1)
      parts[#parts + 1] = new
      i = j + #old
    else
      parts[#parts + 1] = s:sub(i)
      break
    end
  end
  return table.concat(parts)
end

function M.rename_note()
  local bufnr = vim.api.nvim_get_current_buf()
  local filepath = vim.api.nvim_buf_get_name(bufnr)

  if filepath == '' then
    vim.notify('No file open', vim.log.levels.WARN)
    return
  end

  local filename = vim.fn.fnamemodify(filepath, ':t')
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

  if lines[1] ~= '---' then
    vim.notify('No frontmatter found', vim.log.levels.WARN)
    return
  end

  local old_title, title_lnum
  for i = 2, #lines do
    if lines[i] == '---' then
      break
    end
    local t = lines[i]:match('^title:%s*(.+)$')
    if t then
      old_title = vim.fn.trim(t)
      title_lnum = i
      break
    end
  end

  if not old_title then
    vim.notify('No title in frontmatter', vim.log.levels.WARN)
    return
  end

  vim.ui.input({ prompt = 'New title: ', default = old_title }, function(new_title)
    if not new_title or new_title == '' or new_title == old_title then
      return
    end

    vim.api.nvim_buf_set_lines(bufnr, title_lnum - 1, title_lnum, false, { 'title: ' .. new_title })
    vim.api.nvim_buf_call(bufnr, function()
      vim.cmd('silent write')
    end)

    local old_link = '[' .. old_title .. '](' .. filename .. ')'
    local new_link = '[' .. new_title .. '](' .. filename .. ')'
    local md_files = vim.fn.glob(notes_path .. '/**/*.md', false, true)
    local updated = 0

    for _, file in ipairs(md_files) do
      local file_lines = vim.fn.readfile(file)
      local changed = false

      for i, line in ipairs(file_lines) do
        if line:find(old_link, 1, true) then
          file_lines[i] = plain_replace(line, old_link, new_link)
          changed = true
        end
      end

      if changed then
        vim.fn.writefile(file_lines, file)
        reload_buffer_if_open(file)
        updated = updated + 1
      end
    end

    reload_buffer_if_open(filepath)
    vim.notify(
      string.format('Renamed "%s" → "%s" (%d file(s) updated)', old_title, new_title, updated),
      vim.log.levels.INFO
    )
  end)
end

function M.find_backlog()
  local backlog_path = get_backlog_path()
  local lines = vim.fn.readfile(backlog_path)

  local items = {}
  for i, line in ipairs(lines) do
    if line:match('^%- %[ %]') then
      local task_text = line:gsub('^%- %[ %] ', '')
      table.insert(items, {
        text = task_text,
        file = backlog_path,
        pos = { i, 0 },
        task = task_text,
      })
    end
  end

  Snacks.picker({
    title = 'Backlog',
    items = items,
    format = function(item, picker)
      return { { item.task } }
    end,
  })
end

return M
