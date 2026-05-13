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

    require('modules.zettels.pickers').setup()
  end,
  keys = function()
    local extras = require('modules.zettels.extras')
    local views = require('modules.zettels.views')
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
      { '<leader>zd', extras.open_daily, desc = 'Open daily note' },

      -- Backlog & capture
      { '<leader>zo', extras.open_backlog, desc = 'Open backlog' },
      { '<leader>zc', extras.capture, desc = 'Capture task (today / backlog)' },
      { '<leader>zp', extras.pull_from_backlog, desc = 'Pull backlog item into today' },
      { '<leader>zP', extras.push_to_backlog, desc = 'Push current line to backlog' },
      { '<leader>zs', extras.find_backlog, desc = 'Find backlog items' },
      { '<leader>zx', extras.toggle_task, desc = 'Toggle task checkbox' },

      -- Views
      { '<leader>zv', views.insert, desc = 'Insert zk view' },
      { '<leader>zV', views.update, desc = 'Update zk views' },
      { '<leader>zU', views.update_all, desc = 'Update all zk views' },

      -- Grimoire
      {
        '<leader>zw',
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
