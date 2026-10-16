-- Neovim configuration. Minimal on purpose while learning Vim itself.

-- Kanagawa Dragon, like kitty and the rest of the desktop. vim.pack is
-- Neovim's built-in plugin manager (0.12+); it installs the theme on first
-- start and pins it in nvim-pack-lock.json.
vim.pack.add({ "https://github.com/rebelot/kanagawa.nvim" }, { confirm = false })
vim.cmd.colorscheme("kanagawa-dragon")
