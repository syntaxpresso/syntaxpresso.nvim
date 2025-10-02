local get_main_class_cmd = require("syntaxpresso.commands.get_main_class")

local select_one = require("syntaxpresso.ui.components.select_one")

local n = require("nui-components")

local M = {}

function M.show_create_file_ui(java_executable)
  local renderer = n.create_renderer({
    width = 65,
    height = 15,
  })

  local signal = n.create_signal({
    file_name = "NewFile",
    file_type = "CLASS",
    package_path = "",
  })

  local function initialize_package_path()
    get_main_class_cmd.get_main_class_info(java_executable, function(response_data)
      if response_data and response_data.packageName then
        signal.package_path = response_data.packageName
      end
    end)
  end

  initialize_package_path()

  local function render_main_title()
    return n.rows(
      { flex = 0 },
      n.paragraph({
        lines = {
          n.line(n.text("New Java file", "String")),
        },
        align = "center",
        is_focusable = false,
      })
    )
  end

  local function render_text_input_component(title, signal_key, signal_hidden, autofocus)
    return n.text_input({
      size = 1,
      autofocus = autofocus or false,
      value = signal[signal_key],
      border_label = title,
      on_change = function(value, _)
        signal[signal_key] = value
      end,
      hidden = signal[signal_hidden] or false,
    })
  end

  local function render_file_type_component(_signal)
    local data = {
      n.node({ text = "Class", is_done = true, id = "CLASS" }),
      n.node({ text = "Interface", is_done = false, id = "INTERFACE" }),
      n.node({ text = "Record", is_done = false, id = "RECORD" }),
      n.node({ text = "Enum", is_done = false, id = "ENUM" }),
      n.node({ text = "Annotation", is_done = false, id = "ANNOTATION" }),
    }
    return select_one.render_component({
      label = "File type",
      data = data,
      signal = _signal,
      signal_key = "file_type",
    })
  end

  local function render_confirm_button()
    return n.button({
      flex = 1,
      label = "Confirm",
      align = "center",
      global_press_key = "<C-CR>",
      padding = { top = 1 },
      on_press = function()
        local file_name = signal.file_name
        local file_type = signal.file_type
        local package_name = signal.package_path

        if type(file_name) == "table" and file_name.get_value then
          file_name = file_name:get_value()
        end
        if type(file_type) == "table" and file_type.get_value then
          file_type = file_type:get_value()
        end
        if type(package_name) == "table" and package_name.get_value then
          package_name = package_name:get_value()
        end

        local cmd_parts = {
          java_executable,
          "create-new-file",
          "--cwd=" .. vim.fn.getcwd(),
          "--language=JAVA",
          "--ide=NEOVIM",
          "--package-name=" .. tostring(package_name),
          "--file-name=" .. tostring(file_name),
          "--file-type=" .. tostring(file_type),
          "--source-directory=MAIN"
        }

        vim.fn.jobstart(cmd_parts, {
          on_stderr = function(_, data)
            if data and #data > 0 and data[1] ~= "" then
              vim.notify("Error creating file: " .. table.concat(data, "\n"), vim.log.levels.ERROR)
            end
          end,
          on_exit = function(_, exit_code)
            if exit_code == 0 then
              vim.notify("Java file created successfully!", vim.log.levels.INFO)
            else
              vim.notify("Failed to create Java file (exit code: " .. exit_code .. ")", vim.log.levels.ERROR)
            end
          end,
        })

        renderer:close()
      end,
      hidden = signal.confirm_btn_hidden,
    })
  end

  local function render_component()
    return n.rows(
      { flex = 0 },
      render_main_title(),
      n.gap(1),

      render_text_input_component("File name", "file_name", nil, true),
      render_text_input_component("Package path", "package_path", nil, false),
      render_file_type_component(signal),
      render_confirm_button()
    )
  end

  renderer:render(render_component())
end

return M
