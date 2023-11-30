local utils = require 'typst-preview.utils'

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
    utils.notify(
      "typst-preview can't figure out your platform.\n"
        .. 'Please report this bug.\n'
        .. 'os_uname: '
        .. vim.inspect(vim.loop.os_uname()),
      vim.log.levels.ERROR
    )
  end

  return map[os][machine]
end

---Get name of typst-preview binary, this is also the name for the github asset to download.
---@return string name
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

---Get name of websocat binary, this is also the name for the github asset to download.
---@return string name
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

local function get_path(name)
  return utils.get_data_path() .. name
end

function M.up_to_date(name)
utils.file_exist(get_path(name))
end

local function download_bin(url, name, callback)
  local path = get_path(name)
  if M.uptodate(name) then
    print(
      name
        .. ' already up to date.'
        .. '\n'
    )
    callback()
    return
  end

  local stdin = nil
  local stdout = assert(vim.loop.new_pipe())
  local stderr = assert(vim.loop.new_pipe())
  -- TODO add wget support
  vim.loop.spawn('curl', {
    args = { '-L', url, '--create-dirs', '--output', path, '--progress-bar' },
    stdio = { stdin, stdout, stderr },
  }, function(code, _)
    if code ~= 0 then
      utils.notify(
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
      utils.print('Downloading ' .. name .. progress)
    end
  end
  stdout:read_start(read_progress)
  stderr:read_start(read_progress)
end

function M.bins_to_fetch()
  return {
    {
      url = 'https://github.com/Enter-tainer/typst-preview/releases/download/v0.9.0/'
        .. M.get_typst_bin_name(),
      name = M.get_typst_bin_name(),
    },
    {
      url = 'https://github.com/vi/websocat/releases/download/v1.12.0/'
        .. M.get_websocat_bin_name(),
      name = M.get_websocat_bin_name(),
    },
  }
end

---Download all binaries and other needed artifact to utils.get_data_path()
---@param callback function|nil
function M.fetch(callback)
  if callback == nil then
    callback = function() end
  end
  local function finish()
    print(
      'All binary downloaded to '
        .. utils.get_data_path()
        .. '\nYou may want to manually delete it if uninstalling typst-preview.nvim'
    )
    callback()
  end

  local function download_bins(bins, callback_)
    if #bins == 0 then
      callback_()
      return
    end
    local bin = table.remove(bins, 1)
    download_bin(bin.url, bin.name, function()
      download_bins(bins, finish)
    end)
  end

  download_bins(M.bins_to_fetch(), finish)
end

return M
