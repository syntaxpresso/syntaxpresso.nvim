local json_parser = require("syntaxpresso.utils.json_parser")
local get_info_util = require("syntaxpresso.utils.get_info")
local installer = require("syntaxpresso.installer")

local M = {}

local function get_current_word(java_executable, callback)
  get_info_util.get_node_info(java_executable, function(response_data)
    if response_data and response_data.nodeText then
      vim.notify(vim.inspect(response_data), vim.log.levels.INFO)
      local clean_text = response_data.nodeText:gsub("[\r\n]", "")
      callback(clean_text)
    else
      callback(vim.fn.expand("<cword>"))
    end
  end)
end

local function execute_rename(java_executable, new_name)
  local cmd_parts = { java_executable, "rename" }
  local pos = vim.api.nvim_win_get_cursor(0)
  local current_file_path = vim.fn.expand("%:p")

  table.insert(cmd_parts, "--cwd=" .. vim.fn.getcwd())
  table.insert(cmd_parts, "--file-path=" .. current_file_path)
  table.insert(cmd_parts, "--line=" .. pos[1])
  table.insert(cmd_parts, "--column=" .. pos[2])
  table.insert(cmd_parts, "--new-name=" .. new_name)
  table.insert(cmd_parts, "--language=JAVA")
  table.insert(cmd_parts, "--ide=NEOVIM")

  local output = {}
  vim.fn.jobstart(cmd_parts, {
    on_stdout = function(_, data)
      if data and #data > 0 then
        for _, line in ipairs(data) do
          if line ~= "" then
            table.insert(output, line)
          end
        end
      end
    end,
    on_stderr = function(_, data)
      if data and #data > 0 and data[1] ~= "" then
        vim.notify(table.concat(data, "\n"), vim.log.levels.ERROR)
      end
    end,
    on_exit = function(_, exit_code)
      if exit_code == 0 and #output > 0 then
        local raw_output = table.concat(output, "")
        local ok, result = json_parser.parse_response(raw_output)
        if ok and type(result) == "table" and result.succeed and result.data and result.data.filePath then
          ---@cast result DataTransferObject
          ---@type RenameResponse
          local response_data = result.data
          local response_file_path = response_data.filePath
          if response_file_path ~= current_file_path then
            vim.cmd("bdelete")
            vim.cmd("edit " .. response_file_path)
          end
          vim.notify("Rename completed successfully", vim.log.levels.INFO)
        else
          if #output > 0 then
            print(raw_output)
          end
          if not ok then
            vim.notify("Failed to parse rename response", vim.log.levels.WARN)
          elseif result and not (result.succeed) then
            vim.notify("Rename operation failed", vim.log.levels.ERROR)
          end
        end
      else
        vim.notify("Rename command failed with exit code: " .. exit_code, vim.log.levels.ERROR)
      end
    end,
  })
end

---Fallback to inc-rename or LSP rename
local function fallback_rename()
  local ok, inc_rename = pcall(require, "inc_rename")
  if ok then
    local cmd = ":" .. inc_rename.config.cmd_name .. " " .. vim.fn.expand("<cword>")
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(cmd, true, false, true), "n", false)
  else
    vim.lsp.buf.rename()
  end
end


function M.conditional_rename(java_executable)
  if vim.fn.filereadable(java_executable) == 1 then
    get_info_util.get_node_info(java_executable, function(response_data)
      if response_data and (response_data.nodeType == "CLASS_NAME" or response_data.nodeType == "METHOD_NAME") then
        get_current_word(java_executable, function(current_word)
          vim.ui.input({
            prompt = "Enter new name: ",
            default = current_word,
          }, function(new_name)
            if new_name and new_name ~= "" then
              execute_rename(java_executable, new_name)
            end
          end)
        end)
      else
        fallback_rename()
      end
    end)
  else
    fallback_rename()
  end
end

function M.register(java_executable)
  vim.api.nvim_create_user_command("Rename", function(opts)
    if opts.fargs and #opts.fargs > 0 then
      local new_name = opts.fargs[1]
      execute_rename(java_executable, new_name)
    else
      get_current_word(java_executable, function(current_word)
        vim.ui.input({
          prompt = "Enter new name: ",
          default = current_word,
        }, function(new_name)
          if new_name and new_name ~= "" then
            execute_rename(java_executable, new_name)
          end
        end)
      end)
    end
  end, {
    nargs = "?",
    desc = "Rename Java elements (variables, methods, classes, etc.)",
  })
end

return M
