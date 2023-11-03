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
  if bufnr == 0 then
    bufnr = vim.fn.bufnr()
  end

  local buf_path = server.get_buffer_path(bufnr)
  server.spawn(bufnr, function(close_server, write, read_start)
    local function on_change()
      utils.debug('updating buffer: ' .. bufnr)
      write(
        '{"event":"updateMemoryFiles","files":{"'
          .. escape_str(buf_path)
          .. '":"'
          .. escape_str(utils.get_buf_content(bufnr))
          .. '"}}\n'
      )
    end

    -- So that moving cursor for editorScrollTo does generate panelScrollTo events
    local suppress_on_scroll = false
    local function on_editor_scroll()
      if suppress_on_scroll then
        return
      end
      utils.debug('scrolling: ' .. bufnr)
      local cursor = vim.api.nvim_win_get_cursor(0)
      write(
        '{"event":"panelScrollTo","filepath":"'
          .. escape_str(buf_path)
          .. '","line":'
          .. cursor[1] - 1
          .. ',"character":'
          .. cursor[2]
          .. '}\n'
      )
    end

    read_start(function(data)
      vim.defer_fn(function()
        while data:len() > 0 do
          local s, _ = data:find '\n'
          local line = data:sub(1, s - 1)
          data = data:sub(s + 1, -1)
          if line:find 'syncEditorChanges' then
            write(
              '{"event":"syncMemoryFiles","files":{"'
                .. escape_str(buf_path)
                .. '":"'
                .. escape_str(utils.get_buf_content(bufnr))
                .. '"}}\n'
            )
          elseif line:find 'editorScrollTo' then
            -- parse json by counting brackets
            local fst_bra, _ = line:find '%['
            local fst_com, _ = line:find(',', fst_bra)
            local fst_ket, _ = line:find('%]', fst_com)
            local snd_bra, _ = line:find('%[', fst_ket)
            local snd_com, _ = line:find(',', snd_bra)
            local snd_ket, _ = line:find('%]', snd_com)
            local s_row = tonumber(line:sub(fst_bra + 1, fst_com - 1))
            local s_col = tonumber(line:sub(fst_com + 1, fst_ket - 1))
            local e_row = tonumber(line:sub(snd_bra + 1, snd_com - 1))
            local e_col = tonumber(line:sub(snd_com + 1, snd_ket - 1))
            local cmd = '<esc>'
              .. s_row + 1
              .. 'G0'
              .. s_col
              .. 'lv'
              .. e_row + 1
              .. 'G0'
              .. e_col - 1
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
