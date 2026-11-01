local M = {}

M.slime_target = "tmux"

local function tmux(args)
  local cmd = { "tmux" }
  vim.list_extend(cmd, args)
  local output = vim.fn.system(cmd)
  return vim.v.shell_error == 0, output
end

-- $TMUX is "socket_path,server_pid,session_id"
function M.session()
  return (vim.env.TMUX or "default"):match("^[^,]*")
end

function M.exists(pane_id)
  return (tmux({ "has-session", "-t", pane_id }))
end

function M.split(opts)
  local args = { "split-window", "-d", "-P", "-F", "#{pane_id}" }
  if opts.direction == "right" then
    table.insert(args, "-h")
  end
  vim.list_extend(args, { "-l", ("%d%%"):format(math.floor(opts.size * 100 + 0.5)), "-c", opts.cwd })
  local ok, output = tmux(args)
  if not ok then
    return nil, output
  end
  return vim.trim(output)
end

function M.run(pane_id, command)
  tmux({ "send-keys", "-t", pane_id, "-l", command })
  tmux({ "send-keys", "-t", pane_id, "Enter" })
end

function M.interrupt(pane_id)
  tmux({ "send-keys", "-t", pane_id, "C-c" })
end

function M.close(pane_id)
  tmux({ "kill-pane", "-t", pane_id })
end

function M.slime_config(pane_id)
  return { socket_name = M.session(), target_pane = pane_id }
end

return M
