local base = require 'typst-preview.servers.base'
local config = require 'typst-preview.config'
local factory = require 'typst-preview.servers.factory'
local factory_lsp = require 'typst-preview.servers.factory-lsp'
local utils = require 'typst-preview.utils'
local M = {}

---All running servers
---@type Server[]
local servers = {}

---The last used preview mode by file path
---@type { [string]: mode }
local last_modes = {}

---Whether lsp handlers have been registered
local lsp_handlers_registerd = false

---Listeners
---@type fun(jump: OnEditorJumpData)[]
local editor_scroll_to_listeners = {}

function M.on_editor_scroll_to(jump)
  local start = jump.start
  local end_ = jump['end']
  if start == nil or end_ == nil then
    return
  end

  utils.debug('scroll editor to line: ' .. end_[1] .. ', character: ' .. end_[2])

  ---@type OnEditorJumpData
  local parsed_jump = {
    filepath = jump.filepath,
    start = {
      row = start[1],
      column = start[2],
    },
    end_ = {
      row = end_[1],
      column = end_[2],
    },
  }

  for _, listener in pairs(editor_scroll_to_listeners) do
    listener(parsed_jump)
  end
end

---Get last mode that init is called with
---@param path string
---@return mode?
function M.get_last_mode(path)
  path = utils.abs_path(path)
  return last_modes[path]
end

---@param method string
---@param handler fun(result)
local function register_lsp_handler(method, handler)
  vim.lsp.handlers[method] = function(err, result, ctx)
    utils.debug(
      "Received event from server: " .. ctx.method
      .. ", err = " .. vim.inspect(err)
      .. ", result = " .. vim.inspect(result)
    )

    if err ~= nil then
      return
    end

    handler(result)
  end ---@type lsp.Handler
end

local function init_lsp()
  if lsp_handlers_registerd then
    return
  end

  register_lsp_handler('tinymist/preview/dispose', function(result)
    local task_id = result[1]

    M.remove{task_id=task_id}
  end)

  register_lsp_handler('tinymist/preview/scrollSource', function(result)
    ---@type JumpInfo
    local jump = assert(result)

    M.on_editor_scroll_to(jump)
  end)

  register_lsp_handler('tinymist/documentOutline', function(result)
    -- ignore
  end)
end

---Init a server
---@param path string
---@param mode mode
---@param callback fun(server: Server)
function M.init(path, mode, callback)
  path = utils.abs_path(path)
  assert(
    next(M.get{path=path, mode=mode}) == nil,
    'Server with path ' .. path .. ' and mode ' .. mode .. ' already exists.'
  )

  local function handle_new_server(server)
    table.insert(servers, server)
    last_modes[path] = mode
    callback(server)
  end

  if config.opts.use_lsp then
    init_lsp()
    -- In the LSP case, all events are received by a global handler
    factory_lsp.new(path, mode, handle_new_server)
  else
    -- whereas in the subprocess + websocat case, each server receives events
    factory.new(path, mode, handle_new_server, {
      editorScrollTo = M.on_editor_scroll_to,
    })
  end
end

---Get a server
---@param filter ServerFilter
---@return { Server[] }?
function M.get(filter)
  filter.path = filter.path and utils.abs_path(filter.path)

  ---@type Server[]
  local result = {}
  for _, server in pairs(servers) do
    if base.server_matches(server, filter) then
      table.insert(result, server)
    end
  end

  return result
end

---Get all servers
---@return Server[]
function M.get_all()
  ---@type Server[]
  local r = {}
  for _, ser in pairs(servers) do
    table.insert(r, ser)
  end
  return r
end

---Remove all servers matching the filter and clean everything up
---@param filter ServerFilter
---@return boolean removed Whether at least one matching server existed before.
function M.remove(filter)
  filter.path = filter.path and utils.abs_path(filter.path)

  local removed = false
  for idx, server in pairs(servers) do
    if base.server_matches(server, filter) then
      servers[idx] = nil
      server.close()
      utils.debug(
        'Server with path ' .. server.path .. ' and mode ' .. server.mode .. ' closed.'
      )
      removed = true
    end
  end

  if not removed then
    utils.debug(
      'Attempt to remove non-existing server with filter: '
      .. vim.inspect(filter)
    )
  end

  return removed
end

---Remove all servers
function M.remove_all()
  M.remove{}
end

---@param path string
---@param content string
function M.update_memory_file(path, content)
  for _, server in pairs(servers) do
    if not server.suppress then
      server.update_memory_file(path, content)
    end
  end
end

---Scroll preview to where the cursor is.
function M.scroll_preview()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local line = cursor[1] - 1
  utils.debug('scroll to line: ' .. line .. ', character: ' .. cursor[2])

  for _, server in pairs(servers) do
    if not server.suppress then
      server.scroll_to {
        event = 'panelScrollTo',
        filepath = utils.get_buf_path(0),
        line = line,
        character = cursor[2],
      }
    end
  end
end

---Listen to editorScrollTo event from the server
---@param listener fun(event: OnEditorJumpData)
function M.listen_scroll(listener)
  table.insert(editor_scroll_to_listeners, listener)
end

return M
