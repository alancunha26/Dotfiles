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

local function get_inbox_path()
  local inbox_path = notes_path .. '/inbox.md'

  -- Create inbox file if it doesn't exist
  if vim.fn.filereadable(inbox_path) == 0 then
    local date = os.date('%Y-%m-%d')
    local frontmatter = {
      '---',
      'title: Inbox',
      'date: ' .. date,
      'tags: []',
      '---',
      '',
      '# Inbox',
      '',
    }
    vim.fn.writefile(frontmatter, inbox_path)
  end

  return inbox_path
end

function M.quick_capture()
  local inbox_path = get_inbox_path()

  vim.ui.input({ prompt = 'Capture: ' }, function(input)
    if input and input ~= '' then
      local timestamp = os.date('%Y-%m-%d %H:%M')
      local entry = string.format('- [%s] %s', timestamp, input)

      local file = io.open(inbox_path, 'a')
      if file then
        file:write(entry .. '\n')
        file:close()
        vim.notify('Captured to inbox', vim.log.levels.INFO)
      end
    end
  end)
end

function M.open_inbox()
  vim.cmd('edit ' .. get_inbox_path())
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
      format = grep_format_with_titles(collection),
    })
  end)
end

function M.headings()
  build_title_collection(function(collection)
    -- Run rg to get all headings
    local cmd = { 'rg', '--line-number', '--no-heading', '--color=never', '^#{1,6} ', '-g', '*.md' }
    local output = vim.fn.systemlist(cmd)

    local items = {}
    for _, line in ipairs(output) do
      local file, lnum, content = line:match('^([^:]+):(%d+):(.*)$')
      if file and lnum and content then
        local heading = content:gsub('^#+ ', '')
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

        -- Add heading indent (virtual)
        local indent = string.rep('  ', item.level - 1)
        if #indent > 0 then
          ret[#ret + 1] = { indent, nil, virtual = true }
        end

        -- Heading text gets match highlighting
        ret[#ret + 1] = { item.heading }

        return ret
      end,
    })
  end)
end

-- ============================================================================
-- Task Management
-- ============================================================================

local function get_tasks_path()
  local tasks_path = notes_path .. '/tasks.md'

  if vim.fn.filereadable(tasks_path) == 0 then
    local date = os.date('%Y-%m-%d')
    local content = {
      '---',
      'title: Tasks',
      'date: ' .. date,
      'tags: []',
      '---',
      '',
      '# Tasks',
      '',
      '## Do Now',
      '',
      '## Do Later',
      '',
      '## Do Someday',
      '',
    }
    vim.fn.writefile(content, tasks_path)
  end

  return tasks_path
end

local function get_done_path()
  local done_path = notes_path .. '/done.md'

  if vim.fn.filereadable(done_path) == 0 then
    local date = os.date('%Y-%m-%d')
    local content = {
      '---',
      'title: Done',
      'date: ' .. date,
      'tags: []',
      '---',
      '',
      '# Done',
      '',
      '## Tasks',
      '',
    }
    vim.fn.writefile(content, done_path)
  end

  return done_path
end

function M.open_tasks()
  vim.cmd('edit ' .. get_tasks_path())
end

function M.capture_task()
  local tasks_path = get_tasks_path()
  local sections = { 'Do Now', 'Do Later', 'Do Someday' }

  Snacks.picker({
    title = 'Add Task To',
    items = vim.tbl_map(function(s)
      return { text = s, section = s }
    end, sections),
    layout = { preset = 'vscode' },
    format = function(item)
      return { { item.text } }
    end,
    confirm = function(picker, item)
      picker:close()

      vim.schedule(function()
        vim.ui.input({ prompt = 'Task: ' }, function(task)
          vim.schedule(function()
            vim.cmd('stopinsert')
          end)

          if not task or task == '' then
            return
          end

          task = vim.fn.trim(task)
          local lines = vim.fn.readfile(tasks_path)
          local section_header = '## ' .. item.section
          local inserted = false

          for i, line in ipairs(lines) do
            if line == section_header then
              local insert_pos = i + 1
              -- Skip empty line after header if present
              if lines[insert_pos] == '' then
                insert_pos = insert_pos + 1
              end

              -- Insert the task
              table.insert(lines, insert_pos, '- [ ] ' .. task)

              -- Ensure empty line before next heading
              if lines[insert_pos + 1] and lines[insert_pos + 1]:match('^#') then
                table.insert(lines, insert_pos + 1, '')
              end

              inserted = true
              break
            end
          end

          if inserted then
            vim.fn.writefile(lines, tasks_path)
            vim.notify('Task added to ' .. item.section, vim.log.levels.INFO)
          else
            vim.notify('Section not found: ' .. item.section, vim.log.levels.ERROR)
          end
        end)
      end)
    end,
  })
end

function M.complete_task()
  local line = vim.api.nvim_get_current_line()
  local lnum = vim.api.nvim_win_get_cursor(0)[1]

  local task_text
  local is_incomplete = line:match('^%s*%- %[ %]')
  local is_complete = line:match('^%s*%- %[x%]')

  if is_incomplete then
    task_text = line:gsub('^%s*%- %[ %] ', '')
  elseif is_complete then
    task_text = line:gsub('^%s*%- %[x%] ', '')
  else
    vim.notify('Not on a task line', vim.log.levels.WARN)
    return
  end
  local date = os.date('%Y-%m-%d')
  local done_entry = '- [x] ' .. task_text .. ' (' .. date .. ')'

  -- Remove from current file
  vim.api.nvim_buf_set_lines(0, lnum - 1, lnum, false, {})

  -- Add to done.md (at the top, after the ## Tasks header)
  local done_path = get_done_path()
  local done_lines = vim.fn.readfile(done_path)

  -- Find the "## Tasks" header and insert after it
  for i, l in ipairs(done_lines) do
    if l:match('^## Tasks') then
      -- Insert after header, skip empty line if present
      local insert_pos = i + 1
      if done_lines[insert_pos] == '' then
        insert_pos = insert_pos + 1
      end
      table.insert(done_lines, insert_pos, done_entry)
      break
    end
  end

  vim.fn.writefile(done_lines, done_path)
  vim.notify('Task completed!', vim.log.levels.INFO)
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

function M.find_tasks()
  local tasks_path = get_tasks_path()
  local lines = vim.fn.readfile(tasks_path)

  local items = {}
  local current_section = nil

  for i, line in ipairs(lines) do
    -- Track current section
    local section = line:match('^## (.+)$')
    if section then
      current_section = section
    end

    -- Collect tasks
    if line:match('^%- %[ %]') and current_section then
      local task_text = line:gsub('^%- %[ %] ', '')
      table.insert(items, {
        text = current_section .. ' ' .. task_text,
        file = tasks_path,
        pos = { i, 0 },
        section = current_section,
        task = task_text,
      })
    end
  end

  Snacks.picker({
    title = 'Tasks',
    items = items,
    format = function(item, picker)
      local ret = {}

      -- Section badge
      local section_hl = 'SnacksPickerDir'
      if item.section == 'Do Now' then
        section_hl = 'DiagnosticError'
      elseif item.section == 'Do Later' then
        section_hl = 'DiagnosticWarn'
      end

      ret[#ret + 1] = { '[' .. item.section .. ']', section_hl, virtual = true }
      ret[#ret + 1] = { ' ', virtual = true }
      ret[#ret + 1] = { item.task }

      return ret
    end,
  })
end

return M
