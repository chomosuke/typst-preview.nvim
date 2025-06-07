local utils = require 'typst-preview.utils'
local config = require 'typst-preview.config'

-- Tinymist API types

---@class PreviewResult
---@field staticServerAddr string|nil
---@field staticServerPort number|nil
---@field dataPlanePort number|nil
---@field isPrimary boolean|nil

---@class JumpInfo
---@field filepath string
---@field start number[] | nil
---@field end number[] | nil

-- PreviewTask and related types

---@alias mode 'document'|'slide'

-- Responsible for starting, stopping and communicating with the server
---@class (exact) PreviewTask
---@field __index table
---@field path string Unsaved buffer will not be previewable.
---@field mode mode
---@field task_id string
---@field link string?
---@field client vim.lsp.Client?
---@field suppress boolean Prevent server initiated event to trigger editor initiated events.
---@field close fun(self)
local PreviewTask = {}

---@alias ServerEvent 'crash'|'dispose'|'link-set'

---@param self PreviewTask
---@param command string
---@param arguments table
---@param err_callback? fun(err: string?)
---@param result_callback? fun(result: table)
function exec_cmd(
  self,
  command,
  arguments,
  err_callback,
  result_callback
)
  utils.debug("Sending command to server: ", command, ", arguments = ", arguments)

  local status, request_id = assert(self.client):request(
    "workspace/executeCommand",
    {
      command = command,
      arguments = arguments,
    },
    ---@type lsp.Handler
    function(err, result, ctx)
      if err ~= nil then
        utils.debug("Failed to send ", command, " command (error in response): ", err)

      if err_callback ~= nil then
        err_callback(err and err.message)
      end
      else
        if result_callback ~= nil then
          result_callback(result)
        end
      end
    end
  )

  if not status then
    utils.debug("Failed to send " .. command .. " command (error on request)")
    if err_callback ~= nil then
      err_callback("failed to send command")
    end
  end
end



---create a new PreviewTask
---@param path string
---@param mode mode
---@return PreviewTask
function PreviewTask:new(path, mode)
  local obj = {
    path = path,
    mode = mode,
    task_id = utils.random_id(12),
    link = nil,
    client = nil,
    suppress = false,
  }
  setmetatable(obj, self)
  self.__index = self
  return obj
end

---@param on_error fun(string)
---@param on_link_set fun(PreviewTask)
function PreviewTask:spawn(on_error, on_link_set)
  self.client = vim.lsp.get_clients({ name = 'tinymist', buffer = 0 })[1]
  if not self.client then
    utils.notify(
      'No Tinymist client attached to the current buffer',
      vim.log.levels.ERROR
    )
    on_error(self)
    return
  end

  local args = {
    '--invert-colors',
    config.opts.invert_colors,
    '--preview-mode',
    self.mode,
    '--no-open',
    '--task-id',
    self.task_id,
    '--data-plane-host',
    '127.0.0.1:' .. config.opts.port,
    '--root',
    config.opts.get_root(self.path),
  }

  if config.opts.extra_args ~= nil then
    for _, v in ipairs(config.opts.extra_args) do
      table.insert(args, v)
    end
  end

  table.insert(args, config.opts.get_main_file(self.path))

  utils.debug("Starting preview with arguments: ", args)

  exec_cmd(self, 'tinymist.doStartPreview', {args},
    function(err)
      -- FIXME: Handle the AddrInUse case
      -- -> actually, this currently crashes tinymist on an unwrap(), thus
      -- reasonably handling this case requires an upstream change (such that
      -- tinymist returns an error instead of crashing)
      -- cf. https://github.com/Myriad-Dreamin/tinymist/issues/1699
      -- also test with next tinymist release, the respective code has been comletely refactored
      -- FIXME: better communicate this to the user
      utils.debug("Failed to start preview: ", err)
      on_error(self)
    end,
    function(result)
      self.link = (result and result.staticServerAddr)
      on_link_set(self)
    end
)
end

-- FIXME: handle server events
-- delayed startup fail/crash
-- server-side close
function PreviewTask:subscribe(event, handler)
end

function PreviewTask:close()
  exec_cmd(self, 'tinymist.doKillPreview', {self.task_id})
end

---@param filepath string
---@param line number
---@param character number
function PreviewTask:scroll_to(filepath, line, character)
  exec_cmd(
    self,
    'tinymist.scrollPreview',
    {
      self.task_id,
      {
        event = 'panelScrollTo',
        filepath = filepath,
        line = line,
        character = character,
      }
    }
  )
end

---@class(exact) TaskFilter
---@field path? string -- the main file for the preview task
---@field mode? mode -- the mode that the preview uses
---@field task_id? string -- the random task id
---@field client? vim.lsp.Client -- the language server client that the preview was launched on

---@param self PreviewTask
---@param filter TaskFilter
---@return boolean
function PreviewTask:matches(filter)
  for k, v in pairs(filter) do
    if self[k] ~= v then
      return false
    end
  end
  return true
end

return PreviewTask

