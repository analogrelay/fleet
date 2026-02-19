-- Navigate between panes with C-h/j/k/l
vim.keymap.set("n", "<C-h>", "<C-w>h", { desc = "Move to left pane" })
vim.keymap.set("n", "<C-j>", "<C-w>j", { desc = "Move to below pane" })
vim.keymap.set("n", "<C-k>", "<C-w>k", { desc = "Move to above pane" })
vim.keymap.set("n", "<C-l>", "<C-w>l", { desc = "Move to right pane" })
