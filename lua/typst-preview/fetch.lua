local M = {
  bin_name = nil,
}

function M.get_bin_name()
  local os_uname = vim.loop.os_uname()
  local sysname = os_uname.sysname
  if M.bin_name == nil then
    local arch_aliases = { -- Stolen from mason.nvim
      ['x86_64'] = 'x64',
      ['i386'] = 'ia32',
      ['i686'] = 'ia32', -- x86 compat
      ['aarch64'] = 'arm64',
      ['aarch64_be'] = 'arm64',
      ['armv8b'] = 'arm64', -- arm64 compat
      ['armv8l'] = 'arm64', -- arm64 compat
    }
    local machine = arch_aliases[os_uname.machine] or os_uname.machine

    if sysname == 'Darwin' then
      M.bin_name = 'typst-preview-darwin-' .. machine
    elseif sysname == 'Linux' then
      M.bin_name = 'typst-preview-linux-' .. machine
    elseif sysname == 'Windows_NT' then
      M.bin_name = 'typst-preview-win32-' .. machine .. '.exe'
    end

    if M.bin_name == nil then
      vim.notify(
        "typst-preview can't figure out your OS / system architecture!\n"
          .. 'Please report this bug.\n'
          .. 'os_uname: '
          .. vim.inspect(os_uname),
        vim.log.levels.ERROR
      )
    end
  end
  return M.bin_name
end

function M.get_bin_path()
  return vim.fn.fnamemodify(vim.fn.stdpath 'data' .. '/typst-preview/', ':p')
    .. M.get_bin_name()
end

function M.fetch(callback)
  -- from https://docs.github.com/en/repositories/releasing-projects-on-github/linking-to-releases
  local url = 'https://github.com/Enter-tainer/typst-preview/releases/latest/download/'
    .. M.get_bin_name()
  local path = M.get_bin_path()

  local stdin = nil
  local stdout = vim.loop.new_pipe()
  local stderr = vim.loop.new_pipe()
  if stdout == nil or stderr == nil then
    error "typst-preview can't create pipe!"
  end
  -- TODO add wget support
  vim.loop.spawn('curl', {
    args = { '-L', url, '--create-dirs', '--output', path, '--progress-bar' },
    stdio = { stdin, stdout, stderr },
  }, function(code, _)
    if code ~= 0 then
      vim.notify('Downloading typst-preview binary failed, exit code: ' .. code)
    else
      print(
        'typst-preview binary downloaded to '
          .. path
          .. '\nYou may want to manually delete it if uninstalling typst-preview.nvim'
      )
      callback()
    end
  end)
  local function read_progress(err, data)
    if err then
      error(err)
    elseif data then
      local progress = data:sub(-6, data:len())
      while progress:len() < 6 do
        progress = ' ' .. progress
      end
      print('Downloading typst-preview binary ' .. progress)
    end
  end
  stdout:read_start(read_progress)
  stderr:read_start(read_progress)
end

return M
