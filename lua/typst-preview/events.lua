local server = require 'typst-preview.server'
local utils = require 'typst-preview.utils'

-- Both event from the editor and the previewer
local M = {}

-- taken from https://stackoverflow.com/a/40857186/9069929
local function escape_str(s)
  local in_char = { '\\', '"', '/', '\b', '\f', '\n', '\r', '\t' }
  local out_char = { '\\', '"', '/', 'b', 'f', 'n', 'r', 't' }
  for i, c in ipairs(in_char) do
    s = s:gsub(c, '\\' .. out_char[i])
  end
  return s
end

---Call close[bufnr]() to close preview for bufnr
local close = {}

---Do all work necessary to start a preview for a buffer.
---@param bufnr integer
function M.watch(bufnr)
  local server_buf = ''
  server.spawn(bufnr, function(data)
    -- TODO: respond to preview scroll.
  end, function(close_server, write)
    local function on_change()
      utils.debug('updating buffer: ' .. bufnr)
      write(
        '{"event":"updateMemoryFiles","files":{"'
          .. escape_str(server.get_buffer_path(bufnr))
          .. '":"'
          .. escape_str(utils.get_buf_content(bufnr))
          .. '"}}\n'
      )
    end

    local function on_editor_scroll()
      utils.debug('scrolling: ' .. bufnr)
      local cursor = vim.api.nvim_win_get_cursor(0)
      write(
        '{"event":"panelScrollTo","filepath":"'
          .. escape_str(server.get_buffer_path(bufnr))
          .. '","line":'
          .. cursor[1] - 1
          .. ',"character":'
          .. cursor[2]
          .. '}\n'
      )
    end

    local function sync()
      write(
        '{"event":"syncMemoryFiles","files":{"'
          .. escape_str(server.get_buffer_path(bufnr))
          .. '":"'
          .. escape_str(utils.get_buf_content(bufnr))
          .. '"}}\n'
      )
    end

    vim.defer_fn(sync, 0)

    utils.create_autocmds('typst-preview-autocmds-' .. bufnr, {
      {
        event = { 'TextChanged', 'TextChangedI' },
        opts = {
          callback = on_change,
          buffer = bufnr,
        },
      },
      {
        event = { 'CursorMoved', 'CursorMovedI' },
        opts = {
          callback = on_editor_scroll,
          buffer = bufnr,
        },
      },
      {
        event = 'BufUnload',
        opts = {
          callback = function()
            M.stop(bufnr)
          end,
          buffer = bufnr,
        },
      },
    })

    close[bufnr] = close_server
  end)
end

function M.stop(bufnr)
  utils.debug 'Server closed'
  close[bufnr]()
end

return M
