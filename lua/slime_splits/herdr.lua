local M = {}

M.slime_target = "herdr"

local function herdr(args)
  local cmd = { "herdr" }
  vim.list_extend(cmd, args)
  local output = vim.fn.system(cmd)
  return vim.v.shell_error == 0, output
end

function M.session()
  return vim.env.HERDR_SOCKET_PATH or "default"
end

function M.exists(pane_id)
  return (herdr({ "pane", "get", pane_id }))
end

function M.split(opts)
  local ok, output = herdr({
    "pane",
    "split",
    "--current",
    "--direction",
    opts.direction,
    -- herdr's ratio is the share the current pane keeps
    "--ratio",
    tostring(1 - opts.size),
    "--cwd",
    opts.cwd,
    "--no-focus",
  })
  if not ok then
    return nil, output
  end
  return vim.json.decode(output).result.pane.pane_id
end

function M.run(pane_id, command)
  herdr({ "pane", "run", pane_id, command })
end

function M.interrupt(pane_id)
  herdr({ "pane", "send-keys", pane_id, "ctrl+c" })
end

function M.close(pane_id)
  herdr({ "pane", "close", pane_id })
end

function M.slime_config(pane_id)
  return { pane_id = pane_id }
end

return M
