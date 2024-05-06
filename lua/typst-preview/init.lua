local config = require 'typst-preview.config'
local fetch = require 'typst-preview.fetch'

local M = {
  setup = config.config,
  set_follow_cursor = config.set_follow_cursor,
  get_follow_cursor = config.get_follow_cursor,
  sync_with_cursor = config.sync_with_cursor,
  update = function()
    fetch.fetch()
  end,
}

return M
