-- Shared mini.nvim version
local version = '*'

return {
  -- [[ Text editing ]]
  {
    'echasnovski/mini.ai',
    version = version,
    config = true,
  },
  {
    'echasnovski/mini.move',
    version = version,
    config = true,
  },
  {
    'echasnovski/mini.pairs',
    version = version,
    config = true,
  },
  {
    'echasnovski/mini.surround',
    version = version,
    config = true,
  },
  {
    'echasnovski/mini.splitjoin',
    version = version,
    opts = { n_lines = 500 },
  },
  {
    'echasnovski/mini.operators',
    version = version,
  },
  {
    'echasnovski/mini.snippets',
    event = 'InsertEnter',
    dependencies = 'rafamadriz/friendly-snippets',
    opts = function(_, opts)
      local mini_snippets = require('mini.snippets')
      local config_path = vim.fn.stdpath('config')

      opts.snippets = {
        mini_snippets.gen_loader.from_file(config_path .. '/snippets/global.json'),
        mini_snippets.gen_loader.from_lang(),
      }

      opts.expand = {
        select = function(snippets, insert)
          ---@diagnostic disable-next-line: undefined-global
          local select = expand_select_override or MiniSnippets.default_select
          select(snippets, insert)
        end,
      }

      opts.mappings = {
        expand = '<C-j>',
        jump_next = '<C-l>',
        jump_prev = '<C-h>',
        stop = '<Esc>',
      }

      return opts
    end,
  },

  -- [[ Appearance ]]
  {
    'echasnovski/mini.icons',
    version = version,
    config = true,
  },
  {
    'echasnovski/mini.trailspace',
    event = 'BufReadPost',
    version = version,
    config = true,
    keys = {
      { '<leader>gt', '<cmd>lua MiniTrailspace.trim()<cr>', desc = 'Trim trailing whitespace' },
    },
  },
  {
    'echasnovski/mini.bracketed',
    version = version,
    config = true,
  },
  {
    'echasnovski/mini.hipatterns',
    version = version,
    config = function()
      local hipatterns = require('mini.hipatterns')
      -- local hipatterns_extras = require('modules.mini.hipatterns')

      hipatterns.setup({
        highlighters = {
          fixme = { pattern = '%f[%w]()FIXME()%f[%W]', group = 'MiniHipatternsFixme' },
          hack = { pattern = '%f[%w]()HACK()%f[%W]', group = 'MiniHipatternsHack' },
          todo = { pattern = '%f[%w]()TODO()%f[%W]', group = 'MiniHipatternsTodo' },
          note = { pattern = '%f[%w]()NOTE()%f[%W]', group = 'MiniHipatternsNote' },

          -- hex_color = hipatterns.gen_highlighter.hex_color(),
          -- hex_color_short = hipatterns_extras.hex_color_short(),
          -- hsl_color = hipatterns_extras.hsl_color(),
          -- rgb_color = hipatterns_extras.rgb_color(),
          -- rgba_color = hipatterns_extras.rgba_color(),
        },
      })
    end,
  },

  -- [[ Workflow ]]
  {
    'echasnovski/mini.jump',
    version = version,
    config = true,
  },
  {
    'echasnovski/mini-git',
    version = version,
  },
  {
    'echasnovski/mini.diff',
    version = version,
    opts = {
      view = {
        style = 'sign',
        -- signs = { add = '+', change = '~', delete = '_' },
        signs = { add = '┃', change = '┃', delete = '_' },
        priority = 199,
      },
    },
  },
  {
    'echasnovski/mini.files',
    version = version,
    lazy = false,
    opts = {
      options = {
        permanent_delete = false,
        use_as_default_explorer = true,
      },
    },
    config = function(_, opts)
      require('mini.files').setup(opts)
      require('modules.mini/files-git')
    end,
    keys = {
      {
        '<leader>ee',
        function()
          local buf_name = vim.api.nvim_buf_get_name(0)
          local path = vim.fn.filereadable(buf_name) == 1 and buf_name or vim.fn.getcwd()
          MiniFiles.open(path)
          MiniFiles.reveal_cwd()
        end,
        desc = 'File explorer',
      },
      {
        '<leader>eE',
        function()
          MiniFiles.open(vim.uv.cwd(), true)
        end,
        desc = 'File explorer (cwd)',
      },
    },
  },
  {
    'echasnovski/mini.sessions',
    version = version,
    opts = {
      autoread = false,
      autowrite = true,
      directory = vim.fn.stdpath('data') .. '/sessions',
    },
    keys = {
      {
        '<leader>gS',
        function()
          MiniSessions.select()
        end,
        desc = 'Select session',
      },
      {
        '<leader>gs',
        function()
          local cwd = vim.fn.getcwd()
          local session_name = cwd:gsub('/', '_'):gsub('^_', '')
          MiniSessions.write(session_name)
          vim.notify('Session saved: ' .. session_name, vim.log.levels.INFO)
        end,
        desc = 'Save session (cwd)',
      },
    },
  },
  -- Replaces with lualine
  -- {
  --   'echasnovski/mini.statusline',
  --   version = version,
  --   opts = { use_icons = vim.g.have_nerd_font },
  --   config = function(_, opts)
  --     local statusline = require('mini.statusline')
  --     statusline.setup(opts)
  --
  --     ---@diagnostic disable-next-line: duplicate-set-field
  --     statusline.section_location = function()
  --       return '%2l:%-2v'
  --     end
  --   end,
  -- },
}
