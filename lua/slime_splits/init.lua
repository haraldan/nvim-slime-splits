local M = {}

local backend_name

local function backend()
  local name = backend_name
  if not name then
    -- $TMUX and $HERDR_ENV are both set when nested, and don't show which is the inner one
    name = vim.env.HERDR_ENV and "herdr" or vim.env.TMUX and "tmux"
  end
  if not name then
    vim.notify("slime-splits: not running inside herdr or tmux", vim.log.levels.ERROR)
    return nil
  end
  return require("slime_splits." .. name)
end

-- Pane ids live in a state file, one per name and multiplexer session.
local function state_file(b, name)
  local runtime_dir = vim.env.XDG_RUNTIME_DIR or "/tmp"
  local session = b.session():gsub("/", "_")
  return ("%s/slime-splits/%s/%s/%s"):format(runtime_dir, b.slime_target, session, name)
end

--- Choose the multiplexer and point vim-slime at it.
---@param opts? { backend?: "herdr"|"tmux" }
---  backend: skip detection, needed when tmux and herdr are nested and tmux is the inner one
function M.setup(opts)
  backend_name = opts and opts.backend
  local b = backend()
  if b then
    vim.g.slime_target = b.slime_target
  end
end

--- Get the id of the named split, or nil if it doesn't exist.
---@param name string
---@return string?
function M.get(name)
  local b = backend()
  if not b then
    return nil
  end
  local file = state_file(b, name)
  if vim.fn.filereadable(file) == 0 then
    return nil
  end
  local pane_id = vim.fn.readfile(file)[1]
  if not pane_id or not b.exists(pane_id) then
    return nil
  end
  return pane_id
end

--- Open the named split if needed, and make it the slime target of the current buffer.
---@param name string
---@param opts? { command?: string, direction?: "right"|"down", size?: number, cwd?: string }
---  command: run in the split when it is created
---  direction: where to split, defaults to "right"
---  size: share of the current pane the split takes up, defaults to 0.5
---  cwd: working directory of the split, defaults to Neovim's
---@return string? pane_id
function M.open(name, opts)
  local b = backend()
  if not b then
    return nil
  end
  opts = opts or {}
  local pane_id = M.get(name)

  if not pane_id then
    local err
    pane_id, err = b.split({
      direction = opts.direction or "right",
      size = opts.size or 0.5,
      cwd = opts.cwd or vim.fn.getcwd(),
    })
    if not pane_id then
      vim.notify("slime-splits: " .. err, vim.log.levels.ERROR)
      return nil
    end

    local file = state_file(b, name)
    vim.fn.mkdir(vim.fs.dirname(file), "p")
    vim.fn.writefile({ pane_id }, file)

    if opts.command then
      b.run(pane_id, opts.command)
    end
  end

  local slime_config = b.slime_config(pane_id)
  vim.g.slime_target = b.slime_target
  vim.g.slime_default_config = slime_config
  vim.b.slime_config = slime_config
  return pane_id
end

--- Close the named split.
---@param name string
function M.close(name)
  local b = backend()
  if not b then
    return
  end
  local pane_id = M.get(name)
  if pane_id then
    b.close(pane_id)
  end
  vim.fn.delete(state_file(b, name))
end

--- Send Ctrl-C to the named split.
---@param name string
function M.interrupt(name)
  local b = backend()
  local pane_id = M.get(name)
  if b and pane_id then
    b.interrupt(pane_id)
  end
end

return M
