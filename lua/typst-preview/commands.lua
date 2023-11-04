local events = require 'typst-preview.events'
local fetch = require 'typst-preview.fetch'
local utils = require 'typst-preview.utils'

local M = {}

local previewing = {}

function M.create_commands()
  local function preview_on()
    if not previewing[vim.fn.bufnr()] then
      previewing[vim.fn.bufnr()] = true
      events.watch(vim.fn.bufnr())
    else
      utils.print('Already previewing') -- TODO: open another front end to the same preview.
    end
  end
  local function preview_off()
    if previewing[vim.fn.bufnr()] then
      previewing[vim.fn.bufnr()] = false
      events.stop(vim.fn.bufnr())
    else
      utils.print('Preview not running')
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
