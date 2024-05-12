local factory = require 'typst-preview.servers.factory'
local utils = require 'typst-preview.utils'
local M = {}

---There can not be `servers[path]` that's empty and not nil
---@type { [string]: { [mode]: Server } }
local servers = {}

---@type { [string]: mode }
local last_modes = {}

---Get last mode that init is called with
---@param path string
---@return mode?
function M.get_last_mode(path)
  return last_modes[path]
end

---@param path string
---@return string
local function abs_path(path)
  return vim.fn.fnamemodify(path, ':p')
end

---Init a server
---@param path string
---@param mode mode
---@param callback fun(server: Server)
function M.init(path, mode, callback)
  path = abs_path(path)
  assert(
    servers[path] == nil or servers[path][mode] == nil,
    'Server with path ' .. path .. ' and mode ' .. mode .. ' already exist.'
  )
  factory.new(path, mode, function(server)
    servers[path] = servers[path] or {}
    servers[path][mode] = server
    last_modes[path] = mode
    callback(servers[path][mode])
  end)
end

---Get a server
---@param path string
---@return { [mode]: Server }?
function M.get(path)
  path = abs_path(path)
  local ser = servers[path]
  assert(
    ser == nil or utils.length(ser) > 0,
    'servers[' .. path .. '] is empty and not nil.'
  )
  return ser
end

---Get all servers
---@return Server[]
function M.get_all()
  ---@type Server[]
  local r = {}
  for _, sers in pairs(servers) do
    for _, ser in pairs(sers) do
      table.insert(r, ser)
    end
  end
  return r
end

---Remove a server and clean everything up
---@param path string
---@return boolean removed Whether a server with the path existed before.
function M.remove(path)
  path = abs_path(path)
  local removed = false
  if servers[path] ~= nil then
    for mode, _ in pairs(servers[path]) do
      servers[path][mode].close()
      utils.debug(
        'Server with path ' .. path .. ' and mode ' .. mode .. ' closed.'
      )
      servers[path][mode] = nil
      removed = true
    end
    assert(removed, 'servers[' .. path .. '] is empty and not nil.')
    servers[path] = nil
  end
  return removed
end

---Remove all servers
function M.remove_all()
  for path, _ in pairs(servers) do
    M.remove(path)
  end
end

return M
