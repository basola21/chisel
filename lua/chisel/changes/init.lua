-- lua/chisel/changes/init.lua
-- Public API: queue, navigate, accept, reject.

local M = {}

local llm    = require("chisel.llm")
local session = require("chisel.session")
local queue  = require("chisel.changes.queue")
local render = require("chisel.changes.render")
local Status = require("chisel.types").Status
local Kind   = require("chisel.types").Kind

-- ── user turn builder ──────────────────────────────────────────────────────

local function build_user_turn(filetype, selected_text, instruction)
	return table.concat({
		"Code:",
		"```" .. filetype,
		selected_text,
		"```",
		"",
		"Instruction: " .. instruction,
		"",
		"Reminder: respond with only a raw JSON object.",
		'  "message": what you did or what the code does (always required)',
		'  "code": rewritten code, no fences (omit if only explaining)',
	}, "\n")
end

-- ── response parsing ───────────────────────────────────────────────────────

--- Strip optional markdown fences and decode JSON.
--- @param raw string
--- @return table|nil, string|nil  parsed, err
local function parse_response(raw)
	local s = vim.trim(raw):gsub("^```[%w]*\n?", ""):gsub("\n?```$", "")
	local ok, decoded = pcall(vim.fn.json_decode, vim.trim(s))
	if ok and type(decoded) == "table" then
		return decoded, nil
	end
	return nil, "could not parse AI response as JSON: " .. tostring(decoded)
end

-- ── queue ──────────────────────────────────────────────────────────────────

--- Send the selected code + instruction to the LLM and register a pending change.
--- @param cfg table
--- @param bufnr integer
--- @param range integer[]  { start_0, end_0 } 0-indexed, end exclusive
--- @param instruction string
function M.queue(cfg, bufnr, range, instruction)
	local sess = session.get()
	if not sess then
		vim.notify("chisel: no active session — set an intent first", vim.log.levels.ERROR)
		return
	end

	local original_lines = vim.api.nvim_buf_get_lines(bufnr, range[1], range[2], false)
	local filetype       = vim.bo[bufnr].filetype or ""

	local change = {
		id             = queue.gen_id(),
		bufnr          = bufnr,
		range          = range,
		original_lines = original_lines,
		proposed_text  = nil,
		message        = nil,
		kind           = nil,          -- Kind.CHANGE | Kind.EXPLAIN
		status         = Status.PENDING,
		mark_ids       = {},
	}

	queue.push(change)
	render.pending(change)

	local user_content = build_user_turn(filetype, table.concat(original_lines, "\n"), instruction)
	local updated_sess = session.push_user(user_content)
	vim.notify("chisel: queued — " .. instruction, vim.log.levels.INFO)

	llm.complete(cfg, updated_sess.system, updated_sess.messages, {}, function(err, response)
		if err then
			vim.notify("chisel: LLM error: " .. err, vim.log.levels.ERROR)
			render.clear_marks(change)
			queue.remove(change.id)
			return
		end

		local parsed, parse_err = parse_response(response or "")
		if not parsed then
			vim.notify("chisel: " .. (parse_err or "bad response"), vim.log.levels.ERROR)
			render.clear_marks(change)
			queue.remove(change.id)
			return
		end

		session.push_assistant(response)

		change.message = vim.trim(parsed.message or "")
		local code     = parsed.code and vim.trim(parsed.code) or ""
		if code ~= "" then
			change.kind          = Kind.CHANGE
			change.proposed_text = code
		else
			change.kind = Kind.EXPLAIN
		end

		change.status = Status.READY
		render.ready(change)

		local label = change.kind == Kind.EXPLAIN and "explanation ready" or "change ready"
		vim.notify("chisel: " .. label .. " — ]a/[a to navigate", vim.log.levels.INFO)
	end)
end

-- ── navigation ─────────────────────────────────────────────────────────────

function M.next()
	local change = queue.next_after(vim.fn.line(".") - 1)
	if change then
		vim.api.nvim_win_set_cursor(0, { change.range[1] + 1, 0 })
	else
		vim.notify("chisel: no pending changes", vim.log.levels.INFO)
	end
end

function M.prev()
	local change = queue.prev_before(vim.fn.line(".") - 1)
	if change then
		vim.api.nvim_win_set_cursor(0, { change.range[1] + 1, 0 })
	else
		vim.notify("chisel: no pending changes", vim.log.levels.INFO)
	end
end

-- ── accept / reject ────────────────────────────────────────────────────────

function M.accept()
	local change = queue.at(vim.fn.line(".") - 1)
	if not change then
		vim.notify("chisel: cursor is not on a pending change", vim.log.levels.WARN)
		return
	end

	if change.kind == Kind.CHANGE then
		local new_lines = vim.split(change.proposed_text, "\n", { plain = true })
		if new_lines[#new_lines] == "" then table.remove(new_lines) end
		vim.api.nvim_buf_set_lines(change.bufnr, change.range[1], change.range[2], false, new_lines)
		vim.notify("chisel: accepted", vim.log.levels.INFO)
	else
		vim.notify("chisel: dismissed", vim.log.levels.INFO)
	end

	render.clear_marks(change)
	change.status = Status.ACCEPTED
	queue.remove(change.id)
end

function M.reject()
	local change = queue.at(vim.fn.line(".") - 1)
	if not change then
		vim.notify("chisel: cursor is not on a pending change", vim.log.levels.WARN)
		return
	end

	render.clear_marks(change)
	change.status = Status.REJECTED
	queue.remove(change.id)
	vim.notify("chisel: rejected", vim.log.levels.INFO)
end

return M
