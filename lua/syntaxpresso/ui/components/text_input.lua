local n = require("nui-components")

local function text_input_component(_signal, _title, _signal_key, _signal_hidden, _size, _autofocus)
  return n.text_input({
    autofocus = _autofocus,
    size = _size or 0,
    value = _signal[_signal_key],
    border_label = _title,
    on_change = function(value, _)
      _signal[_signal_key] = value
    end,
    hidden = _signal[_signal_hidden] or false,
  })
end

return {
  render_component = text_input_component,
}
