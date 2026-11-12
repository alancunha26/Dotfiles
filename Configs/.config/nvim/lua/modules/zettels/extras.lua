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
-- Capture
-- ============================================================================

local desktop_path = notes_path .. '/vro8.md'
local desktop_section = 'Tasks'

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
  if not lines[insert_pos]:match('^[%-*%s]') then
    insert_pos = insert_pos + 1
    table.insert(lines, insert_pos, '')
  end
  insert_lines(lines, insert_pos + 1, new_lines)
  vim.fn.writefile(lines, filepath)
  return true
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

function M.capture()
  if vim.fn.filereadable(desktop_path) == 0 then
    vim.notify('This vault has no Desktop to capture into', vim.log.levels.WARN)
    return
  end

  vim.ui.input({ prompt = 'Task: ' }, function(text)
    vim.schedule(function()
      vim.cmd('stopinsert')
    end)

    if not text or text == '' then
      return
    end

    if append_to_section(desktop_path, desktop_section, '- [ ] ' .. vim.fn.trim(text)) then
      reload_buffer_if_open(desktop_path)
      vim.notify('Captured to The Desktop', vim.log.levels.INFO)
    else
      vim.notify('No "' .. desktop_section .. '" section in The Desktop', vim.log.levels.ERROR)
    end
  end)
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

return M
