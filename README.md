<div align="center">
	<img alt="Logo that represents the split screen workflow: an eye with NeoVim colours on one half (coding) and black and white on the other (preview); Typst’s logo is in the iris" src="assets/typst-preview-neovim.svg" style="width: 10em; border-radius: 1em;" />
	<h1> ✨ Typst Preview for Neovim ✨ </h1>
</div>

The Neovim plugin for [Myriad-Dreamin/tinymist](https://github.com/Myriad-Dreamin/tinymist).

https://github.com/chomosuke/typst-preview.nvim/assets/38484873/9f8ecf0f-aa1c-4edb-85a9-96a8005e8f25

## 💪 Features

- Low latency preview: preview your document instantly on type. The incremental rendering technique
  makes the preview latency as low as possible.
- Cross jump between code and preview. You can click on the preview to jump to the
  corresponding code location and have the preview follow your cursor in Neovim.

## 📦 Installation

#### Dependencies
- curl

**Lazy.nvim:**

```lua
{
  'chomosuke/typst-preview.nvim',
  lazy = false, -- or ft = 'typst'
  version = '1.*',
  opts = {}, -- lazy.nvim will implicitly calls `setup {}`
}
```

**Packer.nvim:**

```lua
use {
  'chomosuke/typst-preview.nvim',
  tag = 'v1.*',
  config = function()
    require 'typst-preview'.setup {}
  end,
}
```

**vim-plug:**

```vim
Plug 'chomosuke/typst-preview.nvim', {'tag': 'v1.*'}
```

**Note:** You can pin typst's minor version by pinning the minor version of this
plugin, i.e., `v1.1.*` instead of `v1.*`.

## 🚀 Usage

### Commands / Functions:

- `:TypstPreviewUpdate` or `require 'typst-preview'.update()`:
  - Download the necessary binaries to
    `vim.fn.fnamemodify(vim.fn.stdpath 'data' .. '/typst-preview/', ':p')`.
  - This must be run before any other commands can be run. It is implicitly ran
    when calling `setup {}`.
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

This plugin should work out of the box with no configuration. However, calling
`setup()` is required to ensure that the binaries that the plugin depends on are
downloaded and up to date.

### Default

```lua
require 'typst-preview'.setup {
  -- Setting this true will enable logging debug information to
  -- `vim.fn.stdpath 'data' .. '/typst-preview/log.txt'`
  debug = false,

  -- Custom format string to open the output link provided with %s
  -- Example: open_cmd = 'firefox %s -P typst-preview --class typst-preview'
  open_cmd = nil,

  -- Custom port to open the preview server. Default is random.
  -- Example: port = 8000
  port = 0,

  -- Custom host to bind the preview server to.
  -- Example: port = 0.0.0.0
  host = 127.0.0.1,

  -- Setting this to 'always' will invert black and white in the preview
  -- Setting this to 'auto' will invert depending if the browser has enable
  -- dark mode
  -- Setting this to '{"rest": "<option>","image": "<option>"}' will apply
  -- your choice of color inversion to images and everything else
  -- separately.
  invert_colors = 'never',

  -- Whether the preview will follow the cursor in the source file
  follow_cursor = true,

  -- Provide the path to binaries for dependencies.
  -- Setting this will skip the download of the binary by the plugin.
  -- Warning: Be aware that your version might be older than the one
  -- required.
  dependencies_bin = {
    ['tinymist'] = nil,
    ['websocat'] = nil
  },

  -- A list of extra arguments (or nil) to be passed to previewer.
  -- For example, extra_args = { "--input=ver=draft", "--ignore-system-fonts" }
  extra_args = nil,

  -- This function will be called to determine the root of the typst project
  get_root = function(path_of_main_file)
    local root = os.getenv 'TYPST_ROOT'
    if root then
      return root
    end
    return vim.fn.fnamemodify(path_of_main_file, ':p:h')
  end,

  -- This function will be called to determine the main file of the typst
  -- project.
  get_main_file = function(path_of_buffer)
    return path_of_buffer
  end,
}
```

### Use tinymist installed from Mason
Set `dependencies_bin` option to
`dependencies_bin = { ['tinymist'] = 'tinymist' }` should point towards the
Mason installation of tinymist.

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
[Enter-tainer/typst-preview](https://github.com/Enter-tainer/typst-preview) and
[Myriad-Dreamin/tinymist](https://github.com/Myriad-Dreamin/tinymist). If you
like this plugin enough to star it, please consider starring
[Enter-tainer/typst-preview](https://github.com/Enter-tainer/typst-preview) and
[Myriad-Dreamin/tinymist](https://github.com/Myriad-Dreamin/tinymist) as well.
