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
      -- Run once per event, outside the per-server loop. The message is
      -- identical for every server, so building it per server would re-read
      -- the whole buffer and re-encode it once for each open preview.
      prepare = function()
        local path = utils.get_buf_path(bufnr)
        local content = utils.get_buf_content(bufnr)
        return servers.build_memory_file_update(path, content)
      end,
      callback = function(ser, payload)
        servers.send_memory_file_update(ser, payload)
      end,
    },
    {
      event = { 'CursorMoved' },
      callback = function(ser)
        if not config.get_follow_cursor() then
          return
        end
        local line = vim.api.nvim_win_get_cursor(0)[1]
        if last_line ~= line then
          -- No scroll when on the same line in insert mode
          last_line = line
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
          callback = function()
            local all_servers = servers.get_all()
            if #all_servers == 0 then
              return
            end
            local payload
            if autocmd.prepare then
              payload = autocmd.prepare()
            end
            for _, ser in pairs(all_servers) do
              autocmd.callback(ser, payload)
            end
          end,
          buffer = bufnr,
        },
      },
    })
  end
end

return M
