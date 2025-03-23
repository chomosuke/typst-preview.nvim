local fetch = require 'typst-preview.fetch'
local utils = require 'typst-preview.utils'
local config = require 'typst-preview.config'

-- Responsible for starting, stopping and communicating with the server
local M = {}

---Spawn the server and connect to it using the websocat process
---@param path string
---@param mode mode
---@param callback fun(close: fun(), write: fun(data: string), read: fun(on_read: fun(data: string)), link: string)
---Called after server spawn completes
local function spawn(path, port, mode, callback)
  local server_stdout = assert(vim.uv.new_pipe())
  local server_stderr = assert(vim.uv.new_pipe())
  local tinymist_bin = config.opts.dependencies_bin['tinymist']
      or (utils.get_data_path() .. fetch.get_tinymist_bin_name())
  local args = {
    'preview',
    '--invert-colors',
    config.opts.invert_colors,
    '--preview-mode',
    mode,
    '--no-open',
    '--data-plane-host',
    '127.0.0.1:0',
    '--control-plane-host',
    '127.0.0.1:0',
    '--static-file-host',
    '127.0.0.1:' .. port,
    '--root',
    config.opts.get_root(path),
  }

  if config.opts.partial_rendering then
    table.insert(args, '--partial-rendering')
  end

  if config.opts.extra_args ~= nil then
    for _, v in ipairs(config.opts.extra_args) do
      table.insert(args, v)
    end
  end

  table.insert(args, config.opts.get_main_file(path))

  local server_handle, _ = assert(vim.uv.spawn(tinymist_bin, {
    args = args,
    stdio = { nil, server_stdout, server_stderr },
  }))
  utils.debug('spawning server ' .. tinymist_bin .. ' with args:')
  utils.debug(vim.inspect(args))

  -- This will be gradually filled util it's ready to be fed to callback
  -- Refactor if there's a third place callback would be called.
  ---@type { close: fun(), write: fun(data: string), read: fun(on_read: fun(data: string)) } | string | nil
  local callback_param = nil

  local function connect(host)
    local stdin = assert(vim.uv.new_pipe())
    local stdout = assert(vim.uv.new_pipe())
    local stderr = assert(vim.uv.new_pipe())
    local addr = 'ws://' .. host .. '/'
    local websocat_bin = config.opts.dependencies_bin['websocat']
        or (utils.get_data_path() .. fetch.get_websocat_bin_name())
    local websocat_handle, _ = assert(vim.uv.spawn(websocat_bin, {
      args = {
        '-B',
        '10000000',
        '--origin',
        'http://localhost',
        addr,
      },
      stdio = { stdin, stdout, stderr },
    }))
    utils.debug('websocat connecting to: ' .. addr)
    stderr:read_start(function(err, data)
      if err then
        error(err)
      elseif data then
        utils.debug('websocat error: ' .. data)
      end
    end)

    local param = {
      close = function()
        websocat_handle:kill()
        server_handle:kill()
      end,
      write = function(data)
        stdin:write(data)
      end,
      read = function(on_read)
        stdout:read_start(function(err, data)
          if err then
            error(err)
          elseif data then
            utils.debug('websocat said: ' .. data)
            on_read(data)
          end
        end)
      end,
    }
    if callback_param ~= nil then
      assert(type(callback_param) == 'string', "callback_param isn't a string")
      callback(param.close, param.write, param.read, callback_param)
    else
      callback_param = param
    end
  end

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
    end

    if not server_output then
      return
    end

    if server_output:find 'AddrInUse' then
      print('Port ' .. port .. ' is already in use')
      server_stdout:close()
      server_stderr:close()
      -- try again at port + 1
      vim.defer_fn(function()
        spawn(path, port + 1, mode, callback)
      end, 0)
    end
    local control_host = find_host(
      server_output,
      'Control plane server listening on: '
    ) or find_host(server_output, 'Control panel server listening on: ')
    local static_host =
        find_host(server_output, 'Static file server listening on: ')
    if control_host then
      utils.debug 'Connecting to server'
      connect(control_host)
    end
    if static_host then
      utils.debug 'Setting link'
      vim.defer_fn(function()
        utils.visit(static_host)
        if callback_param ~= nil then
          assert(
            type(callback_param.close) == 'function'
            and type(callback_param.write) == 'function'
            and type(callback_param.read) == 'function',
            "callback_param's type isn't a table of functions"
          )
          callback(
            callback_param.close,
            callback_param.write,
            callback_param.read,
            static_host
          )
        else
          callback_param = static_host
        end
      end, 0)
    end
    utils.debug(server_output)
  end

  server_stdout:read_start(read_server)
  server_stderr:read_start(read_server)
end

---create a new Server
---@param path string
---@param mode mode
---@param callback fun(server: Server)
function M.new(path, mode, callback)
  local read_buffer = ''

  spawn(path, config.opts.port, mode, function(close, write, read, link)
    ---@type Server
    local server = {
      path = path,
      mode = mode,
      link = link,
      suppress = false,
      close = close,
      write = write,
      listenerss = {},
    }

    read(function(data)
      vim.defer_fn(function()
        read_buffer = read_buffer .. data
        local s, _ = read_buffer:find '\n'
        while s ~= nil do
          local event = assert(vim.json.decode(read_buffer:sub(1, s - 1)))

          -- Make sure we keep the next message in the read buffer
          read_buffer = read_buffer:sub(s + 1, -1)
          s, _ = read_buffer:find '\n'

          local listeners = server.listenerss[event.event]
          if listeners ~= nil then
            for _, listener in pairs(listeners) do
              listener(event)
            end
          end
        end

        if read_buffer ~= '' then
          utils.debug('Leaving for next read: ' .. read_buffer)
        end
      end, 0)
    end)

    callback(server)
  end)
end

return M
