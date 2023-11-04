local server = require 'typst-preview.server'
local utils = require 'typst-preview.utils'
local json = require 'typst-preview.json'

-- Both event from the editor and the previewer
local M = {}

---Call close[bufnr]() to close preview for bufnr
local close = {}

---Do all work necessary to start a preview for a buffer.
---@param bufnr integer
function M.watch(bufnr)
  utils.debug('Watching buffer: ' .. bufnr)

  if bufnr == 0 then
    bufnr = vim.fn.bufnr()
  end

  local buf_path = server.get_buffer_path(bufnr)
  server.spawn(bufnr, function(close_server, write, read_start)
    local function on_change()
      utils.debug('updating buffer: ' .. bufnr)
      write(json.encode {
        event = 'updateMemoryFiles',
        files = {
          [buf_path] = utils.get_buf_content(bufnr),
        },
      } .. '\n')
    end

    -- So that moving cursor for editorScrollTo does generate panelScrollTo events
    local suppress_on_scroll = false
    local function on_editor_scroll()
      if suppress_on_scroll then
        return
      end
      utils.debug('scrolling: ' .. bufnr)
      local cursor = vim.api.nvim_win_get_cursor(0)
      write(json.encode {
        event = 'panelScrollTo',
        filepath = buf_path,
        line = cursor[1] - 1,
        character = cursor[2],
      } .. '\n')
    end

    read_start(function(data)
      vim.defer_fn(function()
        while data:len() > 0 do
          local s, _ = data:find '\n'
          local event = json.decode(data:sub(1, s - 1))
          data = data:sub(s + 1, -1)
          if event.event == 'syncEditorChanges' then
            write(json.encode {
              event = 'syncMemoryFiles',
              files = {
                [buf_path] = utils.get_buf_content(bufnr),
              },
            } .. '\n')
          elseif event.event == 'editorScrollTo' then
            local cmd = '<esc>'
              .. event.start[1] + 1
              .. 'G0'
              .. event.start[2]
              .. 'lv'
              .. event['end'][1] + 1
              .. 'G0'
              .. event['end'][2] - 1
              .. 'l'
            utils.debug(cmd)
            suppress_on_scroll = true
            vim.api.nvim_input(cmd)
            vim.defer_fn(function()
              suppress_on_scroll = false
            end, 100)
          end
        end
      end, 0)
    end)

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
