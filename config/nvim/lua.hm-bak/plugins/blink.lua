return {
	{
		'saghen/blink.cmp',
		-- optional: provides snippets for the snippet source
		dependencies = { 'rafamadriz/friendly-snippets' },

		-- use a release tag to download pre-built binaries
		version = '1.*',
		-- AND/OR build from source, requires nightly: https://rust-lang.github.io/rustup/concepts/channels.html#working-with-nightly-rust
		-- build = 'cargo build --release',
		-- If you use nix, you can build from source using latest nightly rust with:
		-- build = 'nix run .#build-plugin',

		---@module 'blink.cmp'
		---@type blink.cmp.Config
		opts = {
			keymap = { preset = 'super-tab' },

			appearance = {
				nerd_font_variant = 'mono'
			},
			completion = {
				documentation = { auto_show = true },
				menu = {
					draw = {
						components = {
							kind_icon = {
								text = function(ctx)
									if ctx.source_name ~= "Path" then
										return require("lspkind").symbol_map[ctx.kind] or "" .. ctx.icon_gap
									end

									local is_unknown_type = vim.tbl_contains({ "link", "socket", "fifo", "char", "block", "unknown" }, ctx.item.data.type)
									local mini_icon, _ = require("mini.icons").get(
										is_unknown_type and "os" or ctx.item.data.type,
										is_unknown_type and "" or ctx.label
									)

									return (mini_icon or ctx.kind_icon) .. ctx.icon_gap
								end,

								highlight = function(ctx)
									if ctx.source_name ~= "Path" then return ctx.kind_hl end

									local is_unknown_type = vim.tbl_contains({ "link", "socket", "fifo", "char", "block", "unknown" }, ctx.item.data.type)
									local mini_icon, mini_hl = require("mini.icons").get(
										is_unknown_type and "os" or ctx.item.data.type,
										is_unknown_type and "" or ctx.label
									)
									return mini_icon ~= nil and mini_hl or ctx.kind_hl
								end,
							}
						}
					}
				}
			},
			sources = {
				default = { 'lsp', 'path' },
			},
			fuzzy = { implementation = "prefer_rust_with_warning" }
		},
		opts_extend = { "sources.default" }
	}
}
