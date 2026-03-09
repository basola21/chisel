-- lua/chisel/llm/openai.lua
-- OpenAI-compatible adapter. Works with OpenAI, Groq, Mistral, local LM Studio, etc.

local M = {}

local Role = require("chisel.types").Role

--- @param cfg table  Full plugin config
--- @param system string  System message content
--- @param messages table[]  { role, content }[] conversation history (last entry is current user turn)
--- @param opts table  { model, temperature, max_tokens }
--- @param callback function(err: string|nil, response: string|nil)
function M.complete(cfg, system, messages, opts, callback)
	local url     = cfg.openai.base_url .. "/chat/completions"
	local model   = opts.model or cfg.model
	local api_key = cfg.openai.api_key or ""

	local full_messages = vim.list_extend(
		{ { role = Role.SYSTEM, content = system } },
		messages
	)

	local body = vim.fn.json_encode({
		model = model,
		messages = full_messages,
		temperature = opts.temperature or 0.2,
		max_tokens = opts.max_tokens or 2048,
	})

	local stdout_chunks = {}
	local stderr_chunks = {}

	local stdout = vim.loop.new_pipe()
	local stderr = vim.loop.new_pipe()

	local handle
	handle = vim.loop.spawn("curl", {
		args = {
			"-s", "-X", "POST", url,
			"-H", "Content-Type: application/json",
			"-H", "Authorization: Bearer " .. api_key,
			"-d", body,
		},
		stdio = { nil, stdout, stderr },
	}, function(exit_code)
		handle:close()
		stdout:close()
		stderr:close()

		vim.schedule(function()
			if exit_code ~= 0 then
				callback("curl failed (exit " .. exit_code .. "): " .. table.concat(stderr_chunks), nil)
				return
			end

			local raw = table.concat(stdout_chunks)
			local ok, decoded = pcall(vim.fn.json_decode, raw)
			if not ok or type(decoded) ~= "table" then
				callback("Failed to decode OpenAI response: " .. raw, nil)
				return
			end

			if decoded.error then
				local msg = type(decoded.error) == "table"
					and (decoded.error.message or vim.inspect(decoded.error))
					or tostring(decoded.error)
				callback("OpenAI error: " .. msg, nil)
				return
			end

			local choices = decoded.choices
			if not choices or #choices == 0 then
				callback("OpenAI returned no choices", nil)
				return
			end

			callback(nil, (choices[1].message or {}).content or "")
		end)
	end)

	stdout:read_start(function(err, data)
		if not err and data then
			stdout_chunks[#stdout_chunks + 1] = data
		end
	end)

	stderr:read_start(function(err, data)
		if not err and data then
			stderr_chunks[#stderr_chunks + 1] = data
		end
	end)
end

return M
