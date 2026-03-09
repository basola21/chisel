-- plugin/chisel.lua
-- :Chisel command and all keymaps (registered at load time).

if vim.g.loaded_chisel then
	return
end
vim.g.loaded_chisel = true

local chisel = require("chisel")

-- :Chisel  → open intent picker
vim.api.nvim_create_user_command("Chisel", chisel.open_picker, {
	desc = "Chisel: open intent picker",
})

-- <leader>cs  (visual)  → open prompt for selection
vim.keymap.set("v", "<leader>cs", function()
	local v_pos   = vim.fn.getpos("v")
	local dot_pos = vim.fn.getpos(".")
	local start_1 = math.min(v_pos[2], dot_pos[2])
	local end_1   = math.max(v_pos[2], dot_pos[2])
	local bufnr   = vim.api.nvim_get_current_buf()
	vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "x", false)
	chisel.open_prompt(bufnr, { start_1 - 1, end_1 })
end, { desc = "Chisel: AI edit selection" })

-- ]a / [a  → navigate changes
vim.keymap.set("n", "]a", chisel.next_change, { desc = "Chisel: next change" })
vim.keymap.set("n", "[a", chisel.prev_change, { desc = "Chisel: prev change" })

-- <leader>aa / <leader>ar  → accept / reject
vim.keymap.set("n", "<leader>aa", chisel.accept_change, { desc = "Chisel: accept change" })
vim.keymap.set("n", "<leader>ar", chisel.reject_change, { desc = "Chisel: reject change" })
