return {
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      "nvim-tree/nvim-web-devicons",
    },
    lazy = false,
    config = function()
      require("neo-tree").setup({
        filesystem = {
          window = { position = "left", width = 40 },
        },
      })

      -- Default workspace layout:
      --  filesystem (left) | editor (center) | git_status (top-right)
      --                    |                  | buffers (bottom-right)
      vim.api.nvim_create_autocmd("VimEnter", {
        callback = function()
          vim.schedule(function()
            vim.cmd("Neotree filesystem reveal left")
            vim.cmd("wincmd l")
            vim.cmd("belowright vsplit")
            vim.cmd("vertical resize 40")
            vim.cmd("Neotree git_status current")
            vim.cmd("belowright split")
            vim.cmd("Neotree buffers current")
            vim.cmd("wincmd h")
          end)
        end,
      })
    end,
  },
}
