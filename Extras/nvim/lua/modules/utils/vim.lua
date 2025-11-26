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
  local cursor = vim.fn.getpos('.')
  local visual = vim.fn.getpos('v')

  -- Determine which position is the start and which is the end
  local start_pos, end_pos
  if cursor[2] < visual[2] or (cursor[2] == visual[2] and cursor[3] < visual[3]) then
    start_pos = cursor
    end_pos = visual
  else
    start_pos = visual
    end_pos = cursor
  end

  -- LSP uses 0-based indexing for both lines and characters
  -- LSP ranges are exclusive at the end, so we don't subtract 1 from end character
  return {
    uri = 'file://' .. vim.fn.expand('%:p'),
    range = {
      start = {
        line = start_pos[2] - 1,
        character = start_pos[3] - 1,
      },
      ['end'] = {
        line = end_pos[2] - 1,
        character = end_pos[3],
      },
    },
  }
end

return M
