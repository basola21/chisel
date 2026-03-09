-- lua/chisel/config.lua
-- Default configuration and deep-merge utility.

local M = {}

local DEFAULTS = {
  adapter = 'ollama',
  model = 'minimax-m2.5:cloud',
  ollama = { base_url = 'http://localhost:11434' },
  openai = {
    base_url = 'https://api.openai.com/v1',
    api_key = vim.env.OPENAI_API_KEY,
  },
  keys = { prompt = '<leader>cs', accept = '<leader>aa', reject = '<leader>ar' },
  ui = {
    border = 'rounded',
    panel_width = 0.35,
    picker_width = 0.4,
    picker_height = 0.5,
  },
  storage = vim.fn.stdpath('data') .. '/chisel',
}

--- Deep merge src into dst (non-destructive: returns new table).
--- @param dst table
--- @param src table
--- @return table
local function deep_merge(dst, src)
  local result = vim.deepcopy(dst)
  for k, v in pairs(src) do
    if type(v) == 'table' and type(result[k]) == 'table' then
      result[k] = deep_merge(result[k], v)
    else
      result[k] = v
    end
  end
  return result
end

--- Build final config by merging user opts over defaults.
--- @param opts table|nil
--- @return table
function M.build(opts)
  return deep_merge(DEFAULTS, opts or {})
end

return M
