-- lua/chisel/picker.lua
-- Intent picker via Telescope. Falls back to a vim.ui.input prompt on create.

local M = {}

local intent_mod = require('chisel.intent')

--- Open description input to create a new intent.
--- @param cfg table
--- @param title string
--- @param on_created function(intent)
local function open_description_input(cfg, title, on_created)
  vim.ui.input({ prompt = 'Description for "' .. title .. '": ' }, function(input)
    if not input or vim.trim(input) == '' then
      vim.notify('chisel: description required', vim.log.levels.WARN)
      return
    end
    local new_intent = intent_mod.create(cfg, title, vim.trim(input))
    on_created(new_intent)
  end)
end

--- Main picker entry point.
--- @param cfg table
--- @param on_select function(intent)  Called with the chosen/created intent
function M.open(cfg, on_select)
  local ok, telescope = pcall(require, 'telescope')
  if not ok then
    vim.notify('chisel: telescope.nvim is required for the picker', vim.log.levels.ERROR)
    return
  end

  local pickers   = require('telescope.pickers')
  local finders   = require('telescope.finders')
  local conf      = require('telescope.config').values
  local actions   = require('telescope.actions')
  local action_state = require('telescope.actions.state')

  local all_intents = intent_mod.list(cfg)

  pickers.new({}, {
    prompt_title = 'Chisel: select or create intent',
    finder = finders.new_table {
      results = all_intents,
      entry_maker = function(intent)
        return {
          value   = intent,
          display = intent.title,
          ordinal = intent.title,
        }
      end,
    },
    sorter = conf.generic_sorter({}),
    attach_mappings = function(prompt_bufnr, map)
      -- <CR>: select existing intent
      actions.select_default:replace(function()
        local selection = action_state.get_selected_entry()
        actions.close(prompt_bufnr)
        if selection then
          on_select(selection.value)
        else
          -- Nothing matched — treat prompt text as a new intent title
          local query = action_state.get_current_line()
          if query and query ~= '' then
            open_description_input(cfg, query, on_select)
          else
            vim.notify('chisel: cancelled', vim.log.levels.INFO)
          end
        end
      end)

      -- <C-n>: explicitly create new intent from prompt text
      map({ 'i', 'n' }, '<C-n>', function()
        local query = action_state.get_current_line()
        actions.close(prompt_bufnr)
        if query and query ~= '' then
          open_description_input(cfg, query, on_select)
        else
          vim.notify('chisel: type a name first', vim.log.levels.WARN)
        end
      end)

      return true
    end,
  }):find()
end

return M
