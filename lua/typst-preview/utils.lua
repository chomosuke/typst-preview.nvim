local config = require 'typst-preview.config'
local M = {}

---check if the host system is windows
function M.is_windows()
  return vim.loop.os_uname().sysname == 'Windows_NT'
end

---check if the host system is macos
function M.is_macos()
  return vim.loop.os_uname().sysname == 'Darwin'
end

---check if the host system is linux
function M.is_linux()
  return vim.loop.os_uname().sysname == 'Linux'
end

---check if the host system is wsl
function M.is_wsl()
  return M.is_linux() and vim.loop.os_uname().release:lower():find 'microsoft'
end

-- Stolen from mason.nvim

---check if the host arch is x64
function M.is_x64()
  local machine = vim.loop.os_uname().machine
  return machine == 'x86_64' or machine == 'x64'
end

---check if the host arch is arm64
function M.is_arm64()
  local machine = vim.loop.os_uname().machine
  return machine == 'aarch64'
    or machine == 'aarch64_be'
    or machine == 'armv8b'
    or machine == 'armv8l'
    or machine == 'arm64'
end

local open_cmd
if M.is_macos() then
  open_cmd = 'open'
elseif M.is_windows() then
  open_cmd = 'explorer.exe'
elseif M.is_wsl() then
  open_cmd = '/mnt/c/Windows/explorer.exe'
else
  open_cmd = 'xdg-open'
end

---Open link in browser (platform agnostic)
---@param link string
function M.visit(link)
  local cmd = string.format('%s http://%s', open_cmd, link)
  M.debug('Opening preview with command: ' .. cmd)
  vim.fn.jobstart(cmd, {
    on_stderr = function(_, data)
      local msg = table.concat(data or {}, '\n')
      if msg ~= '' then
        print('typst-preview opening link failed: ' .. msg)
      end
    end,
  })
end

---check if a file exist
---@param path string
function M.file_exist(path)
  local f = io.open(path, 'r')
  if f ~= nil then
    io.close(f)
    return true
  else
    return false
  end
end

---Get the path to store all persistent datas
---@return string path
function M.get_data_path()
  return vim.fn.fnamemodify(vim.fn.stdpath 'data' .. '/typst-preview/', ':p')
end

---@class AutocmdOpts
---@field pattern? string[]|string
---@field buffer? integer
---@field desc? string
---@field callback? function|string
---@field command? string
---@field once? boolean
---@field nested? boolean

---create autocmds
---@param name string
---@param autocmds { event: string[]|string, opts: AutocmdOpts }[]
function M.create_autocmds(name, autocmds)
  local id = vim.api.nvim_create_augroup(name, {})
  for _, autocmd in ipairs(autocmds) do
    ---@diagnostic disable-next-line: inject-field
    autocmd.opts.group = id
    vim.api.nvim_create_autocmd(autocmd.event, autocmd.opts)
  end
end

---print that can be called anywhere
---@param data string
function M.print(data)
  vim.defer_fn(function()
    print(data)
  end, 0)
end

---print that only work when opts.debug = true
---@param data string
function M.debug(data)
  if config.opts.debug then
    M.print(data)
  end
end

---notify that can be called anywhere
---@param data string
---@param level integer|nil
function M.notify(data, level)
  vim.defer_fn(function()
    vim.notify(data, level)
  end, 0)
end

---get content of the buffer
---@param bufnr any
---@return string content
function M.get_buf_content(bufnr)
  return table.concat(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false), '\n')
end

---get content of the buffer
---@param bufnr any
---@return string path
function M.get_buf_path(bufnr)
  return vim.api.nvim_buf_get_name(bufnr)
end

return M
