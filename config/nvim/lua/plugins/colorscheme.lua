return {
    {
        'morhetz/gruvbox',
        lazy = false,
        priority = 1000,
        config = function()
            vim.o.background = 'dark'
            vim.cmd.colorscheme 'gruvbox'

            -- Subtle lighter background for inactive panes (gruvbox bg1)
            vim.api.nvim_set_hl(0, "NormalNC", { bg = "#3c3836" })
            -- Bright green window separators for the active pane
            vim.api.nvim_set_hl(0, "WinSeparator", { fg = "#39ff14", bold = true })
        end,
    },
    {
        'maxmx03/fluoromachine.nvim',
        lazy = true,
        priority = 1000,
    },
}