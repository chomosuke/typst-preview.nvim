local config = require 'typst-preview.config'
local event_server = require 'typst-preview.events.server'
local utils = require 'typst-preview.utils'
local editor = require 'typst-preview.events.editor'
local servers = require 'typst-preview.servers'

local M = {}

---Setup listeners for server -> editor communication, and register filetype
---autocmds that setup listeners for editor -> server communication.
function M.init()
  -- Listen to Server's event
  servers.listen_scroll(event_server.on_editor_scroll_to)

  if config.opts.use_lsp then
    -- When using tinymist via vim.lsp, we don't need to update document state
    -- nvim already handles it in that case.
    -- FIXME: Do we still want to use the VimLeavePre autocmd below? Or is it
    -- sufficient that nvim shuts down tinymist?
    return
  end

  -- Register autocmds to register autocmds for filetype
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
