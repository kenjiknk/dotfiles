-- Colour scheme: the desktop theme's own (lua/theme.lua, generated from
-- ~/.config/theme/themes/*.toml by ~/Scripts/theme-render). All the themes
-- ~/Scripts/theme-switch offers are installed up front, so switching works
-- offline; lazy.nvim loads each one only when its colour scheme is applied.
-- theme-switch runs :ThemeReload in every running Neovim.

-- Reads lua/theme.lua again (a theme switch rewrites it) and applies it.
-- Falls back to LazyVim's tokyonight when the file or its scheme is missing.
local function apply_theme()
    package.loaded.theme = nil
    local ok, theme = pcall(require, "theme")
    vim.o.background = "dark"
    if ok then
        pcall(theme.setup)
        if pcall(vim.cmd.colorscheme, theme.colorscheme) then
            return
        end
        vim.notify("theme: colour scheme " .. theme.colorscheme .. " not found", vim.log.levels.WARN)
    end
    vim.cmd.colorscheme("tokyonight")
end

vim.api.nvim_create_user_command("ThemeReload", apply_theme, { desc = "Apply the desktop theme again" })

return {
    { "rebelot/kanagawa.nvim", lazy = true },
    { "ellisonleao/gruvbox.nvim", lazy = true },
    { "gbprod/nord.nvim", lazy = true },
    { "Shatur/neovim-ayu", lazy = true },
    { "craftzdog/solarized-osaka.nvim", lazy = true },
    { "projekt0n/github-nvim-theme", name = "github-theme", lazy = true },
    { "LazyVim/LazyVim", opts = { colorscheme = apply_theme } },
}
