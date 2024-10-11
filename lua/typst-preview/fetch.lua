local utils = require 'typst-preview.utils'
local config = require 'typst-preview.config'

-- Responsible for downloading all required binary.
-- Currently includes typst-preview and websocat
local M = {
  -- Exposing this so when platform detection fails user can manually set
  -- bin_name
  typst_bin_name = nil,
  websocat_bin_name = nil,
}

local function get_bin_name(map)
  local machine
  if utils.is_x64() then
    machine = 'x64'
  elseif utils.is_arm64() then
    machine = 'arm64'
  end
  local os
  if utils.is_macos() then
    os = 'macos'
  elseif utils.is_linux() then
    os = 'linux'
  elseif utils.is_windows() then
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
        arm64 = 'tinymist-darwin-arm64',
        x64 = 'tinymist-darwin-x64',
      },
      linux = {
        arm64 = 'tinymist-linux-arm64',
        x64 = 'tinymist-linux-x64',
      },
      windows = {
        arm64 = 'tinymist-win32-arm64.exe',
        x64 = 'tinymist-win32-x64.exe',
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
        x64 = 'websocat.x86_64-pc-windows-gnu.exe',
      },
    }
  end
  return M.websocat_bin_name
end

local function get_path(name)
  return utils.get_data_path() .. name
end

local record_path = utils.get_data_path() .. 'version_record.txt'

---@param bin {name: string, bin_name:string, url: string}
function M.up_to_date(bin)
  local record = io.open(record_path, 'r')
  if record ~= nil then
    for line in record:lines() do
      if bin.url == line then
        return utils.file_exist(get_path(bin.bin_name))
      end
    end
    record:close()
  end
  return false
end

local function download_bin(bin, callback)
  local path = get_path(bin.bin_name)
  if config.opts.dependencies_bin[bin.name] then
    print(
      "Binary for '"
        .. bin.name
        .. "' has been provided in config.\n"
        .. 'Please ensure manually that it is up to date.\n'
    )
    callback()
    return
  end
  if M.up_to_date(bin) then
    print(bin.name .. ' already up to date.' .. '\n')
    callback()
    return
  end

  local name = bin.name
  local url = bin.url

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
      if not utils.is_windows() then
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
      url = 'https://github.com/Myriad-Dreamin/tinymist/releases/download/v0.11.32/'
        .. M.get_typst_bin_name(),
      bin_name = M.get_typst_bin_name(),
      name = 'tinymist',
    },
    {
      url = 'https://github.com/vi/websocat/releases/download/v1.12.0/'
        .. M.get_websocat_bin_name(),
      bin_name = M.get_websocat_bin_name(),
      name = 'websocat',
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
      'All binaries required by typst-preview downloaded to '
        .. utils.get_data_path()
    )
    local record, err = io.open(record_path, 'w')
    if record == nil then
      error("Can't open record file!: " .. err)
    end
    for _, bin in pairs(M.bins_to_fetch()) do
      record:write(bin.url .. '\n')
    end
    record:close()
    callback()
  end

  local function download_bins(bins, callback_)
    if #bins == 0 then
      callback_()
      return
    end
    local bin = table.remove(bins, 1)
    download_bin(bin, function()
      download_bins(bins, finish)
    end)
  end

  download_bins(M.bins_to_fetch(), finish)
end

return M
