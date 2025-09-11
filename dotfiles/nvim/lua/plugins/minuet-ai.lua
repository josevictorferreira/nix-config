return {
	"milanglacier/minuet-ai.nvim",
	dependencies = {
		"nvim-lua/plenary.nvim",
	},
	config = function()
		require("minuet").setup({
			provider = "openai_compatible",
			request_timeout = 2.5,
			throttle = 1500,
			debouce = 600,
			notify = "debug",
			provider_options = {
				openai_compatible = {
					api_key = "OPENROUTER_API_KEY",
					end_point = "https://openrouter.ai/api/v1/chat/completions",
					model = "moonshotai/kimi-k2",
					name = "openrouter",
					optional = {
						max_tokens = 56,
						top_p = 0.9,
						provider = {
							sort = "throughput",
						},
					},
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
