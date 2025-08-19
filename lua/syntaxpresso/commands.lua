-- lua/syntaxpresso/commands.lua

local M = {}

-- Private function to register commands from the parsed JSON data.
local function register_commands_from_info(commands_info, java_executable)
  if not commands_info or vim.tbl_isempty(commands_info) then
    vim.notify("No commands returned from syntaxpresso.", vim.log.levels.WARN)
    return
  end

  for name, info in pairs(commands_info) do
    local clean_name = name:gsub("^java%-", ""):gsub("^generic%-", "")
    local command_name = clean_name:gsub("-(%w)", function(c) return c:upper() end)
    command_name = command_name:sub(1, 1):upper() .. command_name:sub(2)

    vim.api.nvim_create_user_command(command_name, function(opts)
      -- THE FIX: Construct the command correctly.
      -- The first part is the main command group, e.g., "java"
      local command_group = name:match("^([^-]+)")
      -- The second part is the subcommand, e.g., "create-jpa-repository"
      local subcommand = name:match("^[^-]+-(.*)")

      local cmd_parts = { java_executable, command_group }
      if subcommand then
        table.insert(cmd_parts, subcommand)
      end

      for _, option in ipairs(info.options) do
        if option.name == "--cwd" then
          table.insert(cmd_parts, "--cwd=" .. vim.fn.getcwd())
        elseif option.name == "--file-path" then
          table.insert(cmd_parts, "--file-path=" .. vim.fn.expand("%:p"))
        end
      end
      if opts.fargs and #opts.fargs > 0 then
        for _, arg in ipairs(opts.fargs) do
          table.insert(cmd_parts, arg)
        end
      end

      -- Use jobstart for non-blocking execution
      vim.fn.jobstart(cmd_parts, {
        on_stdout = function(_, data)
          if data and #data > 0 and data[1] ~= "" then print(table.concat(data, "\n")) end
        end,
        on_stderr = function(_, data)
          if data and #data > 0 and data[1] ~= "" then vim.notify(table.concat(data, "\n"), vim.log.levels.ERROR) end
        end,
      })
    end, {
      nargs = "*",
      desc = info.description,
    })
  end
  vim.notify("Syntaxpresso commands are ready!", vim.log.levels.INFO)
end

-- Main function to start the registration process.
function M.register(java_executable)
  local command = { java_executable, "generate-command-info" }
  local stdout_buffer = {}

  vim.fn.jobstart(command, {
    on_stdout = function(_, data)
      if data then
        for _, chunk in ipairs(data) do
          table.insert(stdout_buffer, chunk)
        end
      end
    end,
    on_stderr = function(_, err)
      if err and #err > 0 and err[1] ~= "" then
        vim.notify("Failed to get command info (stderr): " .. table.concat(err, " "), vim.log.levels.ERROR)
      end
    end,
    on_exit = function(_, code)
      if code ~= 0 then
        vim.notify("Binary exited with a non-zero code: " .. code, vim.log.levels.ERROR)
        return
      end

      local result = table.concat(stdout_buffer, "")
      if result == "" then
        vim.notify("Binary returned no command info.", vim.log.levels.WARN)
        return
      end

      local ok, commands_info = pcall(vim.fn.json_decode, result)
      if not ok then
        vim.notify("Failed to parse JSON from binary: " .. result, vim.log.levels.ERROR)
        return
      end

      register_commands_from_info(commands_info, java_executable)
    end,
  })
end

return M
