local M = {
  opts = {
    open_cmd = nil,
    invert_colors = 'never',
    debug = false,
    get_root = function(_)
      return vim.fn.getcwd()
    end,
  },
}

function M.config(opts)
  M.opts = vim.tbl_deep_extend('force', M.opts, opts or {})
end

return M
