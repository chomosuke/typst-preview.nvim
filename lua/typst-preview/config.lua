local M = {
  opts = {
    debug = false,
    open_cmd = nil,
    port = 0, -- tinymist will use a random port if this is 0
    invert_colors = 'never',
    follow_cursor = true,
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

local deprecated_opts = {
  'extra_args',
  'dependencies_bin'
}
local all_opts = {
  'debug',
  'open_cmd',
  'port',
  'invert_colors',
  'follow_cursor',
  'get_root',
  'get_main_file'
}

local function contains(table, value)
  for _, v in pairs(table) do
    if value == v then
      return true
    end
  end
  return false
end

function M.config(opts)
  local deprecated = {}
  local invalid = {}
  for key, _ in pairs(opts) do
    if not contains(all_opts, key) then
      if contains(deprecated_opts, key) then
        table.insert(deprecated, key)
      else
        table.insert(invalid, key)
      end
      opts[key] = nil
    end
  end

  if next(invalid) then
    vim.notify(
      'typst-preview: invalid config keys: '
      .. table.concat(invalid, ', ')
      .. '\n',
      vim.log.levels.ERROR
    )
  end
  if next(deprecated) then
    vim.notify(
      'typst-preview: deprecated config keys: '
      .. table.concat(deprecated, ', ')
      .. '\n'
      .. 'Note that the plugin has changed substantially and does not download tinymist anymore, but connects to existing language servers. Please update your configuration, cf. the documentation',
      vim.log.levels.ERROR
    )
  end

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
