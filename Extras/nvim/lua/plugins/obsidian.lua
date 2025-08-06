return {
  'obsidian-nvim/obsidian.nvim',
  enabled = false,
  version = '*',
  ft = 'markdown',
  ---@module 'obsidian'
  ---@type obsidian.config
  opts = {
    legacy_commands = false,
    preferred_link_style = 'markdown',

    -- Optional, customize how markdown links are formatted.
    markdown_link_func = function(opts)
      return require('obsidian.util').markdown_link(opts)
    end,

    workspaces = {
      {
        name = 'personal',
        path = '~/.repos/github.com/alancunha26/notes/',
      },
    },

    completion = {
      blink = true,
      nvim_cmp = false,
      min_chars = 0,
    },
  },
}
