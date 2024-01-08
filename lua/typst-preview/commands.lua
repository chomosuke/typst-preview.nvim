local events = require 'typst-preview.events'
local fetch = require 'typst-preview.fetch'
local utils = require 'typst-preview.utils'
local init = require 'typst-preview.init'

local M = {}

local previewing = {}

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

  local function preview_on()
    local bufnr = vim.fn.bufnr()
    -- check if binaries are available and tell them to fetch first
    for _, bin in pairs(fetch.bins_to_fetch()) do
      if not fetch.up_to_date(bin) then
        utils.notify(
          bin.name
            .. ' not found or out of date\nPlease run :TypstPreviewUpdate first!',
          vim.log.levels.ERROR
        )
        return
      end
    end

    if not previewing[bufnr] then
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
      events.watch(bufnr, function(link)
        previewing[bufnr] = link
      end)
    elseif type(previewing[bufnr]) == 'string' then
      print 'Opening another frontend'
      utils.visit(previewing[bufnr])
    end
  end

  vim.api.nvim_create_user_command('TypstPreviewUpdate', init.update, {})

  vim.api.nvim_create_user_command('TypstPreview', preview_on, {})
  vim.api.nvim_create_user_command('TypstPreviewStop', function()
    preview_off()
  end, {})
  vim.api.nvim_create_user_command('TypstPreviewToggle', function()
    if previewing[vim.fn.bufnr()] then
      preview_off()
    else
      preview_on()
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
