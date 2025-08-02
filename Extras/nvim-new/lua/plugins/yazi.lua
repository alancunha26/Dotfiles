return {
  'mikavilpas/yazi.nvim',
  event = 'VeryLazy',
  dependencies = {
    { 'nvim-lua/plenary.nvim', lazy = true },
  },
  keys = {
    {
      '<leader>e',
      '<cmd>Yazi<cr>',
      desc = 'File explorer',
    },
    {
      '<leader>yc',
      mode = { 'n', 'v' },
      '<cmd>Yazi<cr>',
      desc = 'Open yazi at the current file',
    },
    {
      '<leader>yr',
      '<cmd>Yazi cwd<cr>',
      desc = "Open the yazi in nvim's working directory",
    },
    {
      '<leader>ye',
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
  -- 👇 if you use `open_for_directories=true`, this is recommended
  init = function()
    -- More details: https://github.com/mikavilpas/yazi.nvim/issues/802
    -- vim.g.loaded_netrw = 1
    -- vim.g.loaded_netrwPlugin = 1
  end,

  -- NOTE: Wating for kitty image protcol support
  enabled = false,
}
