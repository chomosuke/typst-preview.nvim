local factory = require 'typst-preview.server.factory'
local M = {}

---@type { [string]: Server }
local servers = {}

---Init or retrieve a server base on the path of main file
---@param path string
---@param callback fun(server: Server)
function M.get_or_init(path, callback)
  path = vim.fn.fnamemodify(path, ':p')
  if servers[path] == nil then
    factory.new(path, function(server)
      servers[path] = server
      callback(servers[path])
    end)
  else
    callback(servers[path])
  end
end

return M
