local M = {}

function M.get_visual_selection()
  local vstart = vim.fn.getpos('.')
  local vend = vim.fn.getpos('v')

  local region = vim.fn.getregion(vstart, vend, {
    mode = vim.fn.mode(),
  })

  return table.concat(region)
end

function M.get_selection_lsp_location()
  local vstart = vim.fn.getpos('.')
  local vend = vim.fn.getpos('v')

  return {
    uri = 'file://' .. vim.fn.expand('%:p'),
    range = {
      start = {
        line = vstart[2] - 1,
        character = vstart[3],
      },
      ['end'] = {
        line = vend[2] - 1,
        character = vend[3] - 1,
      },
    },
  }
end

return M
