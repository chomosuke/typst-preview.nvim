local factory = require 'typst-preview.servers.factory'
local utils = require 'typst-preview.utils'
local M = {}

---@type { [string]: Server }
local servers = {}

---@param path string
---@return string
local function abs_path(path)
  return vim.fn.fnamemodify(path, ':p')
end

---Init a server
---@param path string
---@param mode 'document'|'slide'
---@param callback fun(server: Server)
function M.init(path, mode, callback)
  path = abs_path(path)
  assert(
    servers[path] == nil or #servers[path] < 2,
    'Server with path ' .. path .. ' already exist'
  )
  factory.new(path, mode, function(server)
    servers[path] = server
    callback(servers[path])
  end)
end

---Get a server
---@param path string
---@return Server?
function M.get(path)
  path = abs_path(path)
  return servers[path]
end

---Get all servers
---@return Server[]
function M.get_all()
  local r = {}
  for _, server in pairs(servers) do
    table.insert(r, server)
  end
  return r
end

---Remove a server and clean everything up
---@param path string
---@return boolean removed Whether a server with the path existed before.
function M.remove(path)
  path = abs_path(path)
  if servers[path] ~= nil then
    servers[path].close()
    utils.debug('Server with path ' .. path .. ' closed.')
    servers[path] = nil
    return true
  else
    return false
  end
end

---Remove all servers
function M.remove_all()
  for path, _ in pairs(servers) do
    M.remove(path)
  end
  servers = {}
end

return M
