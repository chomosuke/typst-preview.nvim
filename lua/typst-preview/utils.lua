local config = require "typst-preview.config"
local M = {}

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
  vim.defer_fn(function()
    local id = vim.api.nvim_create_augroup(name, {})
    for _, autocmd in ipairs(autocmds) do
      ---@diagnostic disable-next-line: inject-field
      autocmd.opts.group = id
      vim.api.nvim_create_autocmd(autocmd.event, autocmd.opts)
    end
  end, 0)
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

return M
