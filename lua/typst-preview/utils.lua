local config = require 'typst-preview.config'
local M = {}

---Open link in browser (platform agnostic)
---@param link string
function M.visit(link)
  local opts = {}
  if config.opts.open_cmd ~= nil then
    opts.cmd = {config.opts.open_cmd }
  end
  vim.ui.open('http://' .. link, opts)
end

---@param path string
---@return string
function M.abs_path(path)
  return vim.fn.fnamemodify(path, ':p')
end

---Get the path to store all persistent datas, creating it if necessary
---@return string path
local function get_data_path()
  local path = vim.fn.fnamemodify(vim.fn.stdpath 'data' .. '/typst-preview/', ':p')
  vim.fn.mkdir(path, 'p')
  return path
end

---@class AutocmdOpts
---@field pattern? string[]|string
---@field buffer? integer
---@field desc? string
---@field callback? function|string
---@field command? string
---@field once? boolean
---@field nested? boolean

---print that can be called anywhere
---@param data string
function M.print(data)
  vim.defer_fn(function()
    print(data)
  end, 0)
end

local file = nil

---write debug prints to a file when opts.debug = true, else do nothing
---
---Concatenates all arguments, converting them into a human-readable
---representation using vim.inspect.
---If an argument is a function, it will be called the corresponding part of
---the debug message lazily.
---@param ... string|number|nil|table|fun(): string
function M.debug(...)
  if config.opts.debug then
    local err
    if file == nil then
      file, err = io.open(get_data_path() .. 'log.txt', "a")
    end
    if file == nil then
      error("Can't open record file!: " .. err)
    end
    local msg = ""
    for k, v in pairs({...}) do
      local part
      if type(v) == "function" then
        part = v()
      else
        part = v
      end
      if type(part) ~= "string" then
        part = vim.inspect(part)
      end
      msg = msg .. part
    end
    file:write(msg .. '\n')
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

---get absolute path to the buffer's file, or nil if it is not saved
---@param bufnr? integer
---@return string?
function M.get_buf_path(bufnr)
  local path = vim.api.nvim_buf_get_name(bufnr or 0)
  if path == '' then
    return nil
  end
  return M.abs_path(path)
end

---@param bufnr? integer
---@return string?
function M.get_main_file(bufnr)
  local path = M.get_buf_path(bufnr or 0)
  return path and config.opts.get_main_file(path)
end

local id_chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890"

---get a random string to be used as a preview task id
---@param len number
---@return string
function M.random_id(len)
  local id = ""
  for _i=1,len do
    local idx = math.random(1, #id_chars)
    id = id .. id_chars:sub(idx, idx)
  end

  return id
end

return M
