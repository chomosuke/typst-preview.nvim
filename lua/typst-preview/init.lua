local config = require 'typst-preview.config'
local autocmds = require 'typst-preview.events.autocmds'

local M = {
  setup = config.config,
  set_follow_cursor = autocmds.set_follow_cursor,
  get_follow_cursor = autocmds.get_follow_cursor,
  sync_with_cursor = autocmds.sync_with_cursor,
}

return M
