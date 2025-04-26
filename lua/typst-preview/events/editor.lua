local servers = require 'typst-preview.servers'
local utils = require 'typst-preview.utils'
local config= require 'typst-preview.config'

local M = {}

---Register autocmds for a buffer
---@param bufnr integer
function M.register_autocmds(bufnr)
  local last_line
  local autocmds = {
    {
      event = { 'TextChanged', 'TextChangedI', 'TextChangedP', 'InsertLeave' },
      callback = function(_ev)
        servers.update_memory_file(
          utils.get_buf_path(bufnr),
          utils.get_buf_content(bufnr)
        )
      end,
    },
    {
      event = { 'CursorMoved' },
      callback = function(_ev)
        if not config.get_follow_cursor() then
          return
        end
        local line = vim.api.nvim_win_get_cursor(0)[1]
        if last_line ~= line then
          -- No scroll when on the same line in insert mode
          last_line = line
          servers.scroll_preview()
        end
      end,
    },
  }

  for i, autocmd in pairs(autocmds) do
    utils.create_autocmds('typst-preview-autocmds-' .. i .. '-' .. bufnr, {
      {
        event = autocmd.event,
        opts = {
          callback = autocmd.callback,
          buffer = bufnr,
        },
      },
    })
  end
end

return M
