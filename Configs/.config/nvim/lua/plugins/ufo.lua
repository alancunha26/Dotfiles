return {
  'kevinhwang91/nvim-ufo',
  event = 'VeryLazy',
  dependencies = {
    'kevinhwang91/promise-async',
  },
  opts = {
    provider_selector = function()
      return { 'lsp', 'indent' }
    end,
  },
  keys = {
    -- stylua: ignore start
    { 'zR', function () require('ufo').openAllFolds() end, desc = 'Open all folds' },
    { 'zM', function () require('ufo').closeAllFolds() end, desc = 'Close all folds' },
    -- stylua: ignore end
  },
}
