local server = require 'typst-preview.server'
local utils = require 'typst-preview.utils'
local json = require 'typst-preview.json'

-- Both event from the editor and the previewer
local M = {}

---Call close[bufnr]() to close preview for bufnr
local close = {}

local on_changes = {}

local function watch_buf_change(bufnr)
  utils.create_autocmds('typst-preview-autocmds-on-change-' .. bufnr, {
    {
      event = { 'TextChanged', 'TextChangedI' },
      opts = {
        callback = function()
          for _, on_change in pairs(on_changes) do
            on_change(bufnr)
          end
        end,
        buffer = bufnr,
      },
    },
  })
end

utils.create_autocmds('typst-preview-autocmds-filetype-init', {
  {
    event = 'FileType',
    opts = {
      callback = function(ev)
        watch_buf_change(ev.buf)
      end,
      pattern = 'typst',
    },
  },
})

for _, bufnr in pairs(vim.api.nvim_list_bufs()) do
  if vim.bo[bufnr].filetype == 'typst' then
    watch_buf_change(bufnr)
  end
end

---Do all work necessary to start a preview for a buffer.
---@param bufnr integer
---@param set_link function
function M.watch(bufnr, set_link)
  utils.debug('Watching buffer: ' .. bufnr)

  if bufnr == 0 then
    bufnr = vim.fn.bufnr()
  end

  local buf_path = server.get_buffer_path(bufnr)
  server.spawn(bufnr, function(close_server, write, read_start)
    local function on_change(changed_bufnr)
      utils.debug('updating buffer: ' .. changed_bufnr)
      write(json.encode {
        event = 'updateMemoryFiles',
        files = {
          [utils.get_buf_path(changed_bufnr)] = utils.get_buf_content(
            changed_bufnr
          ),
        },
      } .. '\n')
    end

    -- So that moving cursor for editorScrollTo does generate panelScrollTo events
    local suppress_on_scroll = false
    local last_line
    local function on_editor_scroll(ev)
      if suppress_on_scroll then
        return
      end
      utils.debug('scrolling: ' .. bufnr)
      local cursor = vim.api.nvim_win_get_cursor(0)
      local line = cursor[1] - 1
      if last_line ~= line or ev.event ~= 'CursorMovedI' then
        -- No scroll when on the same line in insert mode
        last_line = line
        write(json.encode {
          event = 'panelScrollTo',
          filepath = buf_path,
          line = line,
          character = cursor[2],
        } .. '\n')
      end
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
            local cmd = '<esc>' .. event.start[1] + 1 .. 'G0'
            if event.start[2] > 0 then
              cmd = cmd .. event.start[2] .. 'l'
            end
            cmd = cmd .. 'v' .. event['end'][1] + 1 .. 'G0'
            if event['end'][2] - 1 > 0 then
              cmd = cmd .. event['end'][2] - 1 .. 'l'
            end

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

    on_changes[bufnr] = on_change
    utils.create_autocmds('typst-preview-autocmds-' .. bufnr, {
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
  end, set_link)
end

function M.stop(bufnr)
  utils.debug 'Server closed'
  close[bufnr]()
  on_changes[bufnr] = nil
end

return M
