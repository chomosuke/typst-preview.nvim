local config = require 'typst-preview.config'
local fetch = require 'typst-preview.fetch'
local commands = require 'typst-preview.commands'

local M = {
  setup = config.config,
  set_follow_cursor = config.set_follow_cursor,
  get_follow_cursor = config.get_follow_cursor,
  sync_with_cursor = commands.sync_with_cursor,
  update = function()
    fetch.fetch(nil)
  end,
}

return M
