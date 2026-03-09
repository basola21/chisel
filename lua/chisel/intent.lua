-- lua/chisel/intent.lua
-- Intent CRUD with JSON persistence. Immutable: every write returns a new list.

local M = {}

--- @param cfg table  Full plugin config (uses cfg.storage)
--- @return string  Path to intents.json
local function storage_path(cfg)
  return cfg.storage .. '/intents.json'
end

--- Ensure storage directory exists.
--- @param cfg table
local function ensure_dir(cfg)
  vim.fn.mkdir(cfg.storage, 'p')
end

--- Load all intents from disk.
--- @param cfg table
--- @return table[]  List of intent objects
function M.load(cfg)
  local path = storage_path(cfg)
  local ok, data = pcall(vim.fn.readfile, path)
  if not ok or not data or #data == 0 then
    return {}
  end
  local raw = table.concat(data, '\n')
  local ok2, decoded = pcall(vim.fn.json_decode, raw)
  if not ok2 or type(decoded) ~= 'table' then
    return {}
  end
  return decoded
end

--- Persist a list of intents to disk.
--- @param cfg table
--- @param intents table[]
local function save(cfg, intents)
  ensure_dir(cfg)
  local ok, encoded = pcall(vim.fn.json_encode, intents)
  if not ok then
    vim.notify('chisel: failed to encode intents: ' .. tostring(encoded), vim.log.levels.ERROR)
    return
  end
  local ok2, err = pcall(vim.fn.writefile, { encoded }, storage_path(cfg))
  if not ok2 then
    vim.notify('chisel: failed to write intents: ' .. tostring(err), vim.log.levels.ERROR)
  end
end

--- Create a new intent and persist it.
--- @param cfg table
--- @param title string
--- @param description string
--- @return table  The new intent
function M.create(cfg, title, description)
  local intent = {
    id = tostring(os.time()) .. '_' .. math.random(1000, 9999),
    title = title,
    description = description,
    created_at = os.time(),
  }
  local intents = M.load(cfg)
  local new_list = vim.list_extend(vim.deepcopy(intents), { intent })
  save(cfg, new_list)
  return intent
end

--- Return all intents.
--- @param cfg table
--- @return table[]
function M.list(cfg)
  return M.load(cfg)
end

--- Delete an intent by id and persist.
--- @param cfg table
--- @param id string
--- @return table[]  Updated list
function M.delete(cfg, id)
  local intents = M.load(cfg)
  local filtered = vim.tbl_filter(function(i)
    return i.id ~= id
  end, intents)
  save(cfg, filtered)
  return filtered
end

return M
