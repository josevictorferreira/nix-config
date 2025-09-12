return {
	"milanglacier/minuet-ai.nvim",
	dependencies = {
		"nvim-lua/plenary.nvim",
	},
	event = "InsertEnter",
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
				model = "qwen/qwen3-coder",
				name = "openrouter",
				optional = {
					max_tokens = 56,
					top_p = 0.95,
					provider = { sort = "throughput" },
					reasoning = { effort = "minimal" },
				},
			},
		},
		virtualtext = {
			auto_trigger_ft = { "*" },
			keymap = {
				accept = "<C-y>",
				accept_line = "<C-l>",
				accept_n_lines = "<C-j>",
				prev = "<A-[>",
				next = "<A-]>",
				dismiss = "<C-d>",
			},
		},
	},
}
