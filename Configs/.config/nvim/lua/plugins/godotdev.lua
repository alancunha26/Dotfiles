return {
  'Mathijs-Bakker/godotdev.nvim',
  dependencies = {
    'mfussenegger/nvim-dap',
    { 'rcarriga/nvim-dap-ui', dependencies = { 'nvim-neotest/nvim-nio' } },
  },
  ft = { 'gdscript', 'gdshader' },
  cmd = {
    'GodotStartEditorServer',
    'GodotReconnectLSP',
    'GodotRunProject',
    'GodotRunCurrentScene',
    'GodotRunScene',
    'GodotRunScenePicker',
    'GodotShowConsole',
    'GodotSceneTree',
    'GodotDocs',
    'GodotDocsCursor',
  },
  opts = {
    csharp = false,
    -- gdformat (Mason's gdtoolkit) instead of the default
    -- gdscript-formatter, whose --reorder-code rewrites declarations
    formatter = 'gdformat',
    -- server.pipe is started from config.commands so Godot can reach
    -- nvim even before the first .gd file is opened
    autostart_editor_server = false,
    run = {
      console = { enabled = true },
    },
    -- parsers are managed in plugins/treesitter.lua
    treesitter = { auto_setup = false },
  },
  config = function(_, opts)
    require('godotdev').setup(opts)

    -- The builtin picker requires telescope; replace it with snacks
    vim.api.nvim_create_user_command('GodotRunScenePicker', function()
      local root = vim.fs.root(vim.fn.getcwd(), 'project.godot')
      if not root then
        return vim.notify('project.godot not found', vim.log.levels.ERROR)
      end
      local items = {}
      for i, scene in ipairs(vim.fn.glob(root .. '/**/*.tscn', true, true)) do
        items[#items + 1] = {
          idx = i,
          text = 'res://' .. scene:sub(#root + 2),
          file = scene,
        }
      end
      Snacks.picker({
        title = 'Godot Scenes',
        items = items,
        format = 'text',
        confirm = function(picker, item)
          picker:close()
          vim.cmd('GodotRunScene ' .. item.text)
        end,
      })
    end, { desc = 'Run a Godot scene (snacks picker)' })
  end,
}
