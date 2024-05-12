local events = require 'typst-preview.events'
local fetch = require 'typst-preview.fetch'
local utils = require 'typst-preview.utils'
local config = require 'typst-preview.config'
local servers = require 'typst-preview.servers'

local M = {}

---Scroll all preview to cursor position.
function M.sync_with_cursor()
  for _, ser in pairs(servers.get_all()) do
    servers.sync_with_cursor(ser)
  end
end

---Create user commands
function M.create_commands()
  local function preview_off()
    local path = utils.get_buf_path(0)

    if path ~= '' and servers.remove(config.opts.get_main_file(path)) then
      utils.print 'Preview stopped'
    else
      utils.print 'Preview not running'
    end
  end

  local function get_path()
    local path = utils.get_buf_path(0)
    if path == '' then
      utils.notify('Can not preview an unsaved buffer.', vim.log.levels.ERROR)
      return nil
    else
      return config.opts.get_main_file(path)
    end
  end

  ---@param mode mode?
  local function preview_on(mode)
    -- check if binaries are available and tell them to fetch first
    for _, bin in pairs(fetch.bins_to_fetch()) do
      if
        not fetch.up_to_date(bin) and not config.opts.dependencies_bin[bin.name]
      then
        utils.notify(
          bin.name
            .. ' not found or out of date\nPlease run :TypstPreviewUpdate first!',
          vim.log.levels.ERROR
        )
        return
      end
    end

    local path = get_path()
    if path == nil then
      return
    end

    mode = mode or 'document'

    local ser = servers.get(path)
    if ser == nil or ser[mode] == nil then
      servers.init(path, mode, function(s)
        events.listen(s)
      end)
    else
      local s = ser[mode]
      print 'Opening another frontend'
      utils.visit(s.link)
    end
  end

  vim.api.nvim_create_user_command('TypstPreviewUpdate', function()
    fetch.fetch(nil)
  end, {})

  vim.api.nvim_create_user_command('TypstPreview', function(opts)
    local mode
    if #opts.fargs == 1 then
      mode = opts.fargs[1]
      if mode ~= 'document' and mode ~= 'slide' then
        utils.notify(
          'Invalid preview mode: "'
            .. mode
            .. '.'
            .. ' Should be one of "document" and "slide"',
          vim.log.levels.ERROR
        )
      end
    else
      assert(#opts.fargs == 0)
      local path = get_path()
      if path == nil then
        return
      end
      local sers = servers.get(path)
      if sers ~= nil then
        mode = servers.get_last_mode(path)
      end
    end

    preview_on(mode)
  end, {
    nargs = '?',
    complete = function(_, _, _)
      return { 'document', 'slide' }
    end,
  })
  vim.api.nvim_create_user_command('TypstPreviewStop', preview_off, {})
  vim.api.nvim_create_user_command('TypstPreviewToggle', function()
    local path = get_path()
    if path == nil then
      return
    end

    if servers.get(path) ~= nil then
      preview_off()
    else
      preview_on(servers.get_last_mode(path))
    end
  end, {})

  vim.api.nvim_create_user_command('TypstPreviewFollowCursor', function()
    config.set_follow_cursor(true)
  end, {})
  vim.api.nvim_create_user_command('TypstPreviewNoFollowCursor', function()
    config.set_follow_cursor(false)
  end, {})
  vim.api.nvim_create_user_command('TypstPreviewFollowCursorToggle', function()
    config.set_follow_cursor(not config.get_follow_cursor())
  end, {})
  vim.api.nvim_create_user_command('TypstPreviewSyncCursor', function()
    M.sync_with_cursor()
  end, {})
end

return M
