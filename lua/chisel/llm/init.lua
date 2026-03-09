-- lua/chisel/llm/init.lua
-- Adapter dispatcher. Callers use llm.complete(); adapters are never touched directly.

local M = {}

local ADAPTERS = {
	ollama = "chisel.llm.ollama",
	openai = "chisel.llm.openai",
}

--- Dispatch to the configured adapter.
--- @param cfg table  Full plugin config
--- @param system string  System message content
--- @param messages table[]  { role: "user"|"assistant", content: string }[]
--- @param opts table  { model?, temperature?, max_tokens? }
--- @param callback function(err: string|nil, response: string|nil)
function M.complete(cfg, system, messages, opts, callback)
	local adapter_name = cfg.adapter
	local module_path = ADAPTERS[adapter_name]

	if not module_path then
		local valid = table.concat(vim.tbl_keys(ADAPTERS), ", ")
		callback('Unknown adapter "' .. tostring(adapter_name) .. '". Valid: ' .. valid, nil)
		return
	end

	local ok, adapter = pcall(require, module_path)
	if not ok then
		callback('Failed to load adapter "' .. adapter_name .. '": ' .. tostring(adapter), nil)
		return
	end

	adapter.complete(cfg, system, messages, opts or {}, callback)
end

return M
