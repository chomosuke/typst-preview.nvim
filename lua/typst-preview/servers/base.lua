local M = {}

-- Tinymist API types

---@class PreviewResult
---@field staticServerAddr string|nil
---@field staticServerPort number|nil
---@field dataPlanePort number|nil
---@field isPrimary boolean|nil

---@class JumpInfo
---@field filepath string
---@field start number[] | nil
---@field end number[] | nil

-- Parsed JumpInfo

---@class Location
---@field row number
---@field column number

---@class OnEditorJumpData
---@field filepath string
---@field start Location
---@field end_ Location

-- Server and related types

---@alias mode 'document'|'slide'

---@class (exact) Server
---@field path string Unsaved buffer will not be previewable.
---@field mode mode
---@field link string
---@field suppress boolean Prevent server initiated event to trigger editor initiated events.
---@field close fun()
---@field scroll_to fun(data)
---@field update_memory_file fun(path: string, content: string)
---@field remove_memory_file fun(data: string)

function M.new_server(path, mode, link)
  return {
    path = path,
    mode = mode,
    link = link,
    suppress = false,
    close = function() end,
    scroll_to = function() end,
    update_memory_file = function() end,
    remove_memory_file = function() end,
  }
end

---@class(exact) ServerFilter
---@field path? string
---@field mode? mode
---@field task_id? string

---@param server Server
---@param filter ServerFilter
---@return boolean
function M.server_matches(server, filter)
  for k, v in pairs(filter) do
    if server[k] ~= v then
      return false
    end
  end
  return true
end

return M
