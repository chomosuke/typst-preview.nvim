local root_markers = { 'typst.toml', '.git' }

local M = {
  opts = {
    debug = false,
    open_cmd = nil,
    port = 0, -- tinymist will use a random port if this is 0
    host = '127.0.0.1',
    invert_colors = 'never',
    follow_cursor = true,
    dependencies_bin = {
      ['tinymist'] = nil,
      ['websocat'] = nil,
    },
    extra_args = nil,
    get_root = function(path_of_main_file)
      local env_root = os.getenv 'TYPST_ROOT'
      if env_root then
        return env_root
      end

      -- Use project markers to pick a root that still allows parent imports
      local main_dir = vim.fs.dirname(vim.fn.fnamemodify(path_of_main_file, ':p'))
      local found = vim.fs.find(root_markers, { path = main_dir, upward = true })
      if #found > 0 then
        return vim.fs.dirname(found[1])
      end

      return main_dir
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
