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
