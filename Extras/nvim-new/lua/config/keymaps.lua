-- [[ General Keymaps ]]
--  See `:help vim.keymap.set()`

-- Exit insert mode
vim.keymap.set('i', 'jk', '<Esc>')

-- Clear highlights on search when pressing <Esc> in normal mode
--  See `:help hlsearch`
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

-- Diagnostic keymaps
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })

-- Keybinds to make split navigation easier.
--  Use CTRL+<hjkl> to switch between windows
vim.keymap.set('n', '<C-h>', '<C-w><C-h>', { desc = 'Move focus to the left window' })
vim.keymap.set('n', '<C-l>', '<C-w><C-l>', { desc = 'Move focus to the right window' })
vim.keymap.set('n', '<C-j>', '<C-w><C-j>', { desc = 'Move focus to the lower window' })
vim.keymap.set('n', '<C-k>', '<C-w><C-k>', { desc = 'Move focus to the upper window' })
vim.keymap.set('n', '<C-s>', '<cmd>split<CR>', { desc = 'Split window vertically' })
vim.keymap.set('n', '<C-i>', '<cmd>vsplit<CR>', { desc = 'Split window horizontally' })
vim.keymap.set('n', '<C-q>', '<cmd>close<CR>', { desc = 'Close selected window' })
vim.keymap.set('n', 'zZ', 'zszH', { desc = 'Center this line (horizontal)' })

-- Beter gx -> Open files with vim.ui.open relative to the current buffer
vim.keymap.set('n', 'gx', function()
  local filename = vim.fn.expand('<cfile>%:t')
  local buffer_dir = vim.fn.expand('%:h')

  if not string.match(filename, '[a-z]*://[^ >,;]*') then
    vim.ui.open(buffer_dir .. '/' .. filename)
  else
    vim.ui.open(filename)
  end
end, { desc = '[X] Open url/file relative to current buffer' })

-- [[ Spellcheck ]]
--  See `:help spell`

-- Toggle spell check
vim.keymap.set('n', '<leader>st', function()
  -- Native spellcheck
  -- vim.opt.spell = not (vim.opt.spell:get())

  -- ltex grammar/spellcheck
  local buf_clients = vim.lsp.get_clients({ bufnr = 0 })

  for _, client in pairs(buf_clients) do
    if client.name == 'ltex' then
      client.stop(client, true)
      return
    end
  end

  vim.cmd('LspStart ltex')
end, { desc = 'Toggle spellcheck' })

-- Show spelling suggestions / spell suggestions.
-- NOTE: Overridden by telescope builtin.spell_suggest
vim.keymap.set('n', '<leader>ss', function()
  vim.cmd('normal! z=')
end, { desc = 'Spellcheck suggestions' })

-- Fix spelling with first suggestion
vim.keymap.set('n', '<leader>sf', function()
  vim.cmd('normal! 1z=')
end, { desc = 'Fix spelling with first suggestion' })

-- Add word under the cursor as a good word
vim.keymap.set('n', '<leader>sa', function()
  vim.cmd('normal! zg')
end, { desc = 'Add word to spellcheck' })

-- Undo zw, remove the word from the entry in 'spellfile'.
vim.keymap.set('n', '<leader>sd', function()
  vim.cmd('normal! zug')
end, { desc = 'Delete word from spellcheck' })

-- Repeat the replacement done by |z=| for all matches with the replaced word
-- in the current window.
vim.keymap.set('n', '<leader>sr', function()
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(':spellr\n', true, false, true), 'm', true)
end, { desc = 'Repeat spellcheck for all matches' })

-- Inspect diagnostic
vim.keymap.set('n', 'D', function()
  vim.diagnostic.open_float()
end)
