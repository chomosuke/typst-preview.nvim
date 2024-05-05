local server = require 'typst-preview.server'
local utils = require 'typst-preview.utils'

local M = {}

---Do all work necessary to start a preview for a buffer.
---@param s Server
function M.watch(s)
  utils.debug('Watching buffer: ' .. bufnr)

  server.spawn(bufnr, function(close_server, write, read_start)
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

      if event.filepath ~= utils.get_buf_path(0) then
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
