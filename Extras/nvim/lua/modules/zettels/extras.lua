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

-- TODO: fix new zettels from template in visual mode
function M.new_zettel_from_template()
  Snacks.picker.files({
    dirs = { '.zk/templates' },
    title = 'Templates',
    confirm = function(picker, item)
      picker:close()
      local template = vim.fn.fnamemodify(item.file, ':p')
      M.new_zettel({ template = template })
    end,
  })
end

-- TODO: implementation
function M.insert_template()
  print('hello')
end

function M.mentions()
  local mention = vim.fn.expand('%:t')

  if mention == nil then
    vim.notify("There's no buffer currently open", vim.log.levels.INFO)
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
      .iter(pairs(notes))
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

return M
