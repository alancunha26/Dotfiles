return {
  'mikavilpas/yazi.nvim',
  event = 'VeryLazy',
  dependencies = {
    { 'nvim-lua/plenary.nvim', lazy = true },
  },
  keys = {
    {
      '<leader>ee',
      '<cmd>Yazi<cr>',
      desc = 'File explorer',
    },
    {
      '<leader>ec',
      mode = { 'n', 'v' },
      '<cmd>Yazi<cr>',
      desc = 'Open yazi at the current file',
    },
    {
      '<leader>eE',
      '<cmd>Yazi cwd<cr>',
      desc = "Open the yazi in nvim's working directory",
    },
    {
      '<leader>ey',
      '<cmd>Yazi toggle<cr>',
      desc = 'Open yazi last session',
    },
  },
  opts = {
    -- if you want to open yazi instead of netrw, see below for more info
    open_for_directories = false,
    keymaps = {
      show_help = '<f1>',
    },
  },

  -- NOTE: Wating for kitty image protcol support
  enabled = false,
}
