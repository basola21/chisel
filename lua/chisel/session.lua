-- lua/chisel/session.lua
-- Per-intent conversation history. One session is active at a time.

local M = {}

local Role = require("chisel.types").Role

-- { system: string, messages: { role, content }[], intent: table } | nil
local _session = nil

--- Start a fresh session for the given intent.
--- @param intent table
function M.start(intent)
	_session = {
		intent   = intent,
		system   = table.concat({
			intent.description,
			"",
			"When responding, always output a raw JSON object (no markdown fences, no extra text):",
			'  "message": brief description of what you did or what the code does (always required)',
			'  "code": the rewritten code (omit entirely if only explaining)',
		}, "\n"),
		messages = {},
	}
end

--- Return the active session, or nil.
--- @return table|nil
function M.get()
	return _session
end

--- Append a user turn and return the updated session.
--- @param content string
--- @return table|nil
function M.push_user(content)
	if not _session then return nil end
	_session.messages = vim.list_extend(
		vim.deepcopy(_session.messages),
		{ { role = Role.USER, content = content } }
	)
	return _session
end

--- Append an assistant turn (the raw response string).
--- @param content string
function M.push_assistant(content)
	if not _session then return end
	_session.messages = vim.list_extend(
		vim.deepcopy(_session.messages),
		{ { role = Role.ASSISTANT, content = content } }
	)
end

--- Clear the active session.
function M.clear()
	_session = nil
end

return M
