local fetch = require 'typst-preview.fetch'
local utils = require 'typst-preview.utils'
local config= require 'typst-preview.config'

-- Responsible for starting, stopping and communicating with the server
local M = {}

---Source of truth for dummy file path
---@param bufnr integer
---@return string path
function M.get_buffer_path(bufnr)
  local path = vim.api.nvim_buf_get_name(bufnr)
  if path == '' then
    path = utils.get_data_path() .. 'dummy.typ'
    local f_handle, _ = assert(io.open(path, 'w'))
    f_handle:close() -- open a file in write mode to create an empty file.
  end
  return path
end

---Spawn the server and connect to it using the websocat process
---@param bufnr integer
---@param on_read function Called when server sends a message, parameter is a string
---@param callback function Called after server spawn completes, parameter is
--close and write function where calling close kills the processes and calling
--write write to the server
function M.spawn(bufnr, on_read, callback)
  local file_path = M.get_buffer_path(bufnr)
  local server_stdout = assert(vim.loop.new_pipe())
  local server_stderr = assert(vim.loop.new_pipe())
  local server_handle, _ =
    assert(vim.loop.spawn(utils.get_data_path() .. fetch.get_typst_bin_name(), {
      args = { '--root', config.opts.get_root(bufnr), file_path },
      stdio = { nil, server_stdout, server_stderr },
    }))

  local function connect(host)
    local stdin = assert(vim.loop.new_pipe())
    local stdout = assert(vim.loop.new_pipe())
    local stderr = assert(vim.loop.new_pipe())
    local addr = 'ws://' .. host .. '/'
    local websocat_handle, _ = assert(
      vim.loop.spawn(utils.get_data_path() .. fetch.get_websocat_bin_name(), {
        args = { addr },
        stdio = { stdin, stdout, stderr },
      })
    )
    utils.debug('websocat connecting to: ' .. addr)
    stdout:read_start(function(err, data)
      if err then
        error(err)
      elseif data then
        utils.debug('websocat said: ' .. data)
        on_read(data)
      end
    end)
    stderr:read_start(function(err, data)
      if err then
        error(err)
      elseif data then
        utils.debug('websocat said: ' .. data)
      end
    end)

    callback(function()
      websocat_handle:kill()
      server_handle:kill()
    end, function(data)
      stdin:write(data)
    end)
  end

  local connected = false
  local function read_server(serr, server_output)
    if serr then
      error(serr)
    elseif server_output and not connected then
      local _, s = server_output:find 'Control plane server listening on: '
      if s then
        utils.debug 'Connecting to server'
        connected = true
        local e, _ = (server_output .. '\n'):find('\n', s + 1)
        connect(server_output:sub(s + 1, e - 1):gsub('%s+', ''))
      end
    end
    if server_output then
      utils.debug(server_output)
    end
  end
  server_stdout:read_start(read_server)
  server_stderr:read_start(read_server)
end

return M
