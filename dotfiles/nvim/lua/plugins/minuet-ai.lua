return {
	"milanglacier/minuet-ai.nvim",
	dependencies = {
		"nvim-lua/plenary.nvim",
	},
	opts = {
		provider = "openai_compatible",
		request_timeout = 2.5,
		n_completions = 1,
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
			auto_trigger_ft = { "*" },
			keymap = {
				accept = "<C-y>",
				accept_line = "<A-l>",
				accept_n_lines = "<A-s>",
				prev = "<C-[>",
				next = "<C-]>",
				dismiss = "<A-e>",
			},
		},
	},
}
