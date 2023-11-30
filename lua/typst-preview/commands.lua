local events = require 'typst-preview.events'
local fetch = require 'typst-preview.fetch'
local utils = require 'typst-preview.utils'
local init = require 'typst-preview.init'

local M = {}

local previewing = {}

local open_cmd
if fetch.is_macos() then
  open_cmd = 'open'
elseif
  fetch.is_windows()
  or (fetch.is_linux() and vim.loop.os_uname().release:lower():find 'microsoft')
then
  open_cmd = 'cmd.exe /c start ""'
else
  open_cmd = 'xdg-open'
end

local function visit(link)
  vim.fn.jobstart(string.format('%s %s', open_cmd, link), {
    on_stderr = function(_, data)
      local msg = table.concat(data or {}, '\n')
      if msg ~= '' then
        print('typst-preview opening link failed: ' .. msg)
      end
    end,
  })
end

function M.create_commands()
  local bufnr = vim.fn.bufnr()

  local function preview_off()
    if previewing[bufnr] then
      previewing[bufnr] = false
      events.stop(bufnr)
    else
      utils.print 'Preview not running'
    end
  end

  local function preview_on()
    -- check if binaries are available and tell them to fetch first
    for _, bin in pairs(fetch.bins_to_fetch()) do
      local path = fetch.get_path(bin.name)
      if not utils.file_exist(path) then
        utils.notify(
          path .. ' not found\nPlease run :TypstPreviewUpdate first!',
          vim.log.levels.ERROR
        )
      end
      return
    end

    if not previewing[bufnr] then
      utils.create_autocmds('typst-preview-autocmds-unload-' .. bufnr, {
        {
          event = 'BufUnload',
          opts = {
            callback = function()
              -- preview_off is the source of truth of cleaning up everything.
              preview_off()
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
      print 'Opening another fontend'
      visit(previewing[bufnr])
    end
  end

  vim.api.nvim_create_user_command('TypstPreviewUpdate', init.update, {})

  vim.api.nvim_create_user_command('TypstPreview', preview_on, {})
  vim.api.nvim_create_user_command('TypstPreviewStop', preview_off, {})
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
