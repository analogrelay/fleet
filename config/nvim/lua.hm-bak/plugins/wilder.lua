return {
	{
		"gelguy/wilder.nvim",
		event = "CmdlineEnter",
		config = function()
			local wilder = require("wilder")
			wilder.setup({ modes = { ":", "/", "?" } })

			wilder.set_option("pipeline", {
				wilder.branch(
					wilder.cmdline_pipeline(),
					wilder.search_pipeline()
				),
			})

			wilder.set_option("renderer", wilder.renderer_mux({
				[":"] = wilder.popupmenu_renderer({
					highlighter = wilder.basic_highlighter(),
				}),
				["/"] = wilder.wildmenu_renderer({
					highlighter = wilder.basic_highlighter(),
				}),
			}))
		end,
	},
}
