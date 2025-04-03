return {
  'bullets-vim/bullets.vim',
  lazy = true,
  ft = {
    'markdown',
    'text',
    'txt',
  },
  init = function()
    vim.g.bullets_outline_levels = { 'ROM', 'ABC', 'num', 'abc', 'rom', 'std-' }
  end,
}
