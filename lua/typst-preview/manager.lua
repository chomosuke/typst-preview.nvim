local config = require 'typst-preview.config'
local PreviewTask = require 'typst-preview.task'
local utils = require 'typst-preview.utils'
local M = {}

---All active preview tasks
---@type PreviewTask[]
local tasks = {}

---The last used preview mode by file path
---@type table<string, mode>
local last_modes = {}

---Get last mode that init was called with
---@param path string -- must be an absolute path
---@return mode?
function M.get_last_mode(path)
  return last_modes[path]
end

---Callback that discards crashed tasks
---@param task PreviewTask
local function on_error(task)
  M.remove{task_id = task.task_id}
end

---Return an existing preview or else init a new task
---@param path string -- must be an absolute path
---@param mode mode
---@param on_ready fun(task: PreviewTask, is_new: boolean)
function M.get_or_init(
  path,
  mode,
  on_ready
)
  for _, task in pairs(M.get{path = path, mode = mode}) do
    on_ready(task, false)
    return
  end

  -- FIXME: must not insert the task into tasks before it is ready, since
  -- otherwise, method calls to it can happen before it finished spawning
  -- (or we need to delay/block method calls? Not inserting it immediately
  -- could also lead to creating several tasks, only the last of which is in tasks
  -- if this called in quick succession.)
  local task = PreviewTask:new(path, mode)
  table.insert(tasks, task)
  last_modes[path] = mode
  task:spawn(
    on_error,
    function(t) on_ready(t, true) end
  )
end

---Get a task
---
---If filter.path ~= nil, it must be an absolute path
---@param filter TaskFilter?
---@return PreviewTask[]
function M.get(filter)
  ---@type PreviewTask[]
  local result = {}
  for _, task in pairs(tasks) do
    if filter == nil or task:matches(filter) then
      table.insert(result, task)
    end
  end

  return result
end

---Close & remove all tasks matching the filter
---
---If filter.path ~= nil, it must be an absolute path
---@param filter TaskFilter?
---@param reason string?
---@return boolean removed Whether at least one matching task existed before.
function M.remove(filter, reason)
  local removed = false
  for idx, task in pairs(tasks) do
    if filter == nil or task:matches(filter) then
      tasks[idx] = nil
      task:close()
      utils.debug(
        'Server with path ',
        task.path,
        ' and mode ',
        task.mode,
        ' closed',
        reason and (' (' .. reason .. ')') or ""
      )
      removed = true
    end
  end

  if not removed then
    -- This is not necessarily a bug: For example, the following can happen:
    -- 1. We remove a task and send tinymist.doKillPreview
    -- 2. tinymist sends tinymist/preview/dispose in response
    -- 3. our listener above calls remove again
    utils.debug('Attempt to remove non-existing task with filter: ', filter)
  end

  return removed
end

local last_filepath
local last_line

---Scroll all previews to the current cursor location
function M.scroll_preview()
  local filepath = utils.get_buf_path()
  if not filepath then
    -- Not sure whether this can happen? We only call this from the '*.typ'
    -- autocmd.
    last_filepath = nil
    last_line = nil
    return
  end
  local cursor = vim.api.nvim_win_get_cursor(0)
  local line = cursor[1] - 1
  local character = cursor[2]

  -- Don't send events if we stay on the same line
  if filepath == last_filepath and line == last_line then
    return
  end
  last_filepath = filepath
  last_line = line

  utils.debug('scroll to line: ', line, ', character: ', character)

  for _, task in pairs(tasks) do
    if not task.suppress then
      -- FIXME: Maybe only send this to servers for which the root dir contains
      -- filepath?
      task:scroll_to(filepath, line, character)
    end
  end
end

return M
