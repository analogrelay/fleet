return {
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      local lspconfig = require("lspconfig")

      -- LSP keybindings on attach
      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(ev)
          local opts = { buffer = ev.buf }
          vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
          vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
          vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
          vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
          vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
          vim.keymap.set("n", "<leader>f", function()
            vim.lsp.buf.format({ async = true })
          end, opts)
        end,
      })

      -- Rust (rust-analyzer via rustup)
      lspconfig.rust_analyzer.setup({})

      -- Go
      lspconfig.gopls.setup({})

      -- C# (OmniSharp)
      lspconfig.omnisharp.setup({})

      -- TypeScript
      lspconfig.ts_ls.setup({})

      -- Python
      lspconfig.pyright.setup({})

      -- Nix
      lspconfig.nil_ls.setup({})
    end,
  },
}
