local servers = require 'typst-preview.servers'
local utils = require 'typst-preview.utils'
local config= require 'typst-preview.config'

local M = {}

---Register autocmds for a buffer
---@param bufnr integer
function M.register_autocmds(bufnr)
  local last_line
  -- Each callback runs once per event and reaches every server itself. The
  -- "same line" check below must be made once per event, not once per server:
  -- made per server it lets only the first server through and starves the rest.
  local autocmds = {
    {
      event = { 'TextChanged', 'TextChangedI', 'TextChangedP', 'InsertLeave' },
      callback = function()
        local path = utils.get_buf_path(bufnr)
        local content = utils.get_buf_content(bufnr)
        for _, ser in pairs(servers.get_all()) do
          servers.update_memory_file(ser, path, content)
        end
      end,
    },
    {
      event = { 'CursorMoved' },
      callback = function()
        if not config.get_follow_cursor() then
          return
        end
        local line = vim.api.nvim_win_get_cursor(0)[1]
        if last_line == line then
          -- No scroll when on the same line in insert mode
          return
        end
        last_line = line
        for _, ser in pairs(servers.get_all()) do
          servers.sync_with_cursor(ser)
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
