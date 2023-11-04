local events = require 'typst-preview.events'
local fetch = require 'typst-preview.fetch'

local M = {}

local previewing = {}

function M.create_commands()
  local function preview_on()
    if not previewing[vim.fn.bufnr()] then
      previewing[vim.fn.bufnr()] = true
      events.watch(vim.fn.bufnr())
    end
  end
  local function preview_off()
    if previewing[vim.fn.bufnr()] then
      previewing[vim.fn.bufnr()] = false
      events.stop(vim.fn.bufnr())
    end
  end
  vim.api.nvim_create_user_command('TypstPreview', preview_on, {})
  vim.api.nvim_create_user_command('TypstPreviewStop', preview_off, {})
  vim.api.nvim_create_user_command('TypstPreviewToggle', function()
    if previewing[vim.fn.bufnr()] then
      preview_off()
    else
      preview_on()
    end
  end, {})
  vim.api.nvim_create_user_command('TypstPreviewUpdate', fetch.fetch, {})
end

return M
