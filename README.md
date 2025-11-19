<div align="center">
<img width="500" alt="syntaxpresso" src="https://github.com/user-attachments/assets/be0749b2-1e53-469c-8d99-012024622ade" />
</div>

<div align="center">
<img alt="neovim" src="https://img.shields.io/badge/NeoVim-%2357A143.svg?&logo=neovim&logoColor=white" />
<img alt="lua" src="https://img.shields.io/badge/built%20with-Lua-blue?logo=lua" />
</div>

# Syntaxpresso.nvim

A powerful Neovim plugin for Java development that provides intelligent code generation and manipulation for JPA (Java Persistence API) entities.

Syntaxpresso.nvim serves as a feature-rich Neovim frontend wrapper for [Syntaxpresso Core](https://github.com/syntaxpresso/core). It leverages the core's Rust-based AST manipulation engine and interactive Terminal UI (TUI) to deliver advanced Java code generation capabilities—such as creating entities, managing relationships, and generating repositories—directly within your editor workflow.

## Installation

### Prerequisites

- **Neovim 0.9.0+**
- **Syntaxpresso Core**: The plugin requires the UI-enabled binary of `syntaxpresso-core`. You can install it manually or let the plugin handle it via the `:SyntaxpressoInstall` command.
- **Java Project**: A project with JPA entities.

### Plugin Manager Installation

#### Using lazy.nvim

```lua
{ "syntaxpresso/syntaxpresso.nvim" }
```

#### Using packer.nvim

```lua
use { 'syntaxpresso/syntaxpresso.nvim' }
```

## Keybindings

The plugin sets up `<leader>cj` by default to open the Syntaxpresso menu. You can also bind specific commands directly:

```lua
vim.keymap.set("n", "<leader>je", "<cmd>SyntaxpressoCreateJpaEntity<CR>", { desc = "Create JPA Entity" })
vim.keymap.set("n", "<leader>jf", "<cmd>SyntaxpressoCreateEntityField<CR>", { desc = "Create JPA Field" })
vim.keymap.set("n", "<leader>jr", "<cmd>SyntaxpressoCreateEntityRelationship<CR>", { desc = "Create Relationship" })
vim.keymap.set("n", "<leader>jR", "<cmd>SyntaxpressoCreateJpaRepository<CR>", { desc = "Create Repository" })
```

## Features

All features are accessible through `<leader>cj`, providing a seamless experience.

### 1. Java File Generation

#### Create Java File

Quickly scaffold standard Java files including Classes, Interfaces, Enums, Records, and Annotations.

https://github.com/user-attachments/assets/8acb3027-0eb5-4f43-9a1a-e1befdff873f

### 2. Entity Management

#### Create JPA Entity

Generate new JPA entity classes with customizable options, including package declaration and annotations.

https://github.com/user-attachments/assets/572edebd-04a1-4451-bfee-2cdc6d41937a

#### Create Basic Field

Add fields with comprehensive JPA annotations. Supports all basic Java types, column constraints (nullable, unique, length), temporal types, and LOBs.

https://github.com/user-attachments/assets/f820bbb2-bc4f-49c8-82fa-5875f9e177c6

#### Create ID Field

Generate ID fields with various strategies (AUTO, IDENTITY, SEQUENCE, UUID) and full sequence configuration.

https://github.com/user-attachments/assets/bea198c7-1ed0-4ef5-8801-56d66f28706c

#### Create Enum Field

Add enum fields with proper JPA mapping (EnumType.STRING or EnumType.ORDINAL) and custom column definitions.

https://github.com/user-attachments/assets/d84e1f71-175c-4e41-bf47-c3570c0493ea

#### One-to-One Relationships

Create bidirectional or unidirectional One-to-One relationships.

https://github.com/user-attachments/assets/6cb87bdc-4c18-413e-ad3f-270f0eb69080

#### Many-to-One / One-to-Many Relationships

Create Many-to-One relationships that automatically configure the inverse One-to-Many side.

https://github.com/user-attachments/assets/192b1342-b719-4b1f-94f8-7c087b6d590f

### 3. Repository Generation

#### Create JPA Repository

Generate Spring Data JPA repository interfaces with automatic entity type detection and ID type inference.

https://github.com/user-attachments/assets/10ba0391-b4c3-4bad-90b1-ef515826b563

## Architecture

Syntaxpresso.nvim acts as a bridge between Neovim and the Rust-based core:

1. **Trigger**: You initiate an action (e.g., via `<leader>cj`).
2. **Launch**: The plugin spawns `syntaxpresso-core ui <command>` in a floating terminal.
3. **Interact**: You interact with the TUI forms provided by the Rust binary.
4. **Execute**: The Core processes the input and modifies your Java files using Tree-Sitter.
5. **Refresh**: The TUI closes, and Neovim reloads the buffer to show the generated code.

## UI Navigation

The TUI uses Vim-inspired keybindings for efficient navigation:

### Modes

The UI operates in two modes, similar to Vim:

- **Normal Mode**: Navigate between fields and trigger actions
- **Insert Mode**: Edit text inputs and select options

### Normal Mode Keybindings

| Key                     | Action                                                    |
| ----------------------- | --------------------------------------------------------- |
| `j` / `Tab` / `↓`       | Move to next field                                        |
| `k` / `Shift+Tab` / `↑` | Move to previous field                                    |
| `i`                     | Enter Insert mode at cursor position                      |
| `a`                     | Enter Insert mode at end of field                         |
| `Enter`                 | Activate button or enter Insert mode                      |
| `Esc` / `q`             | Cancel and close (requires double-press for confirmation) |

### Insert Mode Keybindings

#### Text Input Fields

| Key                    | Action                                         |
| ---------------------- | ---------------------------------------------- |
| `Esc`                  | Return to Normal mode                          |
| `Enter`                | Return to Normal mode (or accept autocomplete) |
| `←` / `→`              | Move cursor left/right                         |
| `Home` / `End`         | Jump to start/end of field                     |
| `Backspace` / `Delete` | Delete characters                              |
| Any character          | Type into field                                |

#### List Selectors (e.g., File Type, Enum Storage)

| Key                   | Action                                  |
| --------------------- | --------------------------------------- |
| `j` / `k` / `↑` / `↓` | Navigate options                        |
| `Enter`               | Select option and return to Normal mode |
| `Esc`                 | Return to Normal mode                   |

#### Checkboxes (e.g., Mandatory, Unique)

| Key                   | Action                |
| --------------------- | --------------------- |
| `j` / `k` / `↑` / `↓` | Navigate options      |
| `Space` / `Enter`     | Toggle checkbox       |
| `Esc`                 | Return to Normal mode |

#### Autocomplete Dropdown (Package Name)

| Key             | Action                                |
| --------------- | ------------------------------------- |
| `↑` / `↓`       | Navigate suggestions                  |
| `Tab` / `Enter` | Accept selected suggestion            |
| `Esc`           | Hide autocomplete and continue typing |
| Type characters | Filter suggestions in real-time       |

### Global Shortcuts

These work in both Normal and Insert modes:

| Key              | Action                                             |
| ---------------- | -------------------------------------------------- |
| `Ctrl+Enter`     | Submit form immediately (skip to confirm)          |
| `Ctrl+Backspace` | Go back to previous screen (in multi-step wizards) |
