local n = require("nui-components")

-- @param _text string: The text content to display.
-- @param _is_focusable boolean|nil: Whether the text component is focusable (defaults to false).
-- @param _align string|nil: The text alignment - "left", "center", or "right" (defaults to "center").
-- @return table: The rendered text component.
local function text_component(_text, _is_focusable, _align)
  return n.paragraph({
    lines = {
      n.line(n.text(_text, "String")),
    },
    align = _align or "center",
    is_focusable = _is_focusable or false,
  })
end

return {
  render_component = text_component,
}
