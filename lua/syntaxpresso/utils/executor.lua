local M = {}

function M.execute_command(java_executable, command_parts)
  vim.fn.jobstart(command_parts, {
    on_stdout = function(_, data)
      if data and #data > 0 and data[1] ~= "" then
        print(table.concat(data, "\n"))
      end
    end,
    on_stderr = function(_, data)
      if data and #data > 0 and data[1] ~= "" then
        vim.notify(table.concat(data, "\n"), vim.log.levels.ERROR)
      end
    end,
  })
end

return M
