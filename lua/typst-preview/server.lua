-- Responsible for starting, stopping and communicating with the server
local fetch = require 'typst-preview.fetch'

local M = {}

function M.spawn(root, file, on_read)
  local server_handle, _ = vim.loop.spawn(
    fetch.get_bin_path() .. fetch.get_typst_bin_name(),
    { args = { '--root', root, file } }
  )
  local stdin = vim.loop.new_pipe()
  local stdout = vim.loop.new_pipe()
  local stderr = nil
  local websocat_handle, _ =
    vim.loop.spawn(fetch.get_bin_path() .. fetch.get_websocat_bin_name(), {
      stdio = { stdin, stdout, stderr },
    })
  if
    stdout == nil
    or stdin == nil
    or websocat_handle == nil
    or server_handle == nil
  then
    error "typst-preview can't create pipe or spawn!"
  end
  stdout:read_start(function(err, data)
    if err then
      error(err)
    else
      on_read(data)
    end
  end)

  return {
    close = function()
      websocat_handle:kill()
      server_handle:kill()
    end,
    write = function(data)
      stdin:write(data)
    end,
  }
end

return M
