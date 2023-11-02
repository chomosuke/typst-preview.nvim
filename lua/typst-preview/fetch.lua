-- Responsible for downloading all required binary.
-- Currently includes typst-preview and websocat

local M = {
  -- Exposing this so when platform detection fails user can manually set
  -- bin_name
  typst_bin_name = nil,
  websocat_bin_name = nil,
}

function M.is_windows()
  return vim.loop.os_uname().sysname == 'Windows_NT'
end

function M.is_macos()
  return vim.loop.os_uname().sysname == 'Darwin'
end

function M.is_linux()
  return vim.loop.os_uname().sysname == 'Linux'
end

-- Stolen from mason.nvim
function M.is_x64()
  local machine = vim.loop.os_uname().machine
  return machine == 'x86_64' or machine == 'x64'
end

function M.is_arm64()
  local machine = vim.loop.os_uname().machine
  return machine == 'aarch64'
    or machine == 'aarch64_be'
    or machine == 'armv8b'
    or machine == 'armv8l'
    or machine == 'arm64'
end

local function get_bin_name(map)
  local machine
  if M.is_x64() then
    machine = 'x64'
  elseif M.is_arm64() then
    machine = 'arm64'
  end
  local os
  if M.is_macos() then
    os = 'macos'
  elseif M.is_linux() then
    os = 'linux'
  elseif M.is_windows() then
    os = 'windows'
  end

  if os == nil or machine == nil or map[os][machine] == nil then
    vim.notify(
      "typst-preview can't figure out your platform.\n"
        .. 'Please report this bug.\n'
        .. 'os_uname: '
        .. vim.inspect(vim.loop.os_uname()),
      vim.log.levels.ERROR
    )
  end

  return map[os][machine]
end

function M.get_typst_bin_name()
  if M.typst_bin_name == nil then
    M.typst_bin_name = get_bin_name {
      macos = {
        arm64 = 'typst-preview-darwin-arm64',
        x64 = 'typst-preview-darwin-x64',
      },
      linux = {
        arm64 = 'typst-preview-linux-arm64',
        x64 = 'typst-preview-linux-x64',
      },
      windows = {
        arm64 = 'typst-preview-win32-arm64.exe',
        x64 = 'typst-preview-win32-x64.exe',
      },
    }
  end
  return M.typst_bin_name
end

function M.get_websocat_bin_name()
  if M.websocat_bin_name == nil then
    M.websocat_bin_name = get_bin_name {
      macos = {
        arm64 = 'websocat.aarch64-apple-darwin',
        x64 = 'websocat.x86_64-apple-darwin',
      },
      linux = {
        arm64 = 'websocat.aarch64-unknown-linux-musl',
        x64 = 'websocat.x86_64-unknown-linux-musl',
      },
      windows = {
        arm64 = 'websocat.x86_64-pc-windows-gnu.exe',
      },
    }
  end
  return M.websocat_bin_name
end

function M.get_bin_path()
  return vim.fn.fnamemodify(vim.fn.stdpath 'data' .. '/typst-preview/', ':p')
end

local function download_bin(url, name, callback)
  local path = M.get_bin_path() .. name
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
      vim.notify(
        'Downloading ' .. name .. ' binary failed, exit code: ' .. code
      )
    else
      if not M.is_windows() then
        -- Set executable permission
        vim.loop.spawn('chmod', { args = { '+x', path } }, callback)
      else
        callback()
      end
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
      print('Downloading ' .. name .. 'binary ' .. progress)
    end
  end
  stdout:read_start(read_progress)
  stderr:read_start(read_progress)
end

function M.fetch(callback)
  local function finish()
    print(
      'all binary downloaded to '
        .. M.get_bin_path()
        .. '\nYou may want to manually delete it if uninstalling typst-preview.nvim'
    )
    callback()
  end

  -- from https://docs.github.com/en/repositories/releasing-projects-on-github/linking-to-releases
  download_bin(
    'https://github.com/Enter-tainer/typst-preview/releases/latest/download/'
      .. M.get_typst_bin_name(),
    M.get_typst_bin_name(),
    function()
      download_bin(
        'https://github.com/Enter-tainer/typst-preview/releases/latest/download/'
          .. M.get_websocat_bin_name(),
        M.get_websocat_bin_name(),
        finish
      )
    end
  )
end

return M
