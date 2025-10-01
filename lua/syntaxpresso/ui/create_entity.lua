local n = require("nui-components")
local text = require("syntaxpresso.ui.components.text")
local text_input = require("syntaxpresso.ui.components.text_input")

local renderer = n.create_renderer({ height = 7 })

local signal = n.create_signal({
  entity_name = "NewEntity",
  entity_package_name = "com.example",
})

local function render_confirm_button()
  return n.button({
    flex = 1,
    label = "Confirm",
    align = "center",
    global_press_key = "<C-CR>",
    on_press = function()
      local result = {
        entity_name = signal.entity_name:get_value(),
        entity_package_name = signal.entity_package_name:get_value(),
      }
      vim.call("CreateEntityCallback", result)
      renderer:close()
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

-- Load main class info to set proper entity package name (after UI is rendered)
if _G.syntaxpresso_get_main_class and _G.syntaxpresso_java_executable then
  _G.syntaxpresso_get_main_class(_G.syntaxpresso_java_executable, function(main_class_info)
    if main_class_info and main_class_info.packageName then
      vim.notify("Package name received: " .. main_class_info.packageName, vim.log.levels.INFO)
      vim.notify("Signal type: " .. type(signal), vim.log.levels.INFO)
      vim.notify("entity_package_name field type: " .. type(signal.entity_package_name), vim.log.levels.INFO)

      if signal.entity_package_name and type(signal.entity_package_name) == "table" then
        vim.notify("entity_package_name has set_value method: " .. tostring(signal.entity_package_name.set_value ~= nil),
          vim.log.levels.INFO)
        vim.notify("Available methods: " .. vim.inspect(vim.tbl_keys(signal.entity_package_name)), vim.log.levels.INFO)
      end

      -- Try direct assignment instead of set_value
      signal.entity_package_name = main_class_info.packageName
    end
  end)
end
