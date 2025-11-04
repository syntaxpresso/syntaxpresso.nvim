local n = require("nui-components")

-- @param opts table: Configuration options for the select one component.
--   @field label string: The label for the tree border.
--   @field data table: A list of nodes for the tree, where each node is a table containing 'text' and 'id'.
--   @field signal table: A table that stores the selected node id and hidden state.
--   @field signal_key string: The key in the signal table to store the selected node id.
--   @field signal_hidden_key string: The key in the signal table to store the hidden state of the tree component.
--   @field autofocus boolean|nil: If true, autofocuses the tree component (optional).
--   @field size number|nil: The number of visible nodes in the tree (optional, defaults to #data).
--   @field on_select_callback function|nil: A callback function triggered on node selection (optional).
--   @field tree_ref table|nil: Optional table to store the tree component reference for external re-rendering.
-- @return table: The rendered tree component.
local function render_component(opts)
	local tree_component = n.tree({
		autofocus = opts.autofocus or false,
		size = opts.size or #opts.data,
		border_label = opts.label,
		data = opts.data,
		on_select = function(selected_node, component)
			local tree = component:get_tree()
			local nodes = tree:get_nodes()
			-- Clear all nodes and find the matching node by id
			for _, node in ipairs(nodes) do
				node.is_done = false
				if node.id == selected_node.id then
					node.is_done = true
				end
			end
			opts.signal[opts.signal_key] = selected_node.id
			if opts.on_select_callback then
				opts.on_select_callback(opts.signal, selected_node, opts.data)
			end
			tree:render()
		end,
		prepare_node = function(node, line, _)
			if node.is_done then
				line:append("◉", "String")
			else
				line:append("○", "Comment")
			end
			line:append(" ")
			line:append(node.text)
			return line
		end,
		hidden = opts.signal[opts.signal_hidden_key] or nil,
	})

	-- Store the tree component reference if requested
	if opts.tree_ref then
		opts.tree_ref.component = tree_component
	end

	return tree_component
end

return {
	render_component = render_component,
}
