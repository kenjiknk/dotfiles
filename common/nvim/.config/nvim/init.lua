-- Neovim configuration. Minimal on purpose while learning Vim itself.

-- Colour scheme: the desktop theme's own (lua/theme.lua, generated from
-- ~/.config/theme/themes/*.toml by ~/Scripts/theme-render). vim.pack is
-- Neovim's built-in plugin manager (0.12+); all the themes ~/Scripts/theme-switch
-- offers are installed up front, so switching works offline, and pinned in
-- nvim-pack-lock.json.
vim.pack.add({
    "https://github.com/rebelot/kanagawa.nvim",
    "https://github.com/ellisonleao/gruvbox.nvim",
    "https://github.com/gbprod/nord.nvim",
    "https://github.com/Shatur/neovim-ayu",
    "https://github.com/craftzdog/solarized-osaka.nvim",
    "https://github.com/projekt0n/github-nvim-theme",
}, { confirm = false })

-- Reads lua/theme.lua again, so a running Neovim follows a theme switch:
-- theme-switch calls :ThemeReload on every Neovim it finds.
local function apply_theme()
    package.loaded.theme = nil
    local ok, theme = pcall(require, "theme")
    if not ok then
        return
    end
    vim.o.background = "dark"
    theme.setup()
    if not pcall(vim.cmd.colorscheme, theme.colorscheme) then
        vim.notify("theme: colour scheme " .. theme.colorscheme .. " not found", vim.log.levels.WARN)
    end
end

vim.api.nvim_create_user_command("ThemeReload", apply_theme, { desc = "Apply the desktop theme again" })
apply_theme()
