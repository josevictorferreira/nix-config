vim.opt.grepprg = "rg --vimgrep --hidden --smart-case --glob '!.git' --glob '!node_modules'"

vim.api.nvim_create_user_command("ProjectSub", function(opts)
	local old, new, flags = unpack(vim.split(opts.args, " ", { plain = true, trimempty = true }))
	if not (old and new) then
		print("Usage: :ProjectSub OLD NEW [flags]")
		return
	end
	local root = vim.fn.systemlist("git rev-parse --show-toplevel")[1]
	if root and root ~= "" then
		vim.cmd("cd " .. root)
	end
	vim.cmd("silent grep " .. vim.fn.shellescape(old) .. " .")
	vim.cmd(
		"silent cfdo %s/"
			.. vim.fn.escape(old, "/\\")
			.. "/"
			.. vim.fn.escape(new, "/\\")
			.. "/"
			.. (flags or "g")
			.. " | update"
	)
end, { nargs = "+", desc = "Project-wide search & replace from repo root" })
