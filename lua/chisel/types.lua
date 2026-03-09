-- lua/chisel/types.lua
-- Shared enums. Accessing an unknown key raises an error so typos are caught early.

local function enum(values)
	return setmetatable(values, {
		__newindex = function(_, key)
			error("attempt to modify enum key: " .. tostring(key), 2)
		end,
		__index = function(_, key)
			error("unknown enum key: " .. tostring(key), 2)
		end,
	})
end

-- Lifecycle of a queued change
local Status = enum {
	PENDING  = "pending",   -- LLM request in flight
	READY    = "ready",     -- response received, awaiting user decision
	ACCEPTED = "accepted",  -- user applied the change (or dismissed an explanation)
	REJECTED = "rejected",  -- user discarded the change
}

-- What the AI returned
local Kind = enum {
	CHANGE  = "change",   -- code rewrite — shows red/green diff
	EXPLAIN = "explain",  -- explanation only — shows info highlight + message
}

-- Chat message roles
local Role = enum {
	SYSTEM    = "system",
	USER      = "user",
	ASSISTANT = "assistant",
}

return { Status = Status, Kind = Kind, Role = Role }
