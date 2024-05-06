local server = require 'typst-preview.events.server'
local M = {}

---Listen to Server's event
---All buffers are already watched via auto command
---@param s Server
function M.listen(s)
  server.add_listeners(s)
end

return M
