local executor = require("syntaxpresso.utils.executor")

local M = {}

function M.register(java_executable)
  vim.api.nvim_create_user_command("CreateJPARepository", function(opts)
    local cmd_parts = { java_executable, "java", "create-jpa-repository" }
    table.insert(cmd_parts, "--cwd=" .. vim.fn.getcwd())
    table.insert(cmd_parts, "--file-path=" .. vim.fn.expand("%:p"))

    if opts.fargs and #opts.fargs > 0 then
      for _, arg in ipairs(opts.fargs) do
        table.insert(cmd_parts, arg)
      end
    end

    executor.execute_command(java_executable, cmd_parts)
  end, {
    nargs = "*",
    desc = "Create a JPA repository for Java entities",
  })
end

return M
