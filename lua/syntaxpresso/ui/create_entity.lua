local n = require("nui-components")
local text = require("syntaxpresso.ui.components.text")
local text_input = require("syntaxpresso.ui.components.text_input")

local renderer = n.create_renderer({ height = 7 })

local signal = n.create_signal({
  entity_name = "NewEntity",
  entity_package_name = _G.syntaxpresso_default_package or "com.example",
})

local function render_confirm_button()
  return n.button({
    flex = 1,
    label = "Confirm",
    align = "center",
    global_press_key = "<C-CR>",
    on_press = function()
      local entity_name = signal.entity_name:get_value()
      local package_name = signal.entity_package_name:get_value()
      local java_executable = _G.syntaxpresso_java_executable
      local create_entity_fn = _G.syntaxpresso_create_entity
      
      if not java_executable then
        vim.notify("Java executable not found", vim.log.levels.ERROR)
        return
      end
      
      if not create_entity_fn then
        vim.notify("Create entity function not found", vim.log.levels.ERROR)
        return
      end
      
      renderer:close()
      
      create_entity_fn(java_executable, package_name, entity_name .. ".java", function(response_data)
        if response_data then
          vim.notify("Entity created successfully at: " .. response_data.filePath, vim.log.levels.INFO)
          -- Open the created file
          vim.cmd("edit " .. response_data.filePath)
        else
          vim.notify("Failed to create entity", vim.log.levels.ERROR)
        end
      end)
    end,
  })
end

local function render_component()
  return n.rows(
    { flex = 0 },
    text.render_component({ text = "Create new JPA Entity" }),
    text_input.render_component({
      title = "Entity name",
      signal = signal,
      signal_key = "entity_name",
      autofocus = true,
      size = 1
    }),
    text_input.render_component({
      title = "Package name",
      signal = signal,
      signal_key = "entity_package_name",
      size = 1
    }),
    n.columns(
      { flex = 0 },
      render_confirm_button()
    )
  )
end

renderer:render(render_component())
