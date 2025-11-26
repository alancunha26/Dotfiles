return {
  'zk-org/zk-nvim',
  cond = function()
    return vim.fn.isdirectory(vim.fn.getcwd() .. '/.zk') == 1
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
      { '<leader>zz', extras.open_index, desc = 'Open index zettel' },
      { '<leader>zc', extras.quick_capture, desc = 'Quick capture to inbox' },
      { '<leader>zi', extras.open_inbox, desc = 'Open inbox' },
    }
  end,
}
