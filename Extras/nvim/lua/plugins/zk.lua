return {
  'zk-org/zk-nvim',
  cond = function()
    return vim.fn.isdirectory(vim.fn.getcwd() .. '/.zk') == 1
  end,
  opts = {},
  keys = {},
}
