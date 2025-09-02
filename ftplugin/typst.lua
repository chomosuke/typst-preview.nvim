if vim.g.loaded_typst_preview_plugin then
	return
end
vim.g.loaded_typst_preview_plugin = true

require 'typst-preview.commands'.create_commands()
require 'typst-preview.events'.init()
