-- lua/chisel/changes/render.lua
-- Extmark rendering for pending and ready changes.

local M = {}

local Kind  = require("chisel.types").Kind
local queue = require("chisel.changes.queue")

local NS = vim.api.nvim_create_namespace("chisel_changes")

-- ── helpers ────────────────────────────────────────────────────────────────

local function highlight_lines(bufnr, from, to, hl_group)
	local ids = {}
	for line = from, to - 1 do
		ids[#ids + 1] = vim.api.nvim_buf_set_extmark(bufnr, NS, line, 0, {
			line_hl_group = hl_group,
		})
	end
	return ids
end

local function virt_text_right(bufnr, line, text, hl_group)
	return vim.api.nvim_buf_set_extmark(bufnr, NS, line, 0, {
		virt_text     = { { text, hl_group } },
		virt_text_pos = "right_align",
	})
end

local function message_above(bufnr, line, message)
	local virt_lines = {}
	for _, l in ipairs(vim.split(message, "\n", { plain = true })) do
		virt_lines[#virt_lines + 1] = { { "  " .. l, "DiagnosticVirtualTextInfo" } }
	end
	return vim.api.nvim_buf_set_extmark(bufnr, NS, line, 0, {
		virt_lines       = virt_lines,
		virt_lines_above = true,
	})
end

local function proposed_below(bufnr, last_original_line, proposed_text)
	local lines = vim.split(proposed_text, "\n", { plain = true })
	if lines[#lines] == "" then table.remove(lines) end

	local virt_lines = {}
	for _, l in ipairs(lines) do
		virt_lines[#virt_lines + 1] = { { l, "DiffAdd" } }
	end
	return vim.api.nvim_buf_set_extmark(bufnr, NS, last_original_line, 0, {
		virt_lines = virt_lines,
	})
end

-- ── public ─────────────────────────────────────────────────────────────────

function M.clear_marks(change)
	for _, id in ipairs(change.mark_ids) do
		pcall(vim.api.nvim_buf_del_extmark, change.bufnr, NS, id)
	end
	change.mark_ids = {}
end

--- Show "thinking…" placeholder while the LLM is working.
--- @param change table
function M.pending(change)
	local ids = highlight_lines(change.bufnr, change.range[1], change.range[2], "DiffText")
	ids[#ids + 1] = virt_text_right(change.bufnr, change.range[1], "  chisel: thinking… ", "Comment")
	change.mark_ids = ids
end

--- Show the AI message above the selection, then either a diff or an explanation highlight.
--- @param change table
function M.ready(change)
	M.clear_marks(change)
	local ids   = {}
	local count = queue.ready_count()
	local first = change.range[1]
	local last  = change.range[2] - 1

	-- AI message pinned above the first selected line
	if change.message ~= "" then
		ids[#ids + 1] = message_above(change.bufnr, first, change.message)
	end

	if change.kind == Kind.EXPLAIN then
		-- Explanation: neutral highlight, dismiss hint
		vim.list_extend(ids, highlight_lines(change.bufnr, first, change.range[2], "DiagnosticVirtualTextInfo"))
		ids[#ids + 1] = virt_text_right(
			change.bufnr, first,
			("  chisel [%d]  <leader>aa dismiss"):format(count),
			"DiagnosticInfo"
		)

	elseif change.kind == Kind.CHANGE then
		-- Code change: red original lines, green proposed lines below
		vim.list_extend(ids, highlight_lines(change.bufnr, first, change.range[2], "DiffDelete"))
		ids[#ids + 1] = proposed_below(change.bufnr, last, change.proposed_text)
		ids[#ids + 1] = virt_text_right(
			change.bufnr, first,
			("  chisel [%d ready]  <leader>aa accept  <leader>ar reject"):format(count),
			"DiagnosticInfo"
		)
	end

	change.mark_ids = ids
end

return M
