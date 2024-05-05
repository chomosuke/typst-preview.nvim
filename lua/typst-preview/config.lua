local M = {
  opts = {
    open_cmd = nil,
    invert_colors = 'never',
    debug = false,
    dependencies_bin = {
      ['typst-preview'] = nil,
      ['websocat'] = nil,
    },
    get_root = function(path)
      return vim.fn.fnamemodify(path, ':p:h')
    end,
    get_main_file = function(path)
      return path
    end,
    follow_cursor = true,
  },
}

function M.config(opts)
  M.opts = vim.tbl_deep_extend('force', M.opts, opts or {})
end

return M
