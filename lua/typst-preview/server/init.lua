local utils = require 'typst-preview.utils'
local inventory = require 'typst-preview.server.inventory'
local M = {}

---@class (exact) Server
---@field path string Unsaved buffer will not be previewable.
---@field link string
---@field suppress boolean Prevent server initiated event to trigger editor initiated events.
---@field close fun()
---@field write fun(data: string)
---@field listenerss { [string]: fun(event: table)[] }

---Init or retrieve a server base on the path of main file
---@param path string
---@param callback fun(server: Server)
function M.get_or_init(path, callback)
  inventory.get_or_init(path, callback)
end

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
    filepath = vim.api.nvim_buf_get_name(0),
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
