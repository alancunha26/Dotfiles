return {
  {
    'romus204/tree-sitter-manager.nvim',
    lazy = false,
    config = function()
      local parsers = {
        'bash',
        'c',
        'css',
        'diff',
        'eex',
        'elixir',
        'gdscript',
        'gdshader',
        'godot_resource',
        'heex',
        'html',
        'javascript',
        'json',
        'lua',
        'luadoc',
        'markdown',
        'markdown_inline',
        'printf',
        'query',
        'regex',
        'rust',
        'sql',
        'toml',
        'tsx',
        'typescript',
        'vim',
        'vimdoc',
        'yaml',
      }

      -- tree-sitter-manager.nvim's built-in highlight autocmd uses parser
      -- names as FileType patterns, which fails when the filetype differs
      -- (e.g. tsx parser vs typescriptreact filetype). Disable it and
      -- register our own with proper language-to-filetype mapping.
      require('tree-sitter-manager').setup({
        ensure_installed = parsers,
        auto_install = true,
        highlight = false,
      })

      local filetypes = {}
      for _, parser in ipairs(parsers) do
        for _, ft in ipairs(vim.treesitter.language.get_filetypes(parser)) do
          filetypes[ft] = true
        end
      end

      vim.api.nvim_create_autocmd('FileType', {
        pattern = vim.tbl_keys(filetypes),
        callback = function(args)
          pcall(vim.treesitter.start, args.buf)
        end,
        desc = 'Start treesitter for installed parsers',
      })
    end,
  },
}
