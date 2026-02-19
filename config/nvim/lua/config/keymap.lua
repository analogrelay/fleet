-- Navigate between panes with C-h/j/k/l
vim.keymap.set("n", "<C-h>", "<C-w>h", { desc = "Move to left pane" })
vim.keymap.set("n", "<C-j>", "<C-w>j", { desc = "Move to below pane" })
vim.keymap.set("n", "<C-k>", "<C-w>k", { desc = "Move to above pane" })
vim.keymap.set("n", "<C-l>", "<C-w>l", { desc = "Move to right pane" })

local builtin = require("telescope.builtin")
vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "Telescope find files" })
vim.keymap.set("n", "<leader>fg", builtin.live_grep, { desc = "Telescope live grep" })
vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "Telescope buffers" })
vim.keymap.set("n", "<leader>fh", builtin.help_tags, { desc = "Telescope help tags" })
vim.keymap.set("n", "<leader>fr", builtin.registers, { desc = "Telescope registers" })
vim.keymap.set("n", "<leader>fs", builtin.lsp_workspace_symbols, { desc = "Telescope lsp workspace symbols" })
vim.keymap.set("n", "<leader>fd", builtin.diagnostics, { desc = "Telescope diagnostics" })

-- Barbar config
vim.keymap.set("n", "<C-p>", "<Cmd>BufferPick<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "<A-,>", "<Cmd>BufferPrevious<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "<A-.>", "<Cmd>BufferNext<CR>", { noremap = true, silent = true })

-- Floatty config
local term = require("floatty").setup({})
vim.keymap.set("n", "<C-t>", function() term.toggle() end)
vim.keymap.set("t", "<C-t>", function() term.toggle() end)

local lazygitterm = require("floatty").setup({
	cmd = "lazygit",
	id = vim.fn.getcwd,
})
vim.keymap.set("n", "<Leader>g", function() lazygitterm.toggle() end)
vim.keymap.set("t", "<Leader>g", function() lazygitterm.toggle() end)
