local M = {
  opts = {
    debug = false,
  },
}

function M.setup(opts)
  M.opts = vim.tbl_deep_extend('force', M.opts, opts or {})
end

return M
