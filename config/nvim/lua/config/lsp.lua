vim.api.nvim_create_autocmd("LspAttach", {
	group = vim.api.nvim_create_augroup("lsp.autotrigger", {}),
	callback = function(args)
		local client = assert(vim.lsp.get_client_by_id(args.data.client_id))
		if client:supports_method("textDocument/completion") then
			vim.lsp.completion.enable(true, client.id, args.buf, {autotrigger = true})
		end
	end,
})

vim.lsp.enable("rust_analyzer")
vim.lsp.enable("gopls")
vim.lsp.enable("ts_ls")
vim.lsp.enable("pyright")
vim.lsp.enable("omnisharp")
vim.lsp.enable("nil_ls")
vim.lsp.enable("lua_ls")

