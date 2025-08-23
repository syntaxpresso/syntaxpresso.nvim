-- lua/syntaxpresso/init.lua

local installer = require("syntaxpresso.installer")
local commands = require("syntaxpresso.commands")

local M = {}

-- Track if setup has already been called
local setup_called = false

-- This is the main setup function called when the plugin loads.
function M.setup(opts)
  opts = opts or {}
  if setup_called and not opts.executable_path then
    vim.notify("Setup already called, skipping", vim.log.levels.WARN)
    return
  end
  setup_called = true

  local executable_path
  if opts.executable_path then
    executable_path = opts.executable_path
    vim.notify("Using custom executable: " .. executable_path, vim.log.levels.INFO)
  else
    executable_path = installer.get_executable_path()
  end

  -- Check if the executable binary already exists.
  if vim.fn.executable(executable_path) == 1 or vim.fn.filereadable(executable_path) == 1 then
    -- If it exists, register all the dynamic commands from the binary.
    commands.register(executable_path)
  else
    -- If custom executable_path is provided, register commands anyway (dev mode)
    if opts.executable_path then
      commands.register(executable_path)
    else
      -- If it doesn't exist, create a command to prompt the user to install it.
      vim.api.nvim_create_user_command("SyntaxpressoInstall", function()
        vim.notify("Installing syntaxpresso core...", vim.log.levels.INFO)

        -- The installer function is called with a callback.
        installer.install(function(path)
          if path then
            vim.notify("Installation successful! Restart Neovim to load commands.", vim.log.levels.INFO)
            -- After installation, we can register the commands for the current session.
            commands.register(path)
            -- Remove the installation command as it's no longer needed for this session.
            pcall(vim.api.nvim_del_user_command, "SyntaxpressoInstall")
            -- else
            --   vim.notify("Installation failed. Check logs for details.", vim.log.levels.ERROR)
          end
        end)
      end, {
        desc = "Downloads and installs the syntaxpresso core binary.",
      })

      vim.notify("Syntaxpresso: core not found. Run :SyntaxpressoInstall", vim.log.levels.WARN)
    end
  end

  -- Also, create a command to allow users to update the binary.
  vim.api.nvim_create_user_command("SyntaxpressoUpdate", function()
    vim.notify("Checking for syntaxpresso updates...", vim.log.levels.INFO)
    installer.install(function(path)
      if path then
        vim.notify("Update successful! Please restart Neovim to apply changes.", vim.log.levels.INFO)
      else
        vim.notify("Update failed or you are already on the latest version.", vim.log.levels.ERROR)
      end
    end)
  end, {
    desc = "Checks for and installs updates to the syntaxpresso core binary.",
  })

  -- Setup conditional rename keymap if enabled (default: true)
  if opts.setup_keymap ~= false then
    vim.keymap.set("n", "<leader>cr", function()
      -- Use the same executable_path logic as setup
      local current_executable_path
      if opts.executable_path then
        current_executable_path = opts.executable_path
      else
        current_executable_path = installer.get_executable_path()
      end
      require("syntaxpresso.commands.rename").conditional_rename(current_executable_path)
    end, {
      desc = "Rename (syntaxpresso/inc-rename)",
      silent = true,
    })
  end
end

return M
