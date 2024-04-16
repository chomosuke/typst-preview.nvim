local server = require 'typst-preview.server'
local utils = require 'typst-preview.utils'
local communicator = require 'typst-preview.events.communicator'

-- Both event from the editor and the previewer
local M = {
  -- Just another ugly global variable
  -- So that moving cursor for editorScrollTo doesn't generate panelScrollTo events
  suppress_on_scroll = false,
}

---Do all work necessary to start a preview for a buffer.
---@param bufnr integer
---@param set_link function
function M.watch(bufnr, mode, set_link)
  utils.debug('Watching buffer: ' .. bufnr)

  if bufnr == 0 then
    bufnr = vim.fn.bufnr()
  end

  server.spawn(bufnr, mode, function(close_server, write, read_start)
    local comm = communicator.new(close_server, write, read_start)
    communicator.comms[bufnr] = comm

    communicator.addListener(comm, 'syncEditorChanges', function(_)
      comm.write(vim.fn.json_encode {
        event = 'syncMemoryFiles',
        files = {
          [server.get_buffer_path(bufnr)] = utils.get_buf_content(bufnr),
        },
      } .. '\n')
    end)

    communicator.addListener(comm, 'editorScrollTo', function(event)
      local function editorScrollTo()
        -- local cmd = '<esc>' .. event.start[1] + 1 .. 'G0'
        -- if event.start[2] > 0 then
        --   cmd = cmd .. event.start[2] .. 'l'
        -- end
        -- cmd = cmd .. 'v' .. event['end'][1] + 1 .. 'G0'
        -- if event['end'][2] - 1 > 0 then
        --   cmd = cmd .. event['end'][2] - 1 .. 'l'
        -- end

        utils.debug(event['end'][1] .. ' ' .. event['end'][2])
        M.suppress_on_scroll = true
        vim.api.nvim_win_set_cursor(
          0,
          { event['end'][1] + 1, event['end'][2] - 1 }
        )
        vim.defer_fn(function()
          M.suppress_on_scroll = false
        end, 100)
      end

      if event.filepath ~= vim.api.nvim_buf_get_name(0) then
        vim.cmd('e ' .. event.filepath)
        vim.defer_fn(editorScrollTo, 100)
      else
        editorScrollTo()
      end
    end)
  end, set_link)
end

function M.stop(bufnr)
  utils.debug 'Server closed'
  communicator.comms[bufnr].close()
end

return M
