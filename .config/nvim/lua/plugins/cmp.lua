return {
  { -- Autocompletion
    'hrsh7th/nvim-cmp',
    event = 'InsertEnter',
    dependencies = {
      -- Snippet Engine & its associated nvim-cmp source
      {
        'L3MON4D3/LuaSnip',
        build = (function()
          -- Build Step is needed for regex support in snippets.
          -- This step is not supported in many windows environments.
          -- Remove the below condition to re-enable on windows.
          -- if vim.fn.has('win32') == 1 or vim.fn.executable('make') == 0 then
          --   return
          -- end
          return 'make install_jsregexp'
        end)(),
        dependencies = {
          -- `friendly-snippets` contains a variety of premade snippets.
          --    See the README about individual language/framework/plugin snippets:
          --    https://github.com/rafamadriz/friendly-snippets
          -- {
          --   'rafamadriz/friendly-snippets',
          --   config = function()
          --     require('luasnip.loaders.from_vscode').lazy_load()
          --   end,
          -- },
        },
      },
      'saadparwaiz1/cmp_luasnip',

      -- Adds other completion capabilities.
      --  nvim-cmp does not ship with all sources by default. They are split
      --  into multiple repos for maintenance purposes.
      'hrsh7th/cmp-nvim-lsp',
      'hrsh7th/cmp-buffer',
      'hrsh7th/cmp-path',

      -- Adds tailwind configuration
      'tailwind-tools',
      'onsails/lspkind-nvim',
    },
    config = function()
      local cmp = require('cmp')
      local types = require('cmp.types')
      local compare = require('cmp.config.compare')
      local luasnip = require('luasnip')
      luasnip.config.setup()

      ---@type table<integer, integer>
      local modified_priority = {
        [types.lsp.CompletionItemKind.Variable] = types.lsp.CompletionItemKind.Method,
        [types.lsp.CompletionItemKind.Property] = 0, -- top
        [types.lsp.CompletionItemKind.Snippet] = 0, -- top
        [types.lsp.CompletionItemKind.Keyword] = 0, -- top
        [types.lsp.CompletionItemKind.Text] = 300, -- bottom
      }
      ---@param kind integer: kind of completion entry
      local function modified_kind(kind)
        return modified_priority[kind] or kind
      end

      cmp.setup({
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        completion = {
          completeopt = 'menu,menuone,noinsert',
        },
        formatting = {
          format = require('lspkind').cmp_format({
            before = require('tailwind-tools.cmp').lspkind_format,
          }),
        },

        sorting = {
          priority_weight = 2,
          -- https://github.com/hrsh7th/nvim-cmp/blob/main/lua/cmp/config/compare.lua
          comparators = {
            compare.offset,
            compare.exact,
            -- function(entry1, entry2) -- sort by length ignoring "=~"
            --   local len1 = string.len(string.gsub(entry1.completion_item.label, '[=~()_]', ''))
            --   local len2 = string.len(string.gsub(entry2.completion_item.label, '[=~()_]', ''))
            --   if len1 ~= len2 then
            --     return len1 - len2 < 0
            --   end
            -- end,
            compare.recently_used,
            function(entry1, entry2) -- sort by compare kind (Variable, Function etc)
              local kind1 = modified_kind(entry1:get_kind())
              local kind2 = modified_kind(entry2:get_kind())
              if kind1 ~= kind2 then
                return kind1 - kind2 < 0
              end
            end,
            function(entry1, entry2) -- score by lsp, if available
              local t1 = entry1.completion_item.sortText
              local t2 = entry2.completion_item.sortText
              if t1 ~= nil and t2 ~= nil and t1 ~= t2 then
                return t1 < t2
              end
            end,
            compare.score,
            compare.order,
          },
        },

        -- For an understanding of why these mappings were
        -- chosen, you will need to read `:help ins-completion`
        --
        -- No, but seriously. Please read `:help ins-completion`, it is really good!
        mapping = cmp.mapping.preset.insert({
          -- Select the [n]ext item
          ['<C-n>'] = cmp.mapping.select_next_item(),
          -- Select the [p]revious item
          ['<C-p>'] = cmp.mapping.select_prev_item(),

          -- Scroll the documentation window [b]ack / [f]orward \ [d]own / [u]p
          ['<C-u>'] = cmp.mapping.scroll_docs(-4),
          ['<C-d>'] = cmp.mapping.scroll_docs(4),

          -- Accept ([y]es) the completion.
          --  This will auto-import if your LSP supports it.
          --  This will expand snippets if the LSP sent a snippet.
          ['<C-y>'] = cmp.mapping.confirm({ select = true }),

          -- If you prefer more traditional completion keymaps,
          -- you can uncomment the following lines
          -- ['<CR>'] = cmp.mapping.confirm { select = true },
          --['<Tab>'] = cmp.mapping.select_next_item(),
          --['<S-Tab>'] = cmp.mapping.select_prev_item(),

          -- Manually trigger a completion from nvim-cmp.
          --  Generally you don't need this, because nvim-cmp will display
          --  completions whenever it has completion options available.
          ['<C-Space>'] = cmp.mapping.complete({}),

          -- Think of <c-l> as moving to the right of your snippet expansion.
          --  So if you have a snippet that's like:
          --  function $name($args)
          --    $body
          --  end
          --
          -- <c-l> will move you to the right of each of the expansion locations.
          -- <c-h> is similar, except moving you backwards.
          ['<C-l>'] = cmp.mapping(function()
            if luasnip.expand_or_locally_jumpable() then
              luasnip.expand_or_jump()
            end
          end, { 'i', 's' }),
          ['<C-h>'] = cmp.mapping(function()
            if luasnip.locally_jumpable(-1) then
              luasnip.jump(-1)
            end
          end, { 'i', 's' }),

          -- For more advanced Luasnip keymaps (e.g. selecting choice nodes, expansion) see:
          --    https://github.com/L3MON4D3/LuaSnip?tab=readme-ov-file#keymaps
        }),
        sources = {
          { name = 'lazydev', group_index = 0 },
          { name = 'nvim_lsp', priority = 100 },
          { name = 'luasnip' },
          { name = 'buffer' },
          { name = 'path' },
        },
      })
    end,
  },
}
-- vim: ts=2 sts=2 sw=2 et
