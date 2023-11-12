<h1 align="center"> ✨ Typst Preview for Neovim ✨ </h1>

The Neovim plugin for [Enter-tainer/typst-preview](https://github.com/Enter-tainer/typst-preview).

**Warning: this plugin is still under development and force push might happen (will never overwrite
history more than 30 mins old)**

## 📦 Installation
**Lazy.nvim:**
```lua
{
    'chomosuke/typst-preview.nvim',
    lazy = false, -- or ft = 'toggleterm' if you use toggleterm.nvim
    -- version = '1.*',
}
```
**Packer.nvim:**
```lua
use { 'chomosuke/typst-preview.nvim', --[[ tag = 'v1.*' ]] }
```
**vim-plug:**
```vim
Plug 'chomosuke/typst-preview.nvim' ", {'tag': 'v1.*'}
```

## 🚀 Usage
You must run `:TypstPreviewUpdate` right after you install (Will not be the case before 1.0)
### Commands:
- `:TypstPreview`: Start the preview.
- `:TypstPreviewStop`: Stop the preview.
- `:TypstPreviewToggle`: Toggle the preview.
