local n = require("nui-components")

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
