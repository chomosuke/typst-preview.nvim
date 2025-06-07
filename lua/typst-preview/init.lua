local config = require 'typst-preview.config'
local commands = require 'typst-preview.commands'

local M = {
  setup = function(opts)
    config.config(opts)
  end,
  set_follow_cursor = config.set_follow_cursor,
  get_follow_cursor = config.get_follow_cursor,
  sync_with_cursor = commands.sync_with_cursor,
  update = function()
    vim.notify(
      'typst-preview.update() is deprecated. '
      .. 'Note that the plugin has changed substantially and does not download tinymist anymore, but connects to the existing language server. Please update your configuration, cf. the documentation.',
      vim.log.levels.ERROR
    )
  end
}

return M
