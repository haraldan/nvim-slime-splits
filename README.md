# nvim-slime-splits

Open named REPL splits from Neovim and send code to them with [vim-slime](https://github.com/jpalardy/vim-slime). It detects whether you're in [herdr](https://herdr.dev) or tmux, so the same config works in both.

It also adds the herdr target that vim-slime doesn't have, which you can use on its own. Anything built on vim-slime's send functions keeps working, including [vim-slime-cells](https://github.com/haraldan/vim-slime-cells).

## Requirements

- Neovim 0.10 or later, running inside herdr or tmux
- [vim-slime](https://github.com/jpalardy/vim-slime)
- herdr or tmux 3.1 or later (tested with herdr 0.9.1 and tmux 3.8)

## Installation

With [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  "jpalardy/vim-slime",
  dependencies = { "haraldan/nvim-slime-splits" },
  init = function()
    vim.g.slime_bracketed_paste = 1
    vim.g.slime_dont_ask_default = 1
  end,
  config = function()
    require("slime_splits").setup()
  end,
}
```

`setup()` sets `g:slime_target` to match the multiplexer you're in. If both `$HERDR_ENV` and `$TMUX` are set, it chooses herdr. If you run tmux inside herdr, set it yourself with `setup({ backend = "tmux" })`.

## Usage

`open` creates the split the first time and reuses it afterwards. It also makes that split the slime target of the current buffer, so you can call it right before sending:

```lua
local splits = require("slime_splits")

vim.keymap.set("n", "<leader>ii", function()
  splits.open("ipython", { command = "ipython --no-autoindent", size = 0.4 })
end)
vim.keymap.set("n", "<leader>iq", function() splits.close("ipython") end)
vim.keymap.set("n", "<leader>iz", function() splits.interrupt("ipython") end)
```

| Function | Description |
|---|---|
| `setup(opts)` | Sets the slime target, with an optional `backend` of `"herdr"` or `"tmux"` |
| `open(name, opts)` | Opens the split if needed, targets it, and returns its pane id |
| `get(name)` | Returns the pane id, or `nil` if the split no longer exists |
| `close(name)` | Closes the split |
| `interrupt(name)` | Sends Ctrl-C to the split |

Options for `open`:

| Option | Default | Description |
|---|---|---|
| `command` | none | Command to run when the split is created |
| `direction` | `"right"` | `"right"` or `"down"` |
| `size` | `0.5` | Share of the current pane that the split takes up |
| `cwd` | Neovim's working directory | Working directory of the split |

Each name maps to one split per herdr or tmux session, so a second Neovim using the same name shares the split, even from another tab or window.

## Using only the herdr target

To pick the pane yourself, set the target and run `:SlimeConfig`, then enter a pane id. You can get the id by running `herdr pane current` in that pane.

```lua
vim.g.slime_target = "herdr"
vim.g.slime_default_config = { pane_id = "w1:p2" }
```

## Notes

- Multi-line sends use bracketed paste. IPython runs the paste straight away. Python's built-in REPL may wait at a `...` prompt for one more Enter.
- On herdr, each send is passed as one command-line argument, and Linux limits those to 128 KiB. Larger sends fail.

## License

MIT
