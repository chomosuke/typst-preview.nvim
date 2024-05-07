local utils = require 'typst-preview.utils'
local manager = require 'typst-preview.servers.manager'
local M = {
  get_last_mode = manager.get_last_mode,
  init = manager.init,
  get = manager.get,
  get_all = manager.get_all,
  remove = manager.remove,
  remove_all = manager.remove_all,
}

---@alias mode 'document'|'slide'

---@class (exact) Server
---@field path string Unsaved buffer will not be previewable.
---@field mode mode
---@field link string
---@field suppress boolean Prevent server initiated event to trigger editor initiated events.
---@field close fun()
---@field write fun(data: string)
---@field listenerss { [string]: fun(event: table)[] }

---Update a memory file.
---@param self Server
---@param path string
---@param content string
function M.update_memory_file(self, path, content)
  if self.suppress then
    return
  end
  utils.debug('updating file: ' .. path .. ', main path: ' .. self.path)
  self.write(vim.fn.json_encode {
    event = 'updateMemoryFiles',
    files = {
      [path] = content,
    },
  } .. '\n')
end

---Remove a memory file.
---@param self Server
---@param path string
function M.remove_memory_file(self, path)
  if self.suppress then
    return
  end
  utils.debug('removing file: ' .. path)
  self.write(vim.fn.json_encode {
    event = 'removeMemoryFiles',
    files = { path },
  })
end

---Scroll preview to where the cursor is.
---@param self Server
function M.sync_with_cursor(self)
  if self.suppress then
    return
  end
  local cursor = vim.api.nvim_win_get_cursor(0)
  local line = cursor[1] - 1
  utils.debug('scroll to line: ' .. line .. ', character: ' .. cursor[2])
  self.write(vim.fn.json_encode {
    event = 'panelScrollTo',
    filepath = utils.get_buf_path(0),
    line = line,
    character = cursor[2],
  } .. '\n')
end

---Add a listener for an event from the server
---@param self Server
---@param event string
---@param listener fun(event: table)
local function add_listener(self, event, listener)
  if self.listenerss[event] == nil then
    self.listenerss[event] = {}
  end
  table.insert(self.listenerss[event], listener)
end

---Listen to editorScrollTo event from the server
---@param self Server
---@param listener fun(event: { filepath: string, start: { row: integer, column: integer }, end_: { row: integer, column: integer } })
function M.listen_scroll(self, listener)
  add_listener(self, 'editorScrollTo', function(event)
    listener {
      filepath = event.filepath,
      start = {
        row = event.start[1],
        column = event.start[2],
      },
      end_ = {
        row = event['end'][1],
        column = event['end'][2],
      },
    }
  end)
end

return M
