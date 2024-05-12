local event_server = require 'typst-preview.events.server'
local utils = require 'typst-preview.utils'
local editor = require 'typst-preview.events.editor'
local servers = require 'typst-preview.servers'

local M = {}

---Listen to Server's event
---All buffers are already watched via auto command
---@param s Server
function M.listen(s)
  event_server.add_listeners(s)
end

---Register autocmds to register autocmds for filetype
function M.init()
  utils.create_autocmds('typst-preview-all-autocmds', {
    {
      event = 'FileType',
      opts = {
        callback = function(ev)
          editor.register_autocmds(ev.buf)
        end,
        pattern = 'typst',
      },
    },
    {
      event = 'VimLeavePre',
      opts = {
        callback = servers.remove_all,
      },
    },
  })

  for _, bufnr in pairs(vim.api.nvim_list_bufs()) do
    if vim.bo[bufnr].filetype == 'typst' then
      editor.register_autocmds(bufnr)
    end
  end
end

return M
