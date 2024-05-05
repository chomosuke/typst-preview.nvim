local server = require 'typst-preview.server'
local utils = require 'typst-preview.utils'
local config = require 'typst-preview.config'

local M = {}

---Set the way preview scrolling respond to cursor movement
---@param enabled boolean
function M.set_follow_cursor(enabled)
  config.opts.follow_cursor = enabled
end

---Get current preview scrolling mode
---@return boolean
function M.get_follow_cursor()
  return config.opts.follow_cursor
end

local function sync_with_cursor(comm, bufnr)
  local cursor = vim.api.nvim_win_get_cursor(0)
  local line = cursor[1] - 1
  comm.write(vim.fn.json_encode {
    event = 'panelScrollTo',
    filepath = server.get_buffer_path(bufnr),
    line = line,
    character = cursor[2],
  } .. '\n')
end

---Scroll preview to where cursor is regardless of preview scrolling mode
function M.sync_with_cursor()
  for _, comm in pairs(communicator.comms) do
    sync_with_cursor(comm, vim.fn.bufnr())
  end
end

---register autocmds for this buffer to do the same for all comms
local function register_autocmds(bufnr)
  local last_line
  local autocmds = {
    {
      event = { 'TextChanged', 'TextChangedI', 'TextChangedP', 'InsertLeave' },
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
        if super.suppress_on_scroll or not M.get_follow_cursor() then
          return
        end
        utils.debug('scrolling: ' .. bufnr)
        local cursor = vim.api.nvim_win_get_cursor(0)
        local line = cursor[1] - 1
        if last_line ~= line or ev.event ~= 'CursorMovedI' then
          -- No scroll when on the same line in insert mode
          last_line = line
          sync_with_cursor(comm, bufnr)
        end
      end,
    },
        {
          event = 'BufUnload',
          opts = {
            callback = function()
              -- preview_off is the source of truth of cleaning up everything.
              preview_off(bufnr)
            end,
            buffer = bufnr,
          },
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
