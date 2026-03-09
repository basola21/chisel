-- lua/chisel/prompt.lua
-- Small float at the bottom for typing an instruction.

local M = {}

local changes = require("chisel.changes")

--- @param cfg table
--- @param bufnr integer
--- @param range integer[]  { start_line, end_line } 0-indexed
function M.open(cfg, bufnr, range)
	local buf = vim.api.nvim_create_buf(false, true)
	vim.bo[buf].buftype = "prompt"

	local ui    = vim.api.nvim_list_uis()[1]
	local width = math.floor(ui.width * 0.5)

	local session_title = (require("chisel.session").get() or {}).intent
		and require("chisel.session").get().intent.title
		or "no intent"

	local win = vim.api.nvim_open_win(buf, true, {
		relative   = "editor",
		row        = ui.height - 4,
		col        = math.floor((ui.width - width) / 2),
		width      = width,
		height     = 1,
		border     = cfg.ui.border,
		title      = " Intent: " .. session_title .. " ",
		title_pos  = "center",
		style      = "minimal",
	})

	vim.fn.prompt_setprompt(buf, "> ")
	vim.cmd("startinsert")

	vim.fn.prompt_setcallback(buf, function(input)
		local instruction = vim.trim(input)
		vim.api.nvim_win_close(win, true)

		if instruction == "" then
			vim.notify("chisel: empty instruction, cancelled", vim.log.levels.WARN)
			return
		end

		changes.queue(cfg, bufnr, range, instruction)
	end)

	vim.keymap.set({ "n", "i" }, "<Esc>", function()
		vim.api.nvim_win_close(win, true)
		vim.notify("chisel: cancelled", vim.log.levels.INFO)
	end, { buffer = buf, noremap = true, silent = true })
end

return M
