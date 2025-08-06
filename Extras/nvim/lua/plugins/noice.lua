return {
  'folke/noice.nvim',
  event = 'VeryLazy',
  dependencies = { 'MunifTanjim/nui.nvim' },
  opts = {
    -- lsp = {
    --   signature = { enabled = false },
    -- },
    notify = {
      enabled = true,
    },
    presets = {
      lsp_doc_border = true,
      command_palette = true,
      long_message_to_split = true,
    },
    views = {
      cmdline_popup = {
        position = {
          row = '50%',
          col = '50%',
        },
      },
    },
  },
}
