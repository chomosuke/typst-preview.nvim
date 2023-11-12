local server = require 'typst-preview.server'
local utils = require 'typst-preview.utils'
local super = require 'typst-preview.events'
local communicator = require 'typst-preview.events.communicator'

local M = {}

---register autocmds for this buffer to do the same for all comms
local function register_autocmds(bufnr)
  local last_line
  local autocmds = {
    {
      event = { 'TextChanged', 'TextChangedI' },
      callback = function(comm, _)
        utils.debug('updating buffer: ' .. bufnr)
        comm.write(vim.fn.json_encode {
          event = 'updateMemoryFiles',
          files = {
            [utils.get_buf_path(bufnr)] = utils.get_buf_content(bufnr),
          },
        } .. '\n')
      end,
    },
    {
      event = { 'CursorMoved', 'CursorMovedI' },
      callback = function(comm, ev)
        if super.suppress_on_scroll then
          return
        end
        utils.debug('scrolling: ' .. bufnr)
        local cursor = vim.api.nvim_win_get_cursor(0)
        local line = cursor[1] - 1
        if last_line ~= line or ev.event ~= 'CursorMovedI' then
          -- No scroll when on the same line in insert mode
          last_line = line
          comm.write(vim.fn.json_encode {
            event = 'panelScrollTo',
            filepath = server.get_buffer_path(bufnr),
            line = line,
            character = cursor[2],
          } .. '\n')
        end
      end,
    },
  }

  for i, autocmd in pairs(autocmds) do
    utils.create_autocmds('typst-preview-autocmds-' .. i .. '-' .. bufnr, {
      {
        event = autocmd.event,
        opts = {
          callback = function(ev)
            for _, comm in pairs(communicator.comms) do
              autocmd.callback(comm, ev)
            end
          end,
          buffer = bufnr,
        },
      },
    })
  end
end

function M.init()
  utils.create_autocmds('typst-preview-autocmds-filetype-init', {
    {
      event = 'FileType',
      opts = {
        callback = function(ev)
          register_autocmds(ev.buf)
        end,
        pattern = 'typst',
      },
    },
  })

  for _, bufnr in pairs(vim.api.nvim_list_bufs()) do
    if vim.bo[bufnr].filetype == 'typst' then
      register_autocmds(bufnr)
    end
  end
end

return M
