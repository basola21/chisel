-- lua/chisel/init.lua
-- Public API: setup, intent state, picker, prompt, change navigation.
-- All external code (plugin/chisel.lua) only ever requires this module.

local M = {}

local _cfg = nil
local _intent = nil
local session = require("chisel.session")

function M.setup(opts)
	_cfg = require("chisel.config").build(opts)
end

--- Set the active intent and start a fresh conversation session.
--- @param intent table
function M.set_intent(intent)
	_intent = intent
	session.start(intent)
	vim.notify("chisel: intent set → " .. intent.title, vim.log.levels.INFO)
end

--- @return table|nil
function M.get_intent()
	return _intent
end

function M.open_picker()
	if not _cfg then
		vim.notify("chisel: call setup() first", vim.log.levels.ERROR)
		return
	end
	require("chisel.picker").open(_cfg, M.set_intent)
end

--- @param bufnr integer
--- @param range integer[]  { start_0, end_0 } 0-indexed
function M.open_prompt(bufnr, range)
	if not _cfg then
		vim.notify("chisel: call setup() first", vim.log.levels.ERROR)
		return
	end
	if not _intent then
		vim.notify("chisel: no active intent — run :Chisel first", vim.log.levels.WARN)
		return
	end
	require("chisel.prompt").open(_cfg, bufnr, range)
end

-- ── change navigation proxies ──────────────────────────────────────────────

function M.next_change()
	require("chisel.changes").next()
end
function M.prev_change()
	require("chisel.changes").prev()
end
function M.accept_change()
	require("chisel.changes").accept()
end
function M.reject_change()
	require("chisel.changes").reject()
end

return M
