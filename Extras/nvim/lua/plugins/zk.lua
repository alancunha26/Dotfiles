return {
  'zk-org/zk-nvim',
  cond = function()
    return require('modules.zettels.config').is_zk_workspace()
  end,
  ft = "markdown",
  init = function()
    -- Grimoire sync starts eagerly (doesn't need zk plugin loaded)
    require('modules.zettels.sync').setup()
  end,
  config = function()
    require('zk').setup({
      picker = 'snacks_picker',

      lsp = {
        config = {
          cmd = { 'zk', 'lsp' },
          name = 'zk',

          on_attach = function(client)
            -- Disables definition provider to use marksman instead
            client.server_capabilities.definitionProvider = nil
          end,
        },

        auto_attach = {
          enabled = true,
          filetypes = { 'markdown' },
        },
      },
    })
  end,
  keys = function()
    local extras = require('modules.zettels.extras')
    return {
      { '<leader>z!', '<Cmd>ZkIndex<CR>', desc = 'Index zettels' },
      { '<leader>zt', '<Cmd>ZkTags<CR>', desc = 'Find tags' },
      { '<leader>zf', '<Cmd>ZkNotes<CR>', desc = 'Find zettels' },
      { '<leader>zl', '<Cmd>ZkLinks<CR>', desc = 'Find linked zettels' },
      { '<leader>zb', extras.buffers, desc = 'Find zettels buffers' },
      { '<leader>zB', '<Cmd>ZkBacklinks<CR>', desc = 'Find zettels backlinks' },
      { '<leader>zn', extras.new_zettel, mode = { 'n', 'v' }, desc = 'New zettel' },
      { '<leader>zN', extras.new_zettel_from_template, mode = { 'n', 'v' }, desc = 'New zettel from template' },
      { '<leader>zT', extras.insert_template, mode = { 'n', 'v' }, desc = 'Insert template' },
      { '<leader>zm', extras.mentions, mode = { 'n', 'v' }, desc = 'Find unlinked mentions' },
      { '<leader>zg', extras.grep, desc = 'Grep zettels' },
      { '<leader>zh', extras.headings, desc = 'Find headings' },
      { '<leader>zz', extras.open_index, desc = 'Open index zettel' },
      { '<leader>zc', extras.quick_capture, desc = 'Quick capture to inbox' },
      { '<leader>zi', extras.open_inbox, desc = 'Open inbox' },

      -- Task management
      { '<leader>zo', extras.open_tasks, desc = 'Open tasks' },
      { '<leader>za', extras.capture_task, desc = 'Add task' },
      { '<leader>zx', extras.toggle_task, desc = 'Toggle task checkbox' },
      { '<leader>zX', extras.complete_task, desc = 'Complete task' },
      { '<leader>zs', extras.find_tasks, desc = 'Find tasks' },

      -- Grimoire
      {
        '<leader>zv',
        function()
          require('modules.zettels.sync').force_navigate()
        end,
        desc = 'Preview in Grimoire',
      },
      {
        '<leader>zG',
        function()
          require('modules.zettels.sync').toggle_server()
        end,
        desc = 'Toggle Grimoire server',
      },
      {
        '<leader>zR',
        function()
          require('modules.zettels.sync').clear_cache()
        end,
        desc = 'Clear Grimoire cache + stop server',
      },
    }
  end,
}
