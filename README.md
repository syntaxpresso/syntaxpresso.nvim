<div align="center">
  <img width="500" alt="syntaxpresso" src="https://github.com/user-attachments/assets/be0749b2-1e53-469c-8d99-012024622ade" />
</div>

<div align="center">
  <img alt="neovim" src="https://img.shields.io/badge/NeoVim-%2357A143.svg?&logo=neovim&logoColor=white" />
  <img alt="lua" src="https://img.shields.io/badge/built%20with-Lua-blue?logo=lua" />
  <img alt="GitHub Downloads (all assets, latest release)" src="https://img.shields.io/github/downloads/syntaxpresso/syntaxpresso.nvim/latest/total">
</div>

# Syntaxpresso.nvim

A powerful Neovim plugin for Java development that provides intelligent code generation and manipulation for JPA (Java Persistence API) entities through an intuitive UI.

## Overview

Syntaxpresso.nvim is a feature-rich Neovim frontend that integrates with [Syntaxpresso Core](https://github.com/syntaxpresso/core) to deliver advanced Java code generation capabilities directly in your editor. Built with nui-components, it offers a modern, interactive interface for managing JPA entities, fields, and relationships without leaving your workflow.

## Features

### Interactive Menu

All features are accessible through a dedicated Syntaxpresso menu (default: `<leader>cj` or `:Syntaxpresso`):

#### Entity Management

- **Create JPA Entity**: Generate new JPA entity classes with customizable options
- **Get Entity Info**: View detailed information about the current entity

#### Field Generation

- **Create Basic Field**: Add fields with comprehensive JPA annotations
  - Support for all Java basic types
  - Column constraints (nullable, unique, length, precision, scale)
  - Temporal types with timezone storage
  - Large object (LOB) support
- **Create ID Field**: Generate ID fields with various strategies
  - Generation types: AUTO, IDENTITY, SEQUENCE, TABLE, UUID
  - Sequence configuration (name, initial value, allocation size)
  - Generator customization

- **Create Enum Field**: Add enum fields with proper JPA mapping
  - EnumType.STRING or EnumType.ORDINAL
  - Custom column definitions
  - Full integration with Java enums

#### Relationship Management

- **Create Entity Relationship**: Establish relationships between entities
  - **One-to-One**: Bidirectional or unidirectional relationships
  - **Many-to-One**: With inverse One-to-Many side
  - **Many-to-Many**: _(Coming Soon)_

  Each relationship type supports:
  - Cascade types (PERSIST, MERGE, REMOVE, REFRESH, DETACH)
  - Fetch strategies (LAZY, EAGER)
  - Join column customization
  - Orphan removal
  - Mapped-by configuration

#### Repository Generation

- **Create JPA Repository**: Generate Spring Data JPA repository interfaces
  - Automatic entity type detection
  - ID type inference
  - Package-aware placement

## Installation

### Prerequisites

- Neovim 0.9.0+
- [Syntaxpresso Core](https://github.com/syntaxpresso/core) **UI-enabled binary** installed and accessible in PATH
  - Download `syntaxpresso-core-ui-{platform}-{arch}` from the [latest release](https://github.com/syntaxpresso/core/releases)
  - Or build from source with: `cargo build --release --features ui`
- Java project with JPA entities

**Important**: This plugin requires the **UI-enabled** variant of Syntaxpresso Core (binaries with `-ui-` in the name) as it uses the interactive terminal UI commands.

### Using lazy.nvim

```lua
{
  "syntaxpresso/syntaxpresso.nvim",
  config = function()
    require("syntaxpresso").setup({
      -- Optional: specify custom executable path for UI-enabled binary
      -- executable_path = "/path/to/syntaxpresso-core-ui",
      
      -- Optional: customize the keymap (default: "<leader>cj")
      -- Set to false to disable automatic keymap setup
      -- keymap = "<leader>cj",
    })
  end,
}
```

### Using packer.nvim

```lua
use {
  'syntaxpresso/syntaxpresso.nvim',
  config = function()
    require("syntaxpresso").setup()
  end
}
```

### Manual Installation

```bash
# Clone the repository
git clone https://github.com/syntaxpresso/syntaxpresso.nvim.git \
  ~/.local/share/nvim/site/pack/plugins/start/syntaxpresso.nvim

# Download and install Syntaxpresso Core UI-enabled binary
# Choose the appropriate binary for your platform from:
# https://github.com/syntaxpresso/core/releases
# Example for Linux:
wget https://github.com/syntaxpresso/core/releases/latest/download/syntaxpresso-core-ui-linux-amd64
chmod +x syntaxpresso-core-ui-linux-amd64
sudo mv syntaxpresso-core-ui-linux-amd64 /usr/local/bin/syntaxpresso-core
```

## Usage

### Basic Workflow

1. **Open a Java file** in Neovim (or navigate to your Java project)
2. **Open Syntaxpresso menu**: Press `<leader>cj` (or run `:Syntaxpresso`)
3. **Select an action**: Choose from the available operations
4. **Follow the wizard**: Complete the interactive UI forms
5. **Confirm**: Your code is generated automatically

### Menu Options

The menu automatically adapts based on your context:

**Always Available:**
- Create Java file
- Create JPA Entity

**When in a JPA Entity file** (file with `@Entity` annotation):
- Create JPA Entity field
- Create JPA Entity relationship
- Create JPA Repository

### Example: Creating a One-to-One Relationship

1. Open your `User.java` entity
2. Press `<leader>cj` and select "Create JPA Entity relationship"
3. Select "One-to-One" relationship type
4. **Tab 1 - Basic Configuration:**
   - Choose mapping type (Bidirectional recommended)
   - Select target entity (e.g., `UserProfile`)
   - Set field names (auto-populated: `userProfile`, `user`)
   - Configure cascades (e.g., PERSIST, MERGE)
   - Set options (Mandatory, Unique, etc.)
5. **Tab 2 - Inverse Side Configuration** (for bidirectional):
   - Configure inverse side cascades
   - Set inverse options (Orphan Removal, etc.)
6. Press `Ctrl+Enter` to confirm
7. Both entities are updated automatically!

**Result in User.java:**

```java
@OneToOne(cascade = {CascadeType.PERSIST, CascadeType.MERGE}, optional = false)
@JoinColumn(name = "user_profile_id", nullable = false, unique = true)
private UserProfile userProfile;
```

**Result in UserProfile.java:**

```java
@OneToOne(mappedBy = "userProfile")
private User user;
```

### Example: Creating a Many-to-One Relationship

1. Open your `Order.java` entity (the "Many" side)
2. Press `<leader>cj` and select "Create JPA Entity relationship"
3. Select "Many-to-One" relationship type
4. **Tab 1 - Basic Configuration (ManyToOne side):**
   - Choose mapping type (Bidirectional recommended)
   - Select target entity (e.g., `Customer` - the "One" side)
   - Set field names (auto-populated: `customer`, `orders`)
   - Select fetch type (Lazy/Eager)
   - Configure cascades and options
5. **Tab 2 - Inverse Side Configuration (OneToMany side):**
   - Choose collection type (List, Set, or Collection)
   - Configure inverse cascades
   - Set options (Orphan Removal)
6. Press `Ctrl+Enter` to confirm

**Result in Order.java:**

```java
@ManyToOne(fetch = FetchType.LAZY, optional = false)
@JoinColumn(name = "customer_id", nullable = false)
private Customer customer;
```

**Result in Customer.java:**

```java
@OneToMany(mappedBy = "customer")
private List<Order> orders;
```

### Example: Creating an ID Field

1. Open your entity file
2. Press `<leader>cj` and select "Create JPA Entity field"
3. Select "ID field" from the field type menu
3. **Configure your ID:**
   - Field name: `id`
   - Field type: `Long`
   - ID Generation: `SEQUENCE`
   - Generation Type: `SEQUENCE`
   - Sequence name: `user_seq`
   - Initial value: `1`
   - Allocation size: `50`
4. Press `Ctrl+Enter` to confirm

**Result:**

```java
@Id
@GeneratedValue(strategy = GenerationType.SEQUENCE, generator = "user_seq")
@SequenceGenerator(name = "user_seq", sequenceName = "user_seq", initialValue = 1, allocationSize = 50)
@Column(name = "id", nullable = false)
private Long id;
```

### UI Navigation

- **Arrow Keys / j/k**: Navigate through options
- **Enter / Space**: Select/Toggle options
- **Tab**: Move between form fields
- **Ctrl+Enter**: Confirm current step or submit
- **ESC / q**: Cancel and close

## Configuration

### Setup Options

```lua
require("syntaxpresso").setup({
  -- Path to syntaxpresso-core UI-enabled executable
  -- If not specified, searches in PATH for 'syntaxpresso-core'
  executable_path = nil,

  -- Keymap to open Syntaxpresso menu
  -- Set to false to disable automatic keymap setup
  -- Default: "<leader>cj"
  keymap = "<leader>cj",
})
```

### Available Commands

- `:Syntaxpresso` - Open the Syntaxpresso menu
- `:SyntaxpressoCreateJavaFile` - Create a new Java file
- `:SyntaxpressoCreateJpaEntity` - Create a new JPA Entity
- `:SyntaxpressoCreateEntityField` - Create a JPA Entity field
- `:SyntaxpressoCreateEntityRelationship` - Create a JPA Entity relationship
- `:SyntaxpressoCreateJpaRepository` - Create a JPA Repository
- `:SyntaxpressoInstall` - Install/update Syntaxpresso Core binary
- `:SyntaxpressoUpdate` - Check for and install updates

### Custom Keybindings

```lua
-- Custom keymap for the menu
require("syntaxpresso").setup({
  keymap = "<leader>sj",  -- or any other key combination
})

-- Disable automatic keymap and set your own
require("syntaxpresso").setup({
  keymap = false,
})
vim.keymap.set("n", "<leader>j", function()
  require("syntaxpresso").show_menu()
end, { desc = "Syntaxpresso menu" })

-- Or create direct shortcuts to specific commands
vim.keymap.set("n", "<leader>je", "<cmd>SyntaxpressoCreateJpaEntity<CR>",
  { desc = "Create JPA Entity" })
vim.keymap.set("n", "<leader>jf", "<cmd>SyntaxpressoCreateEntityField<CR>",
  { desc = "Create JPA Field" })
```

## Architecture

### Communication Flow

Syntaxpresso.nvim uses the **Rust core's built-in TUI** for all interactive forms:

1. **User Action**: User opens Syntaxpresso menu (`<leader>cj` or `:Syntaxpresso`)
2. **Menu Selection**: User selects an operation from `vim.ui.select` menu
3. **UI Launcher**: Plugin spawns `syntaxpresso-core ui <command>` in a floating terminal
4. **Interactive TUI**: Rust-based terminal UI (ratatui) collects configuration
5. **Direct Execution**: Core processes request and generates/modifies code directly
6. **Exit**: TUI exits, plugin reloads buffer to show changes

```
┌─────────────┐          ┌──────────────┐          ┌─────────────────────┐
│   Neovim    │          │ UI Launcher  │          │ Syntaxpresso Core   │
│  Menu (<leader>cj)     │  (Lua/vim)   │──────────│ (Rust Binary)       │
│  (vim.ui.select)       │              │   Spawn  │                     │
└─────────────┘          └──────────────┘          └─────────────────────┘
      │                         │                         │
      │  Select Action          │                         │
      │  ───────────►           │                         │
      │                         │  termopen()             │
      │                         │  `core ui <cmd>`        │
      │                         │  ─────────────────────► │
      │                         │                         │
      │                         │              ┌──────────▼─────────┐
      │                         │              │ Interactive TUI    │
      │                         │              │ (ratatui forms)    │
      │                         │              │ - Collect input    │
      │                         │              │ - Validate data    │
      │                         │              │ - Generate code    │
      │                         │              └──────────┬─────────┘
      │                         │                         │
      │                         │  Exit (code 0)          │
      │                         │  ◄───────────────────── │
      │  Buffer Reload          │                         │
      │  ◄───────────           │                         │
```

### Project Structure

```
syntaxpresso.nvim/
├── lua/
│   └── syntaxpresso/
│       ├── init.lua         # Main entry point & code actions
│       ├── installer.lua    # Core binary installer
│       └── ui_launcher.lua  # Rust TUI launcher
└── plugin/
    └── syntaxpresso.lua     # Plugin initialization
```

**Note**: All interactive UI forms and data queries are provided by the Rust core binary (`syntaxpresso-core ui` commands). The Neovim plugin serves as a minimal wrapper that launches the core's TUI in floating terminal windows.

## Development

### Local Development Setup

```bash
# Clone the repository
git clone https://github.com/syntaxpresso/syntaxpresso.nvim.git
cd syntaxpresso.nvim

# Link for local development (lazy.nvim)
{
  "syntaxpresso/syntaxpresso.nvim",
  dir = "/path/to/syntaxpresso.nvim",
  config = function()
    require("syntaxpresso").setup({
      -- Point to your UI-enabled dev build
      executable_path = "/path/to/syntaxpresso-core/target/release/syntaxpresso-core"
    })
  end
}

# Build the UI-enabled core binary for development
cd /path/to/syntaxpresso-core
cargo build --release --features ui
```

### Adding a New Command

1. **Create command module**: `lua/syntaxpresso/commands/your_command.lua`
2. **Create UI module**: `lua/syntaxpresso/ui/your_ui.lua`
3. **Implement data transformation**: Transform UI data to CLI format
4. **Register code action**: Add to `init.lua` code actions
5. **Test thoroughly**: Ensure proper error handling

### Code Action Pattern

```lua
-- In init.lua
local function register_code_actions()
  local code_actions = {
    {
      title = "Your Action",
      action = function()
        local ui = require("syntaxpresso.ui.your_ui")
        -- Load necessary data
        local data = load_required_data()
        -- Render UI
        ui.render(data)
      end,
      -- Optional: condition to show action
      condition = function()
        return is_valid_context()
      end,
    },
  }
  -- Register actions...
end
```

## Troubleshooting

### Common Issues

**Issue**: Menu not appearing or keymap not working

- **Solution**: Check that the keymap is not conflicting with other plugins. Try `:verbose nmap <leader>cj` to see what's bound to that key. You can customize the keymap in setup or use `:Syntaxpresso` command directly.

**Issue**: "syntaxpresso-core not found" or "ui command not found"

- **Solution**: Install the **UI-enabled** Syntaxpresso Core binary (`syntaxpresso-core-ui-*`) and ensure it's in PATH or set `executable_path` in setup. The CLI-only binary does not include UI commands.

**Issue**: Menu options not showing entity-specific actions

- **Solution**: Ensure you're in a file that contains the `@Entity` annotation. The menu is context-aware and only shows entity-specific options when appropriate.

**Issue**: Timeout errors

- **Solution**: Increase `default_timeout` in setup configuration for large projects

**Issue**: UI not rendering correctly

- **Solution**: Update nui-components.nvim to the latest version

### Debug Mode

```lua
-- Enable verbose logging
require("syntaxpresso").setup({
  debug = true,  -- Shows command execution details
})
```

## Contributing

We welcome contributions! Here's how to get started:

1. **Fork the repository**
2. **Create a feature branch**: `git checkout -b feature/amazing-feature`
3. **Make your changes**
4. **Follow Lua style guidelines**: Use LSP for linting
5. **Test thoroughly**: Test with real Java projects
6. **Submit a pull request**

### Development Guidelines

- Follow existing code patterns and structure
- Use factory functions for node creation to prevent state pollution
- Extract signal values before passing to command modules
- Add descriptive comments for complex UI logic
- Keep UI wizards focused and user-friendly

## Support

- **Issues**: [GitHub Issues](https://github.com/syntaxpresso/syntaxpresso.nvim/issues)
- **Discussions**: [GitHub Discussions](https://github.com/syntaxpresso/syntaxpresso.nvim/discussions)
- **Backend**: [Syntaxpresso Core](https://github.com/syntaxpresso/core)

## Changelog

See [Releases](https://github.com/syntaxpresso/syntaxpresso.nvim/releases) for version history and changes.

## License

[MIT License](LICENSE)

## Acknowledgments

- Powered by [Syntaxpresso Core](https://github.com/syntaxpresso/core)
- Inspired by the Neovim community's dedication to efficient development workflows
