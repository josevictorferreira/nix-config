return {
	"milanglacier/minuet-ai.nvim",
	dependencies = {
		"nvim-lua/plenary.nvim",
	},
	config = function()
		require("minuet").setup({
			provider_options = {
				operai_compatible = {
					model = "qwen/qwen3-coder",
					stream = true,
					end_point = "https://openrouter.ai/api/v1/chat/completions",
					api_key = "OPENROUTER_API_KEY",
					name = "Openrouter",
				},
			},
			virtualtext = {
				auto_trigger_ft = {},
				keymap = {
					accept = "<C-y>",
					accept_line = "<C-y>",
					accept_n_lines = "<C-y>",
					prev = "<C-[>",
					next = "<C-]>",
					dismiss = "<C-e>",
				},
			},
		})
	end,
}
