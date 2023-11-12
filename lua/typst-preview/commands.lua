local events = require 'typst-preview.events'
local fetch = require 'typst-preview.fetch'
local utils = require 'typst-preview.utils'

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
  local function preview_on()
    if not previewing[vim.fn.bufnr()] then
      previewing[vim.fn.bufnr()] = true
      events.watch(vim.fn.bufnr(), function(link)
        previewing[vim.fn.bufnr()] = link
      end)
    elseif type(previewing[vim.fn.bufnr()]) == 'string' then
      print 'Opening another fontend'
      visit(previewing[vim.fn.bufnr()])
    end
  end
  local function preview_off()
    if previewing[vim.fn.bufnr()] then
      previewing[vim.fn.bufnr()] = false
      events.stop(vim.fn.bufnr())
    else
      utils.print 'Preview not running'
    end
  end
  -- TODO check if binaries are available and tell them to fetch first
  vim.api.nvim_create_user_command('TypstPreview', preview_on, {})
  vim.api.nvim_create_user_command('TypstPreviewStop', preview_off, {})
  vim.api.nvim_create_user_command('TypstPreviewToggle', function()
    if previewing[vim.fn.bufnr()] then
      preview_off()
    else
      preview_on()
    end
  end, {})
  vim.api.nvim_create_user_command('TypstPreviewUpdate', function()
    fetch.fetch()
  end, {})
  -- TODO ability stop scrolling
end

return M
