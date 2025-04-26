local utils = require 'typst-preview.utils'
local config = require 'typst-preview.config'
local base = require 'typst-preview.servers.base'

-- Responsible for starting, stopping and communicating with the server
local M = {}

---@param command string
---@param arguments
---@param callback? fun(err: string, result)
local function exec_cmd(client, command, arguments, callback)
  local status, request_id = client:request(
    "workspace/executeCommand",
    {
      command = command,
      arguments = arguments,
    },
    ---@type lsp.Handler
    function(err, result, ctx)
      if err ~= nil then
        utils.debug(
          "Failed to send " .. command .. " command (error in response): "
          .. vim.inspect(err)
        )
        return
      end

      if callback ~= nil then
        callback(err and err.message, result)
      end
    end
  )

  if not status then
    utils.debug("Failed to send " .. command .. " command (error on request)")
    if callback ~= nil then
      callback("failed to send command", {})
    end
  end
end



---Spawn the server and connect to it using the websocat process
---@param path string
---@param mode mode
---@param callback fun(client: lsp.Client, task_id: string, link: string)
---Called after server spawn completes
local function spawn(path, port, mode, callback)
  local client = vim.lsp.get_clients({ name = 'tinymist', buffer = 0 })[1]
  if not client then
    return vim.notify(
      'No Tinymist client attached to the current buffer',
      vim.log.levels.ERROR
    )
  end
  
  local task_id = utils.random_id(12)

  local args = {
    '--invert-colors',
    config.opts.invert_colors,
    '--preview-mode',
    mode,
    '--no-open',
    '--task-id',
    task_id,
    '--data-plane-host',
    '127.0.0.1:' .. port,
    '--root',
    config.opts.get_root(path),
  }

  if config.opts.extra_args ~= nil then
    for _, v in ipairs(config.opts.extra_args) do
      table.insert(args, v)
    end
  end

  table.insert(args, config.opts.get_main_file(path))

  utils.debug("Starting preview with arguments: " .. table.concat(args, " "))

  exec_cmd(client, 'tinymist.doStartPreview', {args}, function(err, result)
    -- FIXME: Handle the AddrInUse case
    -- -> actually, this currently crashed tinymist on an unwrap(), thus
    -- reasonably handling this case requires an upstream change (such that
    -- tinymist returns an error instead of crashing)
    -- cf. https://github.com/Myriad-Dreamin/tinymist/issues/1699
    -- also test with next tinymist release, the respective code has been comletely refactored
    if err ~= nil then
      -- FIXME: better communicate this to the user
      utils.debug("Failed to start preview: " .. err)
      return
    end

    callback(client, task_id, result and result.staticServerAddr)
  end)
end

---create a new Server
---@param path string
---@param mode mode
---@param callback fun(server: Server)
function M.new(path, mode, callback)
  spawn(path, config.opts.port, mode, function(client, task_id, link)
    link = assert(link)
    local server = base.new_server(path, mode, link)

    function server.close()
      exec_cmd(client, 'tinymist.doKillPreview', {task_id})
    end

    function server.scroll_to(data)
      exec_cmd(client, 'tinymist.scrollPreview', {task_id, data})
    end

    -- FIXME: Move to top-level commands
    utils.visit(link)

    callback(server)
  end)
end

return M

