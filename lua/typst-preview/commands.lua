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

  local function preview_on()
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

    local path = utils.get_buf_path(0)
    if path == '' then
      print 'Can not preview an unsaved buffer.'
      return
    end

    path = config.opts.get_main_file(path)
    local s = servers.get(path)
    if s == nil then
      servers.init(path, function(ser)
        events.listen(ser)
      end)
    else
      print 'Opening another frontend'
      utils.visit(s.link)
    end
  end

  vim.api.nvim_create_user_command('TypstPreviewUpdate', function()
    fetch.fetch(nil)
  end, {})

  vim.api.nvim_create_user_command('TypstPreview', preview_on, {})
  vim.api.nvim_create_user_command('TypstPreviewStop', preview_off, {})
  vim.api.nvim_create_user_command('TypstPreviewToggle', function()
    local path = utils.get_buf_path(0)
    if path ~= '' and servers.get(config.opts.get_main_file(path)) ~= nil then
      preview_off()
    else
      preview_on()
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
