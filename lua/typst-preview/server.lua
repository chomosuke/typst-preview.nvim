local fetch = require 'typst-preview.fetch'
local utils = require 'typst-preview.utils'
local config = require 'typst-preview.config'

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
---@param callback function Called after server spawn completes, parameter is
--(close, write, read_start)
---@param set_link function
function M.spawn(bufnr, callback, set_link)
  local file_path = M.get_buffer_path(bufnr)
  local server_stdout = assert(vim.loop.new_pipe())
  local server_stderr = assert(vim.loop.new_pipe())
  local server_handle, _ =
    assert(vim.loop.spawn(utils.get_data_path() .. fetch.get_typst_bin_name(), {
      args = {
        '--invert-colors',
        config.opts.invert_colors,
        '--no-open',
        '--data-plane-host',
        '127.0.0.1:0',
        '--control-plane-host',
        '127.0.0.1:0',
        '--static-file-host',
        '127.0.0.1:0',
        '--root',
        config.opts.get_root(bufnr),
        file_path,
      },
      stdio = { nil, server_stdout, server_stderr },
    }))

  local function connect(host)
    local stdin = assert(vim.loop.new_pipe())
    local stdout = assert(vim.loop.new_pipe())
    local stderr = assert(vim.loop.new_pipe())
    local addr = 'ws://' .. host .. '/'
    local websocat_handle, _ = assert(
      vim.loop.spawn(utils.get_data_path() .. fetch.get_websocat_bin_name(), {
        args = {
          '-B',
          '10000000',
          addr,
        },
        stdio = { stdin, stdout, stderr },
      })
    )
    utils.debug('websocat connecting to: ' .. addr)
    stderr:read_start(function(err, data)
      if err then
        error(err)
      elseif data then
        utils.debug('websocat error: ' .. data)
      end
    end)

    callback(function()
      websocat_handle:kill()
      server_handle:kill()
    end, function(data)
      stdin:write(data)
    end, function(on_read)
      stdout:read_start(function(err, data)
        if err then
          error(err)
        elseif data then
          utils.debug('websocat said: ' .. data)
          on_read(data)
        end
      end)
    end)
  end

  local connected = false
  local function find_host(server_output, prompt)
    local _, s = server_output:find(prompt)
    if s then
      local e, _ = (server_output .. '\n'):find('\n', s + 1)
      return server_output:sub(s + 1, e - 1):gsub('%s+', '')
    end
  end
  local function read_server(serr, server_output)
    if serr then
      error(serr)
    elseif server_output then
      local control_host =
        find_host(server_output, 'Control plane server listening on: ')
      local static_host =
        find_host(server_output, 'Static file server listening on: ')
      if control_host and not connected then
        utils.debug 'Connecting to server'
        connected = true
        connect(control_host)
      end
      if static_host then
        utils.debug 'Setting link'
        vim.defer_fn(function()
          utils.visit(static_host)
          set_link(static_host)
        end, 0)
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
