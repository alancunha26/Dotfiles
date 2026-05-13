local M = {}

--- Override zk-nvim's snacks note picker to display the note id alongside
--- the title, so notes that share a title can be disambiguated.
function M.setup()
  local picker_mod = require('zk.pickers.snacks_picker')
  local snacks_picker = require('snacks.picker')

  picker_mod.show_note_picker = function(notes, opts, cb)
    opts = opts or {}

    local items = vim.tbl_map(function(note)
      local title = note.title or note.path
      local id = vim.fn.fnamemodify(note.path, ':t:r')
      return {
        text = title .. ' ' .. id,
        title = title,
        id = id,
        file = note.absPath,
        value = note,
      }
    end, notes)

    local picker_opts = vim.tbl_deep_extend('force', {
      items = items,
      format = function(item)
        local ret = {}
        local icon, icon_hl = Snacks.util.icon(item.file, 'file')
        ret[#ret + 1] = { icon .. ' ', icon_hl }
        ret[#ret + 1] = { item.title, 'SnacksPickerFile' }
        ret[#ret + 1] = { ' (' .. item.id .. ')', 'SnacksPickerDir' }
        return ret
      end,
      sort = { fields = { 'score:desc', 'idx' } },
      confirm = function(picker, item)
        picker:close()
        if not opts.multi_select then
          cb(item.value)
        else
          cb(vim.tbl_map(function(i)
            return i.value
          end, picker:selected({ fallback = true })))
        end
      end,
    }, opts.snacks_picker or {})

    snacks_picker.pick(opts.title, picker_opts)
  end
end

return M
