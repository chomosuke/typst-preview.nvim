<h1 align="center"> ✨ Typst Preview for Neovim ✨ </h1>

The Neovim plugin for [Enter-tainer/typst-preview](https://github.com/Enter-tainer/typst-preview).

https://github.com/chomosuke/typst-preview.nvim/assets/38484873/9f8ecf0f-aa1c-4edb-85a9-96a8005e8f25

## 💪 Features

- Low latency preview: preview your document instantly on type. The incremental rendering technique
  makes the preview latency as low as possible.
- Cross jump between code and preview. You can click on the preview to jump to the
  corresponding code location and have the preview follow your cursor in Neovim.

## 📦 Installation

**Lazy.nvim:**

```lua
{
  'chomosuke/typst-preview.nvim',
  lazy = false, -- or ft = 'typst'
  version = '0.1.*',
  build = function() require 'typst-preview'.update() end,
}
```

**Packer.nvim:**

```lua
use {
  'chomosuke/typst-preview.nvim',
  tag = 'v0.1.*',
  run = function() require 'typst-preview'.update() end,
}
```

**vim-plug:**

```vim
Plug 'chomosuke/typst-preview.nvim', {'tag': 'v0.1.*', do: ':TypstPreviewUpdate'}
```

## 🚀 Usage

### Commands / Functions:

- `:TypstPreviewUpdate` or `require 'typst-preview'.update()`:
  - Download the necessary binaries to
    `vim.fn.fnamemodify(vim.fn.stdpath 'data' .. '/typst-preview/', ':p')`.
  - This must be run before any other commands can be run.
    - If you followed the installation instructions, your package manager should automatically run
      this for you.
- `:TypstPreview`:
  - Start the preview. Optionally, the desired preview mode can be specified:
    `:TypstPreview document` (default) or `:TypstPreview slide` for slide mode.
- `:TypstPreviewStop`:
  - Stop the preview.
- `:TypstPreviewToggle`:
  - Toggle the preview.
- `:TypstPreviewFollowCursor` or `require 'typst-preview'.set_follow_cursor(true)`:
  - Scroll preview as cursor moves.
  - This is on by default.
- `:TypstPreviewNoFollowCursor` or `require 'typst-preview'.set_follow_cursor(false)`:
  - Don't scroll preview as cursor moves.
- `:TypstPreviewFollowCursorToggle` or
  `require 'typst-preview'.set_follow_cursor(not init.get_follow_cursor())`.
- `:TypstPreviewSyncCursor` or `require 'typst-preview'.sync_with_cursor()`:
  - Scroll preview to the current cursor position. This can be used in combination with
    `:TypstPreviewNoFollowCursor` so that the preview only scroll to the current cursor position
    when you want it to.

## ⚙️ Configuration

This plugin should work out of the box with no configuration. Call to `setup()` is not required.

### Default

```lua
require 'typst-preview'.setup {
  -- Setting this true will enable printing debug information with print()
  debug = false,

  -- Custom format string to open the output link provided with %s
  -- Example: open_cmd = 'firefox %s -P typst-preview --class typst-preview'
  open_cmd = nil,

  -- Provide the path to binaries for dependencies.
  -- Setting this will skip the download of the binary by the plugin.
  -- Warning: Be aware that your version might be older than the one
  -- required.
  dependencies_bin = {
          ['typst-preview'] = nil,
          ['websocat'] = nil
  },

  -- Setting this to 'always' will invert black and white in the preview
  -- Setting this to 'auto' will invert depending if the browser has enable
  -- dark mode
  invert_colors = 'never',

  -- This function will be called to determine the root of the typst project
  get_root = function(bufnr_of_typst_buffer)
    return vim.fn.getcwd()
  end,
}
```

## ❓ Comparison with other tools

The author of [Enter-tainer/typst-preview](https://github.com/Enter-tainer/typst-preview) wrote a
good comparison [here](https://enter-tainer.github.io/typst-preview/intro.html#loc-1x0.00x949.99).

- [niuiic/typst-preview.nvim](https://github.com/niuiic/typst-preview.nvim): Since niuiic/typst-preview.nvim uses
  [typst-lsp](https://github.com/nvarner/typst-lsp), it has similar advantages and
  disadvantages of typst-lsp mentioned
  [here](https://enter-tainer.github.io/typst-preview/intro.html#loc-1x0.00x1600.00):
  - Higher latency due to the PDF reader having a delay.
  - Does not support cross jump between code and preview.

## 💻 Contribution

All PRs are welcome.

## Credit

This plugin wouldn't be possible without the work of
[Enter-tainer/typst-preview](https://github.com/Enter-tainer/typst-preview). If you like this plugin
enough to star it, please consider starring
[Enter-tainer/typst-preview](https://github.com/Enter-tainer/typst-preview) as well.
