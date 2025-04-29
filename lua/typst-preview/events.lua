local config = require 'typst-preview.config'
local manager = require 'typst-preview.manager'
local utils = require 'typst-preview.utils'

---Whether lsp handlers have been registered
local lsp_handlers_registerd = false

local M = {}

---@param method string
---@param handler fun(result)
local function register_lsp_handler(method, handler)
  vim.lsp.handlers[method] = function(err, result, ctx)
    utils.debug(
      "Received event from server: ",
      ctx.method,
      ", err = ",
      err,
      ", result = ",
      result
    )

    if err ~= nil then
      return
    end

    handler(result)
  end ---@type lsp.Handler
end

function M.ensure_registered()
  if lsp_handlers_registerd then
    return
  end

  local id = vim.api.nvim_create_augroup('typst-preview-autocmds', {})
  vim.api.nvim_create_autocmd('LspDetach', {
    group = id,
    callback = function(ev)
      manager.remove(
        { client = ev.data.client },
        'server detached'
      )
    end
  })

  vim.api.nvim_create_autocmd('CursorMoved', {
    pattern = '*.typ',
    callback = function(ev)
      utils.debug("received CursorMoved in file ", ev.file)
      if config.get_follow_cursor() then
        manager.scroll_preview()
      end
    end
  })

  register_lsp_handler('tinymist/preview/dispose', function(result)
    local task_id = result['taskId']

    manager.remove(
      { task_id = task_id },
      'received dispose from server'
    )
  end)

  -- Note that tinymist does not seem to send this event: Instead, it uses
  -- 'window/showDocument', which is already handled appropriately by neovim.
  -- -> there is a config option, customizedShowDocument to control which
  -- notification is sent
  -- cf. https://github.com/Myriad-Dreamin/tinymist/pull/1450
  -- -> requires tinymist v0.13.10
  -- This does imply that we send a panelScrollTo in response to showDocument,
  -- but that doesn't seem to result in a loop, luckily
  -- register_lsp_handler('tinymist/preview/scrollSource', function(result)
  --   ---@type JumpInfo
  --   local jump = assert(result)
  --
  --   on_editor_scroll_to(jump)
  -- end)

  -- Don't even register the listener: This notification is sent quite often,
  -- and we don't use it right now.
  -- register_lsp_handler('tinymist/documentOutline', function(result)
  --   -- ignore
  -- end)

  lsp_handlers_registerd = true
end

return M
