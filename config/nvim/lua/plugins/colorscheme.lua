return {
    {
        'morhetz/gruvbox',
        lazy = true,
        priority = 1000,
    },
    {
        'maxmx03/fluoromachine.nvim',
        lazy = false,
        priority = 1000,
        config = function ()
         local fm = require 'fluoromachine'

         fm.setup {
            glow = true,
            theme = 'fluoromachine',
            transparent = true,
         }

         vim.cmd.colorscheme 'fluoromachine'

         -- Subtle lighter background for inactive panes
         vim.api.nvim_set_hl(0, "NormalNC", { bg = "#241b30" })
         vim.api.nvim_set_hl(0, "NeoTreeNormalNC", { bg = "#241b30" })
         -- Bright green window separators for the active pane
         vim.api.nvim_set_hl(0, "WinSeparator", { fg = "#39ff14", bold = true })
        end
    }
}