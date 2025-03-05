local M = {
  opts = {
    debug = false,
    open_cmd = nil,
    port = 0, -- tinymist will use a random port if this is 0
    partial_rendering = true,
    invert_colors = 'never',
    follow_cursor = true,
    dependencies_bin = {
      ['tinymist'] = nil,
      ['websocat'] = nil,
    },
    extra_args = nil,
    get_root = function(path_of_main_file)
      local root = os.getenv 'TYPST_ROOT'
      if root then
        return root
      end
      return vim.fn.fnamemodify(path_of_main_file, ':p:h')
    end,
    get_main_file = function(path)
      return path
    end,
  },
}

function M.config(opts)
  M.opts = vim.tbl_deep_extend('force', M.opts, opts or {})
end

---Set the way preview scrolling respond to cursor movement
---@param enabled boolean
function M.set_follow_cursor(enabled)
  M.opts.follow_cursor = enabled
end

---Get current preview scrolling mode
---@return boolean
function M.get_follow_cursor()
  return M.opts.follow_cursor
end

return M
