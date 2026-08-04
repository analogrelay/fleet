-- Filetypes that are considered sidebar/auxiliary panes and should not count
-- as "real" buffers for the purpose of keeping vim open.
local sidebar_fts = {
	snacks_explorer = true,
	snacks_layout_box = true,
	snacks_picker_list = true,
	snacks_picker_input = true,
}

local function is_sidebar(buf)
	return sidebar_fts[vim.bo[buf].filetype] == true
end

local function count_real_bufs()
	return #vim.tbl_filter(function(b)
		return vim.fn.buflisted(b) == 1 and not is_sidebar(b)
	end, vim.api.nvim_list_bufs())
end

return {
	{ 'romgrk/barbar.nvim',
		dependencies = {
			'lewis6991/gitsigns.nvim',
			'nvim-tree/nvim-web-devicons',
		},
		init = function() vim.g.barbar_auto_setup = false end,
		opts = {},
		version = '^1.0.0',
		config = function(_, plugin_opts)
			require('barbar').setup(plugin_opts)

			-- Make :q close the current tab (buffer) rather than the window.
			-- Vim only quits when the last real buffer is closed.
			vim.api.nvim_create_user_command('Q', function(cmd_opts)
				local force = cmd_opts.bang
				if is_sidebar(vim.api.nvim_get_current_buf()) then
					vim.cmd(force and 'quit!' or 'quit')
					return
				end
				if count_real_bufs() <= 1 then
					vim.cmd(force and 'quit!' or 'quit')
				else
					vim.cmd(force and 'BufferClose!' or 'BufferClose')
				end
			end, { bang = true })

			-- Remap :q to :Q, but only when the full command is exactly 'q'
			-- so that :qa, :quit, etc. are unaffected.
			vim.cmd([[cnoreabbrev <expr> q (getcmdtype() == ':' && getcmdline() ==# 'q') ? 'Q' : 'q']])
		end,
	},
}
