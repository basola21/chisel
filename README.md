# chisel.nvim

AI-assisted code editing inside Neovim. Select code, give an instruction, and review the suggested change inline before applying it.

## Requirements

- Neovim >= 0.10
- [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)
- An LLM backend: [Ollama](https://ollama.com) (default) or an OpenAI-compatible API

## Installation

**lazy.nvim**

```lua
{
  "basola21/chisel.nvim",
  dependencies = { "nvim-telescope/telescope.nvim" },
  opts = {},
}
```

**packer.nvim**

```lua
use {
  "basola21/chisel.nvim",
  requires = { "nvim-telescope/telescope.nvim" },
  config = function()
    require("chisel").setup()
  end,
}
```

## Configuration

```lua
require("chisel").setup({
  adapter = "ollama",           -- "ollama" | "openai"
  model   = "llama3",

  ollama = {
    base_url = "http://localhost:11434",
  },

  openai = {
    base_url = "https://api.openai.com/v1",
    api_key  = vim.env.OPENAI_API_KEY,
  },

  ui = {
    border = "rounded",
  },
})
```

## Usage

### 1. Set an intent

An intent gives the AI its role and goal for the session (e.g. "refactor for readability", "add error handling").

```
:Chisel
```

Opens a Telescope picker. Select an existing intent or type a new name and press `<CR>` to create one. Switching intents starts a fresh conversation.

### 2. Edit code

Select lines in visual mode and press `<leader>cs`. Type an instruction in the prompt that appears (e.g. "extract this into a function") and press `<CR>`.

The AI response appears inline:

- **Code change** — original lines highlighted red, proposed lines in green below
- **Explanation** — lines highlighted blue with the AI message shown above

### 3. Review changes

| Key | Action |
|-----|--------|
| `]a` | Jump to next pending change |
| `[a` | Jump to prev pending change |
| `<leader>aa` | Accept change / dismiss explanation |
| `<leader>ar` | Reject change |

## How it works

Each session maintains a conversation history with the model, so follow-up instructions have full context of what was discussed before. Intents and their descriptions are stored locally in `~/.local/share/nvim/chisel/`.
