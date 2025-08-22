-- lua/syntaxpresso/init.lua

local installer = require("syntaxpresso.installer")
local commands = require("syntaxpresso.commands")

local M = {}

-- Track if setup has already been called
local setup_called = false

-- This is the main setup function called when the plugin loads.
function M.setup()
  if setup_called then
    return
  end
  setup_called = true
  local executable_path = installer.get_executable_path()

  -- Check if the executable binary already exists.
  if vim.fn.filereadable(executable_path) == 1 then
    -- If it exists, register all the dynamic commands from the binary.
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
end

return M
