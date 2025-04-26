local servers = require 'typst-preview.servers'
local utils = require 'typst-preview.utils'

local M = {}

---@param jump OnEditorJumpData
function M.on_editor_scroll_to(jump)
  local function editorScrollTo()
    -- FIXME: What was the original reasoning for this throttling? Is it still
    -- needed? How to best implement for LSP?
    -- s.suppress = true
    local row = jump.end_.row + 1
    local max_row = vim.fn.line '$'
    if row < 1 then
      row = 1
    end
    if row > max_row then
      row = max_row
    end
    local column = jump.end_.column - 1
    local max_column = vim.fn.col '$' - 1
    if column < 0 then
      column = 0
    end
    if column > max_column then
      column = max_column
    end
    vim.api.nvim_win_set_cursor(0, { row, column })
    -- vim.defer_fn(function()
    --   s.suppress = false
    -- end, 100)
  end

  if jump.filepath ~= utils.get_buf_path(0) then
    vim.cmd('e ' .. jump.filepath)
    vim.defer_fn(editorScrollTo, 100)
  else
    editorScrollTo()
  end
end

return M
