# typst-preview.nvim flavor

Arne's branch of typst-preview.nvim: the upstream release tag plus fixes. `~/.config/nvim/init.lua`
loads `wolframm/typst-preview.nvim` at `branch = "flavor"` through lazy.nvim, so `:Lazy sync`
installs whatever this branch holds.

- `origin` = github.com/wolframm/typst-preview.nvim, `upstream` = chomosuke/typst-preview.nvim.
- New upstream release: `git fetch upstream --tags`, `git rebase --onto <tag> <old base> flavor`,
  push, `:Lazy sync`. A fix upstream has merged drops out of the rebase by itself.

| commit | what | upstream |
|---|---|---|
| fix: sync the cursor to every server, not only the first | the CursorMoved "same line" guard sat inside the per-server callback, so only the first server (arbitrary `pairs()` order) ever received the cursor; with two previews open one stopped following | PR #143 |

Base: v1.5.0.
