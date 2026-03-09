# <img src="https://github.com/user-attachments/assets/bb924bbe-83b1-4811-bc5f-2a6d55e67c47" width="32" height="32"> chisel.nvim

https://github.com/user-attachments/assets/da177473-84e1-4fc3-8b2c-12278c85c399

AI-assisted code editing inside Neovim. Select code, give an instruction, and review the suggested change inline before applying it.

## Early Beta

Chisel is an experimental project and still in very early development.

The goal of this project is not to build another AI coding agent, but to explore a different way of working with AI while coding.

Expect rough edges, breaking changes, incomplete features, and ongoing experimentation. The project will likely change as ideas are tested and refined.

## Philosophy

Chisel is built around a simple idea.

AI should enhance a developer's flow state, not interrupt it.

Most AI coding tools attempt to take control of the editing process. Chisel takes the opposite approach. The developer remains in control of the code and the structure of the program.

AI suggestions are small, local, reviewable, and optional.

Instead of asking an AI to generate large amounts of code, Chisel focuses on small transformations of code you have already written.

You select the code.
You give the instruction.
You decide whether the change should happen.

## Design Principles

### Developer Driven

The developer defines the architecture, structure, and intent.

AI assists with implementation details, refactors, and small improvements.

### Local Changes

Changes are scoped to the selected code, not the entire project.

This keeps suggestions understandable and easy to review.

### Inline Review

All suggestions appear directly in the buffer so they can be reviewed before applying.

Nothing is written to your files automatically.

### Vim Native Workflow

Chisel tries to stay close to how developers already work in Neovim.

- Visual selections
- Minimal prompts
- Fast iteration

The goal is to assist the editing process without adding heavy UI or complex agent systems.

## Requirements

- Neovim >= 0.10
- [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)
- An LLM backend: [Ollama](https://ollama.com) (default) or an OpenAI-compatible API

## Installation

### lazy.nvim

```lua
{
  "basola21/chisel.nvim",
  dependencies = { "nvim-telescope/telescope.nvim" },
  opts = {},
}
```

### packer.nvim

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

An intent gives the AI its role and goal for the session (for example: "refactor for readability" or "add error handling").

```
:Chisel
```

This opens a Telescope picker. Select an existing intent or type a new name and press `<CR>` to create one. Switching intents starts a fresh conversation.

### 2. Edit code

Select lines in visual mode and press `<leader>cs`. Type an instruction in the prompt that appears (for example: "extract this into a function") and press `<CR>`.

The AI response appears inline.

- **Code change** — original lines highlighted red, proposed lines in green below
- **Explanation** — lines highlighted blue with the AI message shown above

### 3. Review changes

| Key | Action |
| --- | --- |
| `]a` | Jump to next pending change |
| `[a` | Jump to prev pending change |
| `<leader>aa` | Accept change / dismiss explanation |
| `<leader>ar` | Reject change |

## How it works

Each session maintains a conversation history with the model so follow-up instructions have the context of previous edits.

Intents and their descriptions are stored locally in:

```
~/.local/share/nvim/chisel/
```

No code is changed automatically. All edits must be reviewed and accepted by the user.
