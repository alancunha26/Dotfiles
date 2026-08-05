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
    routes = {
      {
        filter = {
          -- When multiple LSP attached to a buffer
          -- multiple notifications may be triggered
          -- See: https://github.com/neovim/nvim-lspconfig/issues/1931#issuecomment-2138428768
          event = 'notify',
          find = 'No information available',
        },
        opts = {
          skip = true,
        },
      },
      {
        filter = {
          -- Disable deprecation messages
          event = 'msg_show',
          find = 'is deprecated',
        },
        opts = {
          skip = true,
        },
      },
      {
        filter = {
          -- Godot's LSP can't parse the client's reply to its own
          -- workspace/applyEdit request (sent e.g. when connecting a
          -- signal) and answers it with a bogus "Method not found" error,
          -- surfaced by nvim as this harmless notification.
          -- See: https://github.com/godotengine/godot/issues/105544
          event = 'notify',
          find = 'NO_RESULT_CALLBACK_FOUND',
        },
        opts = {
          skip = true,
        },
      },
    },
  },
}
