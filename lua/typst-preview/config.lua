local M = {
  opts = {
    debug = false,
    get_root = function(_)
      return vim.fn.getcwd()
    end,
  },
}

function M.setup(opts)
  M.opts = vim.tbl_deep_extend('force', M.opts, opts or {})
end

return M
