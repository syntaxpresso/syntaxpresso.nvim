# Agent Guidelines for syntaxpresso.nvim

## Project Structure

- Neovim Lua plugin for Java development tools
- Core executable provides language server features via external binary
- No traditional build/test commands - plugin loads dynamically

## Code Style

- Use 2-space indentation for Lua files
- Snake_case for local functions and variables
- PascalCase for module names and exported functions
- Always use `local M = {}` pattern for modules
- Always `return M` at end of module files
- No empty lines inside functions
- Only comment the code when strictly necessary

## Type Annotations

- Use Lua LSP annotations (`---@class`, `---@field`, `---@param`, `---@return`)
- Define response types in json_parser.lua when adding new API calls
- Cast results with `---@cast` when needed for type safety

## Error Handling

- Use `pcall()` for potentially failing operations
- Use `vim.notify()` with appropriate log levels (INFO, WARN, ERROR)
- Always provide fallbacks for external command failures
- Check exit codes and handle stderr output

## Command Registration

- All commands use `vim.api.nvim_create_user_command()`
- Include descriptive `desc` field for help
- Use executor.lua for simple command execution
- Use json_parser.lua for parsing external binary responses
- Handle both interactive prompts and direct arguments with `opts.fargs`

## Committing

- When committing changes, don't commit everything into a single commit.
  Consider making commits based on changes/features/fixes
- Don't ever commit this file

