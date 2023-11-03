local events = require 'typst-preview.events'

local M = {}

-- TODO: TypstPreviewToggle, TypstPreviewUpdate
function M.create_commands()
  vim.api.nvim_create_user_command('TypstPreview', function()
    events.watch(vim.fn.bufnr())
  end, {})
  vim.api.nvim_create_user_command('TypstPreviewStop', function()
    events.stop(vim.fn.bufnr())
  end, {})
end

return M
