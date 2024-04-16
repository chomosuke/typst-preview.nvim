local events = require 'typst-preview.events'
local fetch = require 'typst-preview.fetch'
local utils = require 'typst-preview.utils'
local init = require 'typst-preview.init'
local config = require 'typst-preview.config'

local M = {}

local previewing = {}
local previewing_mode = {}

function M.create_commands()
  local function preview_off(bufnr)
    bufnr = bufnr or vim.fn.bufnr()
    if previewing[bufnr] then
      previewing[bufnr] = false
      events.stop(bufnr)
    else
      utils.print 'Preview not running'
    end
  end

  local function preview_on(mode)
    local bufnr = vim.fn.bufnr()
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

    local function start_preview()
      utils.create_autocmds('typst-preview-autocmds-unload-' .. bufnr, {
        {
          event = 'BufUnload',
          opts = {
            callback = function()
              -- preview_off is the source of truth of cleaning up everything.
              preview_off(bufnr)
            end,
            buffer = bufnr,
          },
        },
      })
      previewing[bufnr] = true
      previewing_mode[bufnr] = mode
      events.watch(bufnr, mode, function(link)
        previewing[bufnr] = link
      end)
    end

    if not previewing[bufnr] then
      start_preview()
    elseif type(previewing[bufnr]) == 'string' then
      if previewing_mode[bufnr] == mode then
        print 'Opening another frontend'
        utils.visit(previewing[bufnr])
      else
        print ('Re-starting preview with new mode ' .. mode)
        events.stop(bufnr)
        start_preview()
      end
    end
  end

  vim.api.nvim_create_user_command('TypstPreviewUpdate', init.update, {})

  vim.api.nvim_create_user_command(
    'TypstPreview',
    function(opts)
      local mode = 'document'
      if #opts.fargs == 0 then
        -- Use default mode
      elseif #opts.fargs == 1 then
        mode = opts.fargs[1]
        if mode ~= 'document' and mode ~= 'slide'  then
          utils.notify(
            'Invalid preview mode: "' .. mode .. '.'
            .. ' Should be one of "document" and "slide"',
            vim.log.levels.ERROR
          )
          return
        end
      else
        -- Error already handled by nvim, via the `nargs = '?'` below
        return
      end

      preview_on(mode)
    end,
    { nargs = '?' }
  )
  vim.api.nvim_create_user_command('TypstPreviewStop', function()
    preview_off()
  end, {})
  vim.api.nvim_create_user_command('TypstPreviewToggle', function()
    local bufnr = vim.fn.bufnr()
    if previewing[bufnr] then
      preview_off()
    else
      -- use the previous preview mode, if there was a :TypstPreview call before
      local mode = previewing_mode[bufnr]
      if mode == nil then
        mode = 'document'
      end
      preview_on(mode)
    end
  end, {})

  vim.api.nvim_create_user_command('TypstPreviewFollowCursor', function()
    init.set_follow_cursor(true)
  end, {})
  vim.api.nvim_create_user_command('TypstPreviewNoFollowCursor', function()
    init.set_follow_cursor(false)
  end, {})
  vim.api.nvim_create_user_command('TypstPreviewFollowCursorToggle', function()
    init.set_follow_cursor(not init.get_follow_cursor())
  end, {})
  vim.api.nvim_create_user_command('TypstPreviewSyncCursor', function()
    init.sync_with_cursor()
  end, {})
end

return M
