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
  server.spawn(function(data)
    -- TODO: respond to preview scroll.
  end, function(close_server, write)
    local function on_change()
      utils.debug('updating buffer: ' .. bufnr)
      write(
        '{"event":"updateMemoryFiles","files":{"'
          .. escape_str(server.get_dummy_path())
          .. '":"'
          .. escape_str(utils.get_buf_content(bufnr))
          .. '"}}\n'
      )
    end
    local function on_editor_scroll() end

    vim.defer_fn(function()
      on_change()
    end, 0)

    utils.create_autocmds('typst-preview-autocmds-' .. bufnr, {
      {
        event = { 'TextChanged', 'TextChangedI' },
        opts = {
          callback = on_change,
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
