local config = require 'typst-preview.config'
local events = require 'typst-preview.events'
local manager = require 'typst-preview.manager'
local utils = require 'typst-preview.utils'

local M = {}

---Create user commands
function M.create_commands()
  ---@param path string?
  local function preview_off(path)
    if path and manager.remove(
      {path = path},
      'user request'
    ) then
      utils.print 'Preview stopped'
    else
      utils.print 'Preview not running'
    end
  end

  ---@param path string
  ---@param mode mode?
  local function preview_on(path, mode)
    assert(path)
    mode = mode or 'document'

    events.ensure_registered()

    manager.get_or_init(
      path,
      mode,
      function(task, is_new)
        if is_new then
          print 'Preview started'
        else
          print 'Opening another frontend'
        end
        utils.visit(task.link)
      end
    )
  end

  vim.api.nvim_create_user_command('TypstPreviewUpdate', function(opts)
    vim.notify(
      'TypstPreviewUpdate is deprecated',
      vim.log.levels.ERROR
    )
  end, {})

  vim.api.nvim_create_user_command('TypstPreview', function(opts)
    local path = utils.get_main_file()
    if path == nil then
      utils.notify('Can not preview an unsaved buffer.', vim.log.levels.ERROR)
      return
    end

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
        return
      end
    else
      assert(#opts.fargs == 0)
      mode = manager.get_last_mode(path)
    end

    preview_on(path, mode)
  end, {
    nargs = '?',
    complete = function(_, _, _)
      return { 'document', 'slide' }
    end,
  })

  vim.api.nvim_create_user_command('TypstPreviewStop', function()
    local path = utils.get_main_file()
    preview_off(path)
  end, {})

  vim.api.nvim_create_user_command('TypstPreviewToggle', function()
    local path = utils.get_main_file()
    if path == nil then
      utils.notify('Can not preview an unsaved buffer.', vim.log.levels.ERROR)
      return
    end

    if next(manager.get{path=path}) ~= nil then
      preview_off(path)
    else
      preview_on(path, manager.get_last_mode(path))
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
    manager.scroll_preview()
  end, {})
end

return M
