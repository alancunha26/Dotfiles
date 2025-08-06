return {
  'saghen/blink.cmp',
  --- @module 'blink.cmp'
  --- @type blink.cmp.Config
  opts = {
    keymap = {
      preset = 'default',
    },

    appearance = {
      nerd_font_variant = 'mono',
    },

    completion = {
      menu = {
        border = 'rounded',
        scrollbar = false,

        cmdline_position = function()
          if vim.g.ui_cmdline_pos ~= nil then
            local pos = vim.g.ui_cmdline_pos
            return { pos[1], pos[2] - 3 }
          end
          local height = (vim.o.cmdheight == 0) and 1 or vim.o.cmdheight
          return { vim.o.lines - height, 0 }
        end,

        draw = {
          treesitter = {
            'lsp',
          },
          columns = {
            { 'label', 'label_description' },
            { 'kind_icon', 'kind', gap = 1 },
          },
          components = {
            kind_icon = {
              text = function(ctx)
                local kind_icon, _, _ = require('mini.icons').get('lsp', ctx.kind)
                return kind_icon
              end,
              -- (optional) use highlights from mini.icons
              highlight = function(ctx)
                local _, hl, _ = require('mini.icons').get('lsp', ctx.kind)
                return hl
              end,
            },
            kind = {
              -- (optional) use highlights from mini.icons
              highlight = function(ctx)
                local _, hl, _ = require('mini.icons').get('lsp', ctx.kind)
                return hl
              end,
            },
          },
        },
      },
      ghost_text = {
        enabled = true,
      },
      documentation = {
        auto_show = true,
        auto_show_delay_ms = 500,
        window = { border = 'rounded' },
      },
    },

    -- Conflicts with Noice signatures
    -- signature = {
    --   enabled = true,
    --   window = {
    --     border = 'none',
    --     show_documentation = false,
    --   },
    -- },

    sources = {
      default = { 'lsp', 'path', 'snippets', 'buffer' },
    },

    snippets = {
      preset = 'mini_snippets',
    },

    fuzzy = {
      implementation = 'lua',
    },

    cmdline = {
      keymap = { preset = 'inherit' },
      completion = {
        menu = {
          auto_show = true,
        },
      },
    },
  },
}
