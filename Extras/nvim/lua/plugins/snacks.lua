---@module 'snacks'
return {
  'folke/snacks.nvim',
  priority = 1000,
  lazy = false,

  ---@type snacks.Config
  opts = {
    -- Disabled
    explorer = { enabled = false },

    -- Enabled
    dashboard = {
      enabled = true,
      preset = {
        keys = function()
          local in_zk = vim.fn.isdirectory(vim.fn.getcwd() .. '/.zk') == 1

          if in_zk then
            return {
              {
                icon = ' ',
                key = 'f',
                desc = 'Find Notes',
                action = function()
                  require('zk').edit(nil, { title = 'Zk Notes' })
                end,
              },
              {
                icon = ' ',
                key = 'n',
                desc = 'New Note',
                action = function()
                  require('modules.zettels.extras').new_zettel()
                end,
              },
              {
                icon = ' ',
                key = 'g',
                desc = 'Grep Notes',
                action = function()
                  require('modules.zettels.extras').grep()
                end,
              },
              {
                icon = ' ',
                key = 'r',
                desc = 'Recent Notes',
                action = function()
                  Snacks.picker.recent()
                end,
              },
              {
                icon = ' ',
                key = 't',
                desc = 'Find Tags',
                action = function()
                  require('zk').pick_tags(nil, { title = 'Zk Tags' })
                end,
              },
              {
                icon = ' ',
                key = 'z',
                desc = 'Open Index',
                action = function()
                  require('modules.zettels.extras').open_index()
                end,
              },
              { icon = '󰒲 ', key = 'L', desc = 'Lazy', action = ':Lazy', enabled = package.loaded.lazy ~= nil },
              { icon = ' ', key = 'q', desc = 'Quit', action = ':qa' },
            }
          else
            return {
              {
                icon = ' ',
                key = 'f',
                desc = 'Find File',
                action = function()
                  Snacks.dashboard.pick('files')
                end,
              },
              { icon = ' ', key = 'n', desc = 'New File', action = ':ene | startinsert' },
              {
                icon = ' ',
                key = 'g',
                desc = 'Find Text',
                action = function()
                  Snacks.dashboard.pick('live_grep')
                end,
              },
              {
                icon = ' ',
                key = 'r',
                desc = 'Recent Files',
                action = function()
                  Snacks.dashboard.pick('oldfiles')
                end,
              },
              {
                icon = ' ',
                key = 'c',
                desc = 'Config',
                action = function()
                  Snacks.dashboard.pick('files', { cwd = vim.fn.stdpath('config') })
                end,
              },
              { icon = '󰒲 ', key = 'L', desc = 'Lazy', action = ':Lazy', enabled = package.loaded.lazy ~= nil },
              { icon = ' ', key = 'q', desc = 'Quit', action = ':qa' },
            }
          end
        end,
      },
    },
    animate = { enabled = true },
    quickfile = { enabled = true },
    bigfile = { enabled = true },
    scroll = { enabled = true },
    image = { enabled = true },
    words = { enabled = true },
    indent = { enabled = true },

    statuscolumn = {
      enabled = true,
      folds = {
        open = true,
        git_hl = true,
      },
    },

    zen = {
      enabled = true,
      toggles = { dim = false },
    },

    input = {
      enabled = true,
      icon = ' ',
    },

    lazygit = {
      enabled = true,
      configure = false,
    },

    notifier = {
      enabled = true,
      style = 'fancy',
    },

    picker = {
      enabled = true,
      layout = {
        preset = 'ivy_split',
      },

      matcher = {
        smartcase = false, -- disable smartcase so highlighting is always case-insensitive
      },

      formatters = {
        file = {
          filename_first = true,
          truncate = math.huge,
        },
      },

      win = {
        input = {
          keys = {
            -- Defaults
            ['/'] = 'toggle_focus',
            ['<C-Down>'] = { 'history_forward', mode = { 'i', 'n' } },
            ['<C-Up>'] = { 'history_back', mode = { 'i', 'n' } },
            ['<C-c>'] = { 'cancel', mode = 'i' },
            ['<C-w>'] = { '<c-s-w>', mode = { 'i' }, expr = true, desc = 'delete word' },
            ['<CR>'] = { 'confirm', mode = { 'n', 'i' } },
            ['<Down>'] = { 'list_down', mode = { 'i', 'n' } },
            ['<S-CR>'] = { { 'pick_win', 'jump' }, mode = { 'n', 'i' } },
            ['<S-Tab>'] = { 'select_and_prev', mode = { 'i', 'n' } },
            ['<Tab>'] = { 'select_and_next', mode = { 'i', 'n' } },
            ['<Up>'] = { 'list_up', mode = { 'i', 'n' } },
            ['<a-d>'] = { 'inspect', mode = { 'n', 'i' } },
            ['<a-f>'] = { 'toggle_follow', mode = { 'i', 'n' } },
            ['<a-h>'] = { 'toggle_hidden', mode = { 'i', 'n' } },
            ['<a-i>'] = { 'toggle_ignored', mode = { 'i', 'n' } },
            ['<a-m>'] = { 'toggle_maximize', mode = { 'i', 'n' } },
            ['<a-p>'] = { 'toggle_preview', mode = { 'i', 'n' } },
            ['<a-w>'] = { 'cycle_win', mode = { 'i', 'n' } },
            ['<c-a>'] = { 'select_all', mode = { 'n', 'i' } },
            ['<c-b>'] = { 'preview_scroll_up', mode = { 'i', 'n' } },
            ['<c-d>'] = { 'list_scroll_down', mode = { 'i', 'n' } },
            ['<c-f>'] = { 'preview_scroll_down', mode = { 'i', 'n' } },
            ['<c-g>'] = { 'toggle_live', mode = { 'i', 'n' } },
            ['<c-j>'] = { 'list_down', mode = { 'i', 'n' } },
            ['<c-k>'] = { 'list_up', mode = { 'i', 'n' } },
            ['<c-n>'] = { 'list_down', mode = { 'i', 'n' } },
            ['<c-p>'] = { 'list_up', mode = { 'i', 'n' } },
            ['<c-q>'] = { 'qflist', mode = { 'i', 'n' } },
            ['<c-s>'] = { 'edit_split', mode = { 'i', 'n' } },
            ['<c-t>'] = { 'tab', mode = { 'n', 'i' } },
            ['<c-u>'] = { 'list_scroll_up', mode = { 'i', 'n' } },
            ['<c-v>'] = { 'edit_vsplit', mode = { 'i', 'n' } },
            ['<c-r>#'] = { 'insert_alt', mode = 'i' },
            ['<c-r>%'] = { 'insert_filename', mode = 'i' },
            ['<c-r><c-a>'] = { 'insert_cWORD', mode = 'i' },
            ['<c-r><c-f>'] = { 'insert_file', mode = 'i' },
            ['<c-r><c-l>'] = { 'insert_line', mode = 'i' },
            ['<c-r><c-p>'] = { 'insert_file_full', mode = 'i' },
            ['<c-r><c-w>'] = { 'insert_cword', mode = 'i' },
            ['<c-w>H'] = 'layout_left',
            ['<c-w>J'] = 'layout_bottom',
            ['<c-w>K'] = 'layout_top',
            ['<c-w>L'] = 'layout_right',
            ['?'] = 'toggle_help_input',
            ['G'] = 'list_bottom',
            ['gg'] = 'list_top',
            ['j'] = 'list_down',
            ['k'] = 'list_up',
            ['q'] = 'close',

            -- Extras
            ['<Esc>'] = { 'close', mode = { 'n', 'i' } },
            ['<C-q>'] = { 'close', mode = { 'n', 'i' } },
          },
        },
      },
    },

    styles = {
      input = {
        row = function()
          local editor_height = vim.o.lines
          return (editor_height / 2) - 2
        end,
      },
    },
  },
  keys = {
    --stylua: ignore start
    -- General remaps
    {
      '<Esc>',
      function()
        vim.cmd('nohlsearch')
        Snacks.notifier.hide()
      end,
    },

    -- Top Pickers & Explorer
    { '<leader><space>', function() Snacks.picker.smart() end, desc = 'Smart find files' },

    -- find
    { '<leader>f?', function() Snacks.picker.help() end, desc = 'Find help pages' },
    { '<leader>f:', function() Snacks.picker.command_history() end, desc = 'Find in command history' },
    { '<leader>f!', function() Snacks.picker.commands() end, desc = 'Find commands' },
    { '<leader>fb', function() Snacks.picker.buffers() end, desc = 'Find buffers' },
    { '<leader>fB', function() Snacks.picker.grep_buffers() end, desc = 'Find grep buffers' },
    { '<leader>fc', function() Snacks.picker.files({ cwd = vim.fn.stdpath('config') }) end, desc = 'Find config file' },
    { '<leader>ff', function() Snacks.picker.files() end, desc = 'Find files' },
    { '<leader>fg', function() Snacks.picker.grep() end, desc = 'Find grep' },
    { '<leader>fh', function() Snacks.picker.git_files() end, desc = 'Find git files'},
    { '<leader>fp', function() Snacks.picker.projects() end, desc = 'Find projects' },
    { '<leader>fr', function() Snacks.picker.recent() end, desc = 'Find recent files' },
    { '<leader>fa', function() Snacks.picker.autocmds() end, desc = 'Find autocmds' },
    { '<leader>fl', function() Snacks.picker.lines() end, desc = 'Find buffer lines' },
    { '<leader>fd', function() Snacks.picker.diagnostics() end, desc = 'Find diagnostics' },
    { '<leader>fD', function() Snacks.picker.diagnostics_buffer() end, desc = 'Find buffer diagnostics' },
    { '<leader>fi', function() Snacks.picker.icons() end, desc = 'Find icons' },
    { '<leader>fj', function() Snacks.picker.jumps() end, desc = 'Find jumps' },
    { '<leader>fk', function() Snacks.picker.keymaps() end, desc = 'Find keymaps' },
    { '<leader>fm', function() Snacks.picker.marks() end, desc = 'Find marks' },
    { '<leader>fM', function() Snacks.picker.man() end, desc = 'Find man pages' },
    { '<leader>fp', function() Snacks.picker.lazy() end, desc = 'Find plugins' },
    { '<leader>fq', function() Snacks.picker.qflist() end, desc = 'Find in quickfix list' },
    { '<leader>fu', function() Snacks.picker.undo() end, desc = 'Find in undo history' },
    { '<leader>fn', function() Snacks.picker.notifications() end, desc = 'Find notifications' },
    { "<leader>fs", function() Snacks.scratch.select() end, desc = "Find scratch buffer" },
    { "<leader>fH", function() Snacks.picker.highlights() end, desc = "Find highlights groups" },

    -- Buffers
    { "<leader>bs", function() Snacks.scratch() end, desc = "Toggle scratch buffer" },
    { "<leader>bd", function() Snacks.bufdelete() end, desc = "Delete buffer" },
    { "<leader>bD", function() Snacks.bufdelete.all() end, desc = "Delete all buffers" },
    { "<leader>bc", function() Snacks.bufdelete.other() end, desc = "Delete all except current buffer" },
    { "<leader>br", function() Snacks.rename.rename_file() end, desc = "Rename buffer" },
    { '<leader>bf', function() Snacks.picker.buffers() end, desc = 'Find buffers' },
    { '<leader>b/', function() Snacks.picker.grep_buffers() end, desc = 'Find grep buffers' },

    -- Git
    { '<leader>hh', desc = 'Lazygit', function() Snacks.lazygit() end },
    { '<leader>hb', function() Snacks.picker.git_branches() end, desc = 'Git branches' },
    { '<leader>hB', function() Snacks.git.blame_line() end, desc = 'Git blame line' },
    { "<leader>ho", function() Snacks.gitbrowse() end, desc = "Git open in browser", mode = { "n", "v" } },
    { '<leader>hl', function() Snacks.picker.git_log() end, desc = 'Git log' },
    { '<leader>hL', function() Snacks.picker.git_log_line() end, desc = 'Git log line' },
    { '<leader>hs', function() Snacks.picker.git_status() end, desc = 'Git status' },
    { '<leader>hS', function() Snacks.picker.git_stash() end, desc = 'Git stash' },
    { '<leader>hd', function() Snacks.picker.git_diff() end, desc = 'Git diff (hunks)' },
    { '<leader>hf', function() Snacks.picker.git_log_file() end, desc = 'Git log file' },

    -- Code/LSP
    { "gd", function() Snacks.picker.lsp_definitions() end, desc = "Goto definition" },
    { "gD", function() Snacks.picker.lsp_declarations() end, desc = "Goto declaration" },
    { "gR", function() Snacks.picker.lsp_references() end, nowait = true, desc = "Goto references" },
    { "gI", function() Snacks.picker.lsp_implementations() end, desc = "Goto implementation" },
    { "gy", function() Snacks.picker.lsp_type_definitions() end, desc = "Goto type definition" },
    { "<leader>cs", function() Snacks.picker.lsp_symbols() end, desc = "LSP symbols" },
    { "<leader>cS", function() Snacks.picker.lsp_workspace_symbols() end, desc = "LSP workspace symbols" },

    -- Others
    { "]]", function() Snacks.words.jump(vim.v.count1) end, desc = "Next reference", mode = { "n", "t" } },
    { "[[", function() Snacks.words.jump(-vim.v.count1) end, desc = "Prev reference", mode = { "n", "t" } },
    { '<leader>ss', function() Snacks.picker.spelling() end, desc = 'Spellcheck suggestions' },
    --stylua: ignore end
  },
}
