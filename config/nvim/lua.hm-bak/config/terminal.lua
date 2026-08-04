local ergoterm = require("ergoterm")

ergoterm.setup({
	terminal_defaults = {
		layout = "below",
		cleanup_on_success = false,
		auto_scroll = true
	}
})

local copilot = ergoterm:new({
	cmd = "copilot",
	name = "copilot",
	layout = "right",
	auto_list = false,
	bang_target = false,
	sticky = true,
	watch_files = true,
})

local term = ergoterm:new({
	cmd = "tmux",
	name = "term",
	layout = "below",
	auto_list = true,
	bang_target = true,
	sticky = true,
	watch_files = true,
})

local map = vim.keymap.set
map("n", "<Leader>t", function ()
	term:toggle()
end, { desc = "Open common terminal" })

map("n", "<Leader>a", function ()
	copilot:toggle()
end, { desc = "Open Copilot" })

exitTerm = function ()
	vim.cmd(":ToggleTerm")
end

map("t", "<esc><esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })
map("t", "<C-w>", "<C-\\><C-n><C-w>", { desc = "Window commands from terminal mode" })
