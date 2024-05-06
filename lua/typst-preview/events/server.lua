local server = require 'typst-preview.server'
local utils = require 'typst-preview.utils'

local M = {}

---Register event listener
---@param s Server
function M.add_listeners(s)
  server.listen_scroll(s, function(event)
    local function editorScrollTo()
      utils.debug(event.end_.row .. ' ' .. event.end_.column)
      s.suppress = true
      vim.api.nvim_win_set_cursor(
        0,
        { event.end_.row + 1, event.end_.column - 1 }
      )
      vim.defer_fn(function()
        s.suppress = false
      end, 100)
    end

    if event.filepath ~= utils.get_buf_path(0) then
      vim.cmd('e ' .. event.filepath)
      vim.defer_fn(editorScrollTo, 100)
    else
      editorScrollTo()
    end
  end)
end

return M
