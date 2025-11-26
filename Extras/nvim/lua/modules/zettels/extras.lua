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

function M.grep()
  -- Build a collection of file paths -> titles using zk API
  local collection = {}
  local list_opts = { select = { 'title', 'path', 'absPath' } }

  require('zk.api').list(nil, list_opts, function(_, notes)
    if notes then
      for _, note in ipairs(notes) do
        collection[note.absPath] = note.title or note.path
      end
    end

    -- Open grep picker with custom format that shows titles
    Snacks.picker.grep({
      format = function(item, picker)
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

        -- Add line content with match highlighting (simple, no treesitter)
        if item.line then
          local offset = Snacks.picker.highlight.offset(ret)

          if item.positions then
            Snacks.picker.highlight.matches(ret, item.positions, offset)
          end

          ret[#ret + 1] = { item.line }
        end

        return ret
      end,
    })
  end)
end

return M
