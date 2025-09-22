return {
	"milanglacier/minuet-ai.nvim",
	dependencies = {
		"nvim-lua/plenary.nvim",
	},
	event = "InsertEnter",
	opts = {
		provider = "openai_compatible",
		request_timeout = 2.5,
		context_window = 12000,
		throttle = 1500,
		debouce = 600,
		notify = "debug",
		provider_options = {
			openai_compatible = {
				api_key = "OPENROUTER_API_KEY",
				end_point = "https://openrouter.ai/api/v1/chat/completions",
				model = "google/gemini-2.5-flash",
				name = "Openrouter",
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
			auto_trigger_ignore_ft = {
				"TelescopePrompt",
				"alpha",
				"neo-tree",
				".env",
				"env",
				".enc.yaml",
				".enc.yml",
				"lazy",
				"NvimTree",
				"Trouble",
				"lir",
				"Outline",
				"undotree",
				"fugitive",
				"DiffviewFiles",
				"toggleterm",
			},
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
