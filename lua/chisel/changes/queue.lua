-- lua/chisel/changes/queue.lua
-- In-memory queue of pending changes. Pure state — no rendering.

local M = {}

local Status = require("chisel.types").Status

local _queue = {}

function M.gen_id()
	return tostring(os.time()) .. "_" .. math.random(10000, 99999)
end

function M.push(change)
	_queue[#_queue + 1] = change
end

function M.remove(id)
	_queue = vim.tbl_filter(function(c) return c.id ~= id end, _queue)
end

function M.ready_count()
	local count = 0
	for _, c in ipairs(_queue) do
		if c.status == Status.READY then
			count = count + 1
		end
	end
	return count
end

--- Return the ready change whose range contains cursor_line (0-indexed), or nil.
--- @param cursor_line integer
--- @return table|nil
function M.at(cursor_line)
	for _, c in ipairs(_queue) do
		local is_ready      = c.status == Status.READY
		local covers_cursor = cursor_line >= c.range[1] and cursor_line < c.range[2]
		if is_ready and covers_cursor then
			return c
		end
	end
	return nil
end

--- Return all ready changes, sorted by start line.
local function ready_sorted()
	local ready = vim.tbl_filter(function(c)
		return c.status == Status.READY
	end, _queue)
	table.sort(ready, function(a, b) return a.range[1] < b.range[1] end)
	return ready
end

--- Next ready change after cursor_line, wrapping to the first if none ahead.
--- @param cursor_line integer
--- @return table|nil
function M.next_after(cursor_line)
	local ready = ready_sorted()
	for _, c in ipairs(ready) do
		if c.range[1] > cursor_line then
			return c
		end
	end
	return ready[1] -- wrap
end

--- Prev ready change before cursor_line, wrapping to the last if none behind.
--- @param cursor_line integer
--- @return table|nil
function M.prev_before(cursor_line)
	local ready = ready_sorted()
	for i = #ready, 1, -1 do
		if ready[i].range[1] < cursor_line then
			return ready[i]
		end
	end
	return ready[#ready] -- wrap
end

return M
