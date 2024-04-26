---@class Comm
---@field close function
---@field write function
---@field listeners function[]

local M = {
  ---@type Comm[]
  comms = {},
}

---@return Comm comm
function M.new(close_server, write, read_start)
  local comm = { close = close_server, write = write, listeners = {} }
  read_start(function(data)
    vim.defer_fn(function()
      while data:len() > 0 do
        local s, _ = data:find '\n'
        local event = assert(vim.fn.json_decode(data:sub(1, s - 1)))
        data = data:sub(s + 1, -1)
        local listener = comm.listeners[event.event]
        if listener then
          listener(event)
        end
      end
    end, 0)
  end)

  return comm
end

function M.addListener(comm, event, listener)
  comm.listeners[event] = listener
end

return M
