local config = require "typst-preview.config"
local commands = require "typst-preview.commands"

-- Implement all events.
local M = {}

function M.setup(opts)
  config.setup(opts)
  commands.create_commands()
end

return M
