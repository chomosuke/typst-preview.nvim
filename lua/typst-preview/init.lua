local config = require 'typst-preview.config'
local autocmds = require 'typst-preview.events.autocmds'
local fetch = require 'typst-preview.fetch'
local utils = require 'typst-preview.utils'

local M = {
  setup = config.config,
  set_follow_cursor = autocmds.set_follow_cursor,
  get_follow_cursor = autocmds.get_follow_cursor,
  sync_with_cursor = autocmds.sync_with_cursor,
  update =  function()
    if config.opts.executable then
        utils.debug(string.format("Executable '%s' has been provided, please update manually.",config.opts.executable))
        return
    end
    fetch.fetch()
  end,
}

return M
