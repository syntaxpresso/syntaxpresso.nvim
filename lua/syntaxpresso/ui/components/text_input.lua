local n = require("nui-components")

-- @param opts table: Configuration options for the text input component.
--   @field title string: Label displayed on the text input border.
--   @field signal table: Table storing input value and hidden state.
--   @field signal_key string: Key in the signal table for the input value.
--   @field size number|nil: Height of the text input in lines (defaults to 0). Ignored if autoresize is true.
--   @field signal_hidden_key string: Key in the signal table for hidden state.
--   @field autofocus boolean|nil: If true, autofocuses the text input (optional).
--   @field autoresize boolean|nil: If true, automatically resizes based on content (optional).
--   @field max_lines number|nil: Maximum number of lines allowed for multi-line input (optional).
--   @field wrap boolean|nil: If true, enables automatic line wrapping (optional).
--   @field flex table|nil: Flex layout options for the input (optional).
--   @field on_change_callback function|nil: Callback triggered when value changes (optional).
-- @return table: Rendered text input component.
local function text_input_component(opts)
	return n.text_input({
		flex = opts.flex or nil,
		autofocus = opts.autofocus or false,
		autoresize = opts.autoresize or false,
		size = opts.autoresize and nil or (opts.size or 0),
		value = opts.signal[opts.signal_key],
		max_lines = opts.max_lines or nil,
		wrap = opts.wrap or false,
		border_label = opts.title,
		on_change = function(value, _)
			opts.signal[opts.signal_key] = value
			if opts.on_change_callback then
				opts.on_change_callback(value, _)
			end
		end,
		hidden = opts.signal[opts.signal_hidden_key] or false,
	})
end

return {
	render_component = text_input_component,
}
