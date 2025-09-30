local n = require("nui-components")

-- @param opts table: Configuration options for the text component.
--   @field text string: The text content to display.
--   @field is_focusable boolean|nil: Whether the text component is focusable (defaults to false).
--   @field align string|nil: The text alignment - "left", "center", or "right" (defaults to "center").
-- @return table: The rendered text component.
local function text_component(opts)
  return n.paragraph({
    lines = {
      n.line(n.text(opts.text, "String")),
    },
    align = opts.align or "center",
    is_focusable = opts.is_focusable or false,
  })
end

return {
  render_component = text_component,
}
